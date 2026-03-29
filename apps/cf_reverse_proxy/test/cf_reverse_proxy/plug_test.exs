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

    conn = conn(method, path, body)

    conn =
      Enum.reduce(headers, conn, fn {key, value}, acc ->
        put_req_header(acc, key, value)
      end)

    conn = %{conn | host: host}
    CF.ReverseProxy.Plug.call(conn, [])
  end

  defp stub_role(conn) do
    case Jason.decode(conn.resp_body) do
      {:ok, %{"stub" => role}} -> role
      _ -> nil
    end
  end

  defp routing_mode(probe_conn) do
    case stub_role(probe_conn) do
      "graphql" -> :prod
      "rest" -> :dev
      _ -> :unknown
    end
  end

  test "init/1 passes options through" do
    assert CF.ReverseProxy.Plug.init(foo: 1) == [foo: 1]
  end

  test "GET /status returns 200 Ok" do
    conn = call(:get, "/status")
    assert conn.status == 200
    assert conn.resp_body == "Ok"
  end

  describe "forwarding" do
    setup _tags do
      probe = call(:get, "/", host: "graphql.captainfact.io")
      {:ok, routing: routing_mode(probe)}
    end

    test "routes to REST API", %{routing: mode} do
      conn =
        case mode do
          :dev ->
            call(:get, "/")

          :prod ->
            call(:get, "/", host: "rest.captainfact.io")

          :unknown ->
            flunk("could not determine dev vs prod routing from probe")
        end

      assert conn.status == 200
      assert stub_role(conn) == "rest"
    end

    test "routes to GraphQL", %{routing: mode} do
      conn =
        case mode do
          :dev ->
            call(:post, "/graphql",
              body: ~s({"query":"{ __typename }"}),
              headers: [{"content-type", "application/json"}]
            )

          :prod ->
            call(:post, "/",
              host: "graphql.captainfact.io",
              body: ~s({"query":"{ __typename }"}),
              headers: [{"content-type", "application/json"}]
            )

          :unknown ->
            flunk("could not determine dev vs prod routing from probe")
        end

      assert conn.status == 200
      assert stub_role(conn) == "graphql"
    end

    test "routes to Atom feed", %{routing: mode} do
      conn =
        case mode do
          :dev ->
            call(:get, "/feed/")

          :prod ->
            call(:get, "/", host: "feed.captainfact.io")

          :unknown ->
            flunk("could not determine dev vs prod routing from probe")
        end

      assert conn.status == 200
      assert stub_role(conn) == "feed"
    end

    test "unknown subdomain defaults to REST API (prod only)", %{routing: mode} do
      if mode == :prod do
        conn = call(:get, "/", host: "other.captainfact.io")
        assert conn.status == 200
        assert stub_role(conn) == "rest"
      else
        :ok
      end
    end

    test "dev strips /rest path prefix and forwards to REST stub", %{routing: mode} do
      if mode == :dev do
        conn = call(:get, "/rest/foo")
        assert conn.status == 200
        assert stub_role(conn) == "rest"
      else
        :ok
      end
    end
  end
end
