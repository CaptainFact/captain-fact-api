defmodule CF.GraphQLWeb.UserSocketTest do
  use ExUnit.Case, async: false

  import Phoenix.ChannelTest
  import DB.Factory

  alias CF.Authenticator.GuardianImpl

  @endpoint CF.GraphQLWeb.Endpoint

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DB.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(DB.Repo, {:shared, self()})
    :ok
  end

  defp absinthe_context(socket) do
    opts = get_in(socket.assigns, [:absinthe, :opts]) || []
    Keyword.get(opts, :context, %{})
  end

  test "connect without token yields empty absinthe context" do
    assert {:ok, socket} = connect(CF.GraphQLWeb.UserSocket, %{})
    assert absinthe_context(socket) == %{}
  end

  test "connect with token param authenticates user" do
    user = insert(:user)
    {:ok, token, _} = GuardianImpl.encode_and_sign(user)

    assert {:ok, socket} = connect(CF.GraphQLWeb.UserSocket, %{"token" => token})
    assert absinthe_context(socket).user.id == user.id
  end

  test "connect with lowercase authorization bearer header authenticates user" do
    user = insert(:user)
    {:ok, token, _} = GuardianImpl.encode_and_sign(user)

    assert {:ok, socket} =
             connect(CF.GraphQLWeb.UserSocket, %{
               "authorization" => "Bearer #{token}"
             })

    assert absinthe_context(socket).user.id == user.id
  end

  test "connect with Authorization bearer header authenticates user" do
    user = insert(:user)
    {:ok, token, _} = GuardianImpl.encode_and_sign(user)

    assert {:ok, socket} =
             connect(CF.GraphQLWeb.UserSocket, %{
               "Authorization" => "Bearer #{token}"
             })

    assert absinthe_context(socket).user.id == user.id
  end

  test "connect with invalid token yields empty context" do
    assert {:ok, socket} = connect(CF.GraphQLWeb.UserSocket, %{"token" => "not-a-jwt"})
    assert absinthe_context(socket) == %{}
  end
end
