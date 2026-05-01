defmodule CF.ReverseProxy.PlugTest do
  use ExUnit.Case, async: false

  import Plug.Conn
  import Plug.Test

  alias CF.ReverseProxy.EndpointStubs

  setup do
    Application.put_env(:cf_reverse_proxy, :rest_target, EndpointStubs.Rest)
    Application.put_env(:cf_reverse_proxy, :graphql_target, EndpointStubs.Graphql)
    Application.put_env(:cf_reverse_proxy, :feed_target, EndpointStubs.Feed)

    on_exit(fn ->
      Application.delete_env(:cf_reverse_proxy, :rest_target)
      Application.delete_env(:cf_reverse_proxy, :graphql_target)
      Application.delete_env(:cf_reverse_proxy, :feed_target)
    end)

    :ok
  end

  defp call(method, path, opts \\ []) do
    body = Keyword.get(opts, :body, "")
    headers = Keyword.get(opts, :headers, [])
    host = Keyword.get(opts, :host, "localhost")

    conn(method, path, body)
    |> then(fn conn ->
      Enum.reduce(headers, conn, fn {key, value}, acc ->
        put_req_header(acc, key, value)
      end)
    end)
    |> Map.replace!(:host, host)
    |> CF.ReverseProxy.Plug.call([])
  end

  defp stub_role(conn) do
    case Jason.decode(conn.resp_body) do
      {:ok, %{"stub" => role}} -> role
      _ -> nil
    end
  end

  test "init/1 passes options through" do
    assert CF.ReverseProxy.Plug.init(foo: 1) == [foo: 1]
  end

  test "GET /status returns 200 Ok regardless of host" do
    assert call(:get, "/status").resp_body == "Ok"
    assert call(:get, "/status", host: "graphql.captainfact.io").resp_body == "Ok"
  end

  # ---------------------------------------------------------------------------
  # Host-based routing (staging / production)
  # ---------------------------------------------------------------------------

  describe "host-based routing" do
    test "graphql subdomain routes to GraphQL" do
      conn = call(:post, "/", host: "graphql.captainfact.io")
      assert stub_role(conn) == "graphql"
    end

    test "graphql.staging subdomain routes to GraphQL" do
      conn = call(:post, "/", host: "graphql.staging.captainfact.io")
      assert stub_role(conn) == "graphql"
    end

    test "rest subdomain routes to REST" do
      conn = call(:get, "/", host: "rest.captainfact.io")
      assert stub_role(conn) == "rest"
    end

    test "rest.staging subdomain routes to REST" do
      conn = call(:get, "/", host: "rest.staging.captainfact.io")
      assert stub_role(conn) == "rest"
    end

    test "feed subdomain routes to Atom feed" do
      conn = call(:get, "/", host: "feed.captainfact.io")
      assert stub_role(conn) == "feed"
    end

    test "unknown subdomain defaults to REST" do
      conn = call(:get, "/", host: "api.staging.captainfact.io")
      assert stub_role(conn) == "rest"
    end

    test "X-Forwarded-Host overrides an unrecognized Host header" do
      conn =
        call(:post, "/",
          host: "internal.functions.fnc.fr-par.scw.cloud",
          headers: [{"x-forwarded-host", "graphql.staging.captainfact.io"}]
        )

      assert stub_role(conn) == "graphql"
    end

    test "X-Forwarded-Host is ignored when Host already has a service subdomain" do
      conn =
        call(:get, "/",
          host: "rest.captainfact.io",
          headers: [{"x-forwarded-host", "graphql.captainfact.io"}]
        )

      assert stub_role(conn) == "rest"
    end
  end

  # ---------------------------------------------------------------------------
  # Path-based routing (local dev — host is localhost or has no service subdomain)
  # ---------------------------------------------------------------------------

  describe "path-based routing (localhost dev)" do
    test "/ routes to REST" do
      conn = call(:get, "/")
      assert stub_role(conn) == "rest"
    end

    test "/rest/* routes to REST and strips prefix" do
      conn = call(:get, "/rest/videos")
      assert stub_role(conn) == "rest"
    end

    test "/graphql routes to GraphQL and strips prefix" do
      conn =
        call(:post, "/graphql",
          body: ~s({"query":"{ __typename }"}),
          headers: [{"content-type", "application/json"}]
        )

      assert stub_role(conn) == "graphql"
    end

    test "/feed/ routes to Atom feed and strips prefix" do
      conn = call(:get, "/feed/")
      assert stub_role(conn) == "feed"
    end
  end
end
