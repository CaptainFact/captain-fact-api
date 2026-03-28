defmodule CF.Graphql.AbsintheRunTest do
  use ExUnit.Case, async: true

  @query """
  query {
    loggedInUser {
      id
    }
  }
  """

  test "Absinthe.run returns data without HTTP for anonymous loggedInUser" do
    assert {:ok, %{data: data}} = Absinthe.run(@query, CF.Graphql.Schema)
    assert data["loggedInUser"] == nil
  end

  test "Absinthe.run includes user in context when provided" do
    user = %DB.Schema.User{id: 1, username: "ctx_user"}
    ctx = %{user: user}

    assert {:ok, %{data: data}} =
             Absinthe.run(@query, CF.Graphql.Schema, context: ctx)

    assert get_in(data, ["loggedInUser", "id"]) == "1"
  end
end
