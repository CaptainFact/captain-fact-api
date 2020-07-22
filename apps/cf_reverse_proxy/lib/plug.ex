defmodule CF.ReverseProxy.Plug do
  @moduledoc false

  use Plug.Builder

  plug(
    Corsica,
    max_age: 3600,
    allow_headers: ~w(Accept Content-Type Authorization Origin),
    origins: [~r/(.*)\.captainfact\.io$/]
  )

  @default_host CF.RestApi.Endpoint
  @base_host_regex ~r/^(?<service>rest|graphql|feed)\./
  @subdomains %{
    "graphql" => CF.GraphQLWeb.Endpoint,
    "rest" => CF.RestApi.Endpoint,
    "feed" => CF.AtomFeed.Router
  }

  def init(opts), do: opts

  # See https://github.com/wojtekmach/acme_bank/blob/master/apps/master_proxy/lib/master_proxy/plug.ex
  # Or CaddyServer
  # https://elixirforum.com/t/umbrella-with-2-phoenix-apps-how-to-forward-request-from-1-to-2-and-vice-versa/1797/18?u=betree
  # https://github.com/jesseshieh/master_proxy

  if Application.get_env(:cf, :env) == :dev do
    # Dev requests are routed through here
    def call(conn, _) do
      [path_info, endpoint] =
        case conn.path_info do
          ["rest" | _] -> [tl(conn.path_info), CF.RestApi.Endpoint]
          ["graphql" | _] -> [tl(conn.path_info), CF.GraphQLWeb.Endpoint]
          ["feed" | _] -> [tl(conn.path_info), CF.AtomFeed.Router]
          path_info -> [path_info, CF.RestApi.Endpoint]
        end

      conn
      |> Map.replace!(:path_info, path_info)
      |> Map.replace!(:request_path, Enum.join(path_info, "/"))
      |> endpoint.call(endpoint.init(nil))
    end
  else
    # Prod requests are routed through here
    def call(conn, _) do
      subdomain = get_domain_from_host(conn.host)
      endpoint = Map.get(@subdomains, subdomain, @default_host)
      endpoint.call(conn, endpoint.init(nil))
    end

    defp get_domain_from_host(host) do
      @base_host_regex
      |> Regex.named_captures(host)
      |> case do
        %{"service" => service} -> service
        _ -> "rest"
      end
    end
  end
end
