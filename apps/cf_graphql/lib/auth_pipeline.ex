defmodule CF.GraphQL.AuthPipeline do
  @moduledoc """
  Adds the token authentification from CF app to graphql API.
  """

  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    case build_context(conn) do
      {:ok, context} ->
        put_private(conn, :absinthe, %{context: context})

      _ ->
        conn
    end
  end

  defp build_context(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, current_user, _claims} <- authorize(token) do
      {:ok, %{user: current_user}}
    end
  end

  defp authorize(token) do
    CF.Authenticator.GuardianImpl.resource_from_token(token)
  end
end
