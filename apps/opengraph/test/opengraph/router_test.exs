defmodule Opengraph.RouterTest do
  use ExUnit.Case

  import Plug.Test
  import DB.Factory

  alias Opengraph.Router

  describe "get /u/:username" do
    test "returns 200 for a valid user" do
      user = insert(:user)

      response =
        conn(:get, "/u/#{user.username}")
        |> Router.call([])

      assert response.status == 200
    end

    test "returns 404 for an unknown user" do
      username = Kaur.Secure.generate_api_key   # best way I know to generate URL
                                                # compatible random string
      response =
        conn(:get, "/u/#{username}")
        |> Router.call([])

      assert response.status == 404
    end

    test "returns valid xml" do
      user = insert(:user)

      %{resp_body: body} =
        conn(:get, "/u/#{user.username}")
        |> Router.call([])

      assert SweetXml.parse(body)
    end
  end
end
