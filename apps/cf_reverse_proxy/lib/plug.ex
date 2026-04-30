defmodule CF.ReverseProxy.Plug do
  @moduledoc false

  @behaviour Plug

  import Plug.Conn

  # Matches the leading service label in a hostname:
  #   graphql.captainfact.io        → "graphql"
  #   graphql.staging.captainfact.io → "graphql"
  @service_subdomain ~r/^(?<service>rest|graphql|feed)\./

  # CORS is handled by each downstream endpoint (CF.RestApi.Endpoint and
  # CF.GraphQLWeb.Endpoint both plug Corsica with their own allowed origins).

  def init(opts), do: opts

  defp rest_target do
    Application.get_env(:cf_reverse_proxy, :rest_target, CF.RestApi.Endpoint)
  end

  defp graphql_target do
    Application.get_env(:cf_reverse_proxy, :graphql_target, CF.GraphQLWeb.Endpoint)
  end

  defp feed_target do
    Application.get_env(:cf_reverse_proxy, :feed_target, CF.AtomFeed.Router)
  end

  # Routing strategy
  # ─────────────────────────────────────────────────────────────────────────────
  # Primary (staging/production): host-based.
  #   graphql.<anything>.captainfact.io → GraphQL endpoint
  #   rest.<anything>.captainfact.io    → REST endpoint
  #   feed.<anything>.captainfact.io    → Atom feed
  #
  # Some ingress layers (e.g. Knative/Scaleway activator) preserve the original
  # public hostname in X-Forwarded-Host even if they rewrite Host internally;
  # routing_host/1 handles that fallback.
  #
  # Fallback (local dev, host = localhost / no service subdomain): path-based.
  #   /graphql/* → GraphQL   /feed/* → Atom feed   /* → REST
  #   The leading path segment is stripped before forwarding.
  # ─────────────────────────────────────────────────────────────────────────────

  def call(conn, _) do
    if conn.request_path == "/status" do
      send_resp(conn, 200, "Ok")
    else
      {conn, endpoint} =
        case conn |> routing_host() |> service_from_host() do
          "graphql" -> {conn, graphql_target()}
          "rest" -> {conn, rest_target()}
          "feed" -> {conn, feed_target()}
          nil -> path_based_routing(conn)
        end

      endpoint.call(conn, endpoint.init(nil))
    end
  end

  # Determines the effective hostname for routing.  Prefers conn.host when it
  # starts with a known service label; otherwise checks X-Forwarded-Host (set
  # by some ingress proxies when they rewrite Host internally).
  defp routing_host(conn) do
    host = String.downcase(conn.host)

    if Regex.match?(@service_subdomain, host) do
      host
    else
      case first_x_forwarded_host(conn) do
        nil -> host
        forwarded -> String.downcase(forwarded)
      end
    end
  end

  # Returns "graphql" | "rest" | "feed" | nil
  defp service_from_host(host) do
    case Regex.named_captures(@service_subdomain, host) do
      %{"service" => service} -> service
      _ -> nil
    end
  end

  # Fallback for local dev: route by the first path segment and strip it.
  defp path_based_routing(conn) do
    case conn.path_info do
      ["graphql" | rest] -> {strip_prefix(conn, rest), graphql_target()}
      ["feed" | rest] -> {strip_prefix(conn, rest), feed_target()}
      ["rest" | rest] -> {strip_prefix(conn, rest), rest_target()}
      _ -> {conn, rest_target()}
    end
  end

  defp strip_prefix(conn, path_info) do
    %{conn | path_info: path_info, request_path: "/" <> Enum.join(path_info, "/")}
  end

  defp first_x_forwarded_host(conn) do
    case get_req_header(conn, "x-forwarded-host") do
      [] ->
        nil

      [value | _] ->
        value
        |> String.split(",")
        |> List.first()
        |> String.trim()
        |> host_without_port()
    end
  end

  defp host_without_port(host) do
    case String.split(host, ":", parts: 2) do
      [h, _port] -> h
      [h] -> h
    end
  end
end
