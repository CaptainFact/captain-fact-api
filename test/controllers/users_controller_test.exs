defmodule CaptainFact.UsersControllerTest do
  use CaptainFact.ConnCase

  alias CaptainFact.Users
  @valid_attrs %{email: "some content", name: "some content"}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, users_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    users = Repo.insert! %Users{}
    conn = get conn, users_path(conn, :show, users)
    assert json_response(conn, 200)["data"] == %{"id" => users.id,
      "name" => users.name,
      "email" => users.email}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, users_path(conn, :show, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, users_path(conn, :create), users: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Users, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, users_path(conn, :create), users: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    users = Repo.insert! %Users{}
    conn = put conn, users_path(conn, :update, users), users: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Users, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    users = Repo.insert! %Users{}
    conn = put conn, users_path(conn, :update, users), users: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    users = Repo.insert! %Users{}
    conn = delete conn, users_path(conn, :delete, users)
    assert response(conn, 204)
    refute Repo.get(Users, users.id)
  end
end
