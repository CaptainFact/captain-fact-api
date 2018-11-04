defmodule CF.RestApi.ApiInfoControllerTest do
  use CF.RestApi.ConnCase

  test "GET / returns API info", %{conn: conn} do
    response =
      conn
      |> get("/")
      |> json_response(200)

    assert is_binary(response["version"])
    assert response["status"] == "✔"
  end
end
