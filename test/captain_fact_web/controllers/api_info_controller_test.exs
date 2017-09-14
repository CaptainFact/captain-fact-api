defmodule CaptainFactWeb.AuthControllerTest do
  use CaptainFactWeb.ConnCase

  test "GET /api", %{conn: conn} do
    response =
      conn
      |> get("/api")
      |> json_response(200)

    assert is_binary(response["version"])
    assert response["status"] == "✔"
  end
end