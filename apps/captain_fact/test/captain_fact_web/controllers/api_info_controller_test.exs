defmodule CaptainFactWeb.ApiInfoControllerTest do
  use CaptainFactWeb.ConnCase

  test "GET / returns API info", %{conn: conn} do
    response =
      conn
      |> get("/")
      |> json_response(200)

    assert is_binary(response["version"])
    assert response["status"] == "✔"
  end
end
