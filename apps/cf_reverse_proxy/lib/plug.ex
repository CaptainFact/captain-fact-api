defmodule CF.ReverseProxy.Plug do
  @moduledoc false

  use Plug.Builder

  plug(
    Corsica,
    max_age: 3600,
    allow_headers: ~w(Accept Content-Type Authorization Origin),
    origins: [~r/(.*)\.captainfact\.io$/]
  )

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

  # See https://github.com/wojtekmach/acme_bank/blob/master/apps/master_proxy/lib/master_proxy/plug.ex
  # Or CaddyServer
  # https://elixirforum.com/t/umbrella-with-2-phoenix-apps-how-to-forward-request-from-1-to-2-and-vice-versa/1797/18?u=betree
  # https://github.com/jesseshieh/master_proxy

  if Application.compile_env(:cf, :env, :prod) == :dev do
    # Dev requests are routed through here
    def call(conn, _) do
      if conn.request_path == "/status" do
        send_resp(conn, 200, "Ok")
      else
        [path_info, endpoint] =
          case conn.path_info do
            ["rest" | _] -> [tl(conn.path_info), rest_target()]
            ["graphql" | _] -> [tl(conn.path_info), graphql_target()]
            ["feed" | _] -> [tl(conn.path_info), feed_target()]
            path_info -> [path_info, rest_target()]
          end

        conn
        |> Map.replace!(:path_info, path_info)
        |> Map.replace!(:request_path, Enum.join(path_info, "/"))
        |> endpoint.call(endpoint.init(nil))
      end
    end
  else
    # Prod requests are routed through here
    def call(conn, _) do
      if conn.request_path == "/status" do
        send_resp(conn, 200, "Ok")
      else
        subdomain = get_domain_from_host(conn.host)

        endpoint =
          case subdomain do
            "graphql" -> graphql_target()
            "rest" -> rest_target()
            "feed" -> feed_target()
            _ -> rest_target()
          end

        endpoint.call(conn, endpoint.init(nil))
      end
    end

    defp get_domain_from_host(host) do
      ~r/^(?<service>rest|graphql|feed)\./
      |> Regex.named_captures(host)
      |> case do
        %{"service" => service} -> service
        _ -> "rest"
      end
    end
  end
end
