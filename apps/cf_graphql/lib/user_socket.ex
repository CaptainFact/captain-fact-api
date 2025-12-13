defmodule CF.GraphQLWeb.UserSocket do
  use Phoenix.Socket
  use Absinthe.Phoenix.Socket, schema: CF.Graphql.Schema

  alias CF.Authenticator.GuardianImpl

  def connect(params, socket) do
    context = build_context(params)

    socket =
      socket
      |> Absinthe.Phoenix.Socket.put_options(context: context)

    {:ok, socket}
  end

  def id(_socket), do: nil

  defp build_context(params) do
    with {:ok, token} <- fetch_token(params),
         {:ok, user, _claims} <- GuardianImpl.resource_from_token(token) do
      %{user: user}
    else
      _ -> %{}
    end
  end

  defp fetch_token(%{"token" => token}) when is_binary(token), do: {:ok, token}
  defp fetch_token(%{"authorization" => "Bearer " <> token}), do: {:ok, token}
  defp fetch_token(%{"Authorization" => "Bearer " <> token}), do: {:ok, token}
  defp fetch_token(_), do: :error
end



