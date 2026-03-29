defmodule CF.Graphql.CustomAbsinthePlug do
  @moduledoc """
  Custom Absinthe plug that catches all exceptions and converts them
  to proper GraphQL errors instead of letting Phoenix return HTML error pages.
  """

  import Plug.Conn
  alias CF.Accounts.UserPermissions.PermissionsError

  def init(opts) do
    Absinthe.Plug.init(opts)
  end

  @spec call(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def call(conn, opts) do
    try do
      Absinthe.Plug.call(conn, opts)
    rescue
      e in PermissionsError ->
        # Convert the PermissionsError to a GraphQL error response
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, build_graphql_error_response(e.message, "FORBIDDEN"))

      exception ->
        # Convert any other exception to a GraphQL error response
        error_message = Exception.message(exception)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, build_graphql_error_response(error_message, "INTERNAL_ERROR"))
    end
  end

  defp build_graphql_error_response(message, code) do
    Jason.encode!(%{
      "errors" => [
        %{
          "message" => message,
          "extensions" => %{
            "code" => code
          }
        }
      ],
      "data" => nil
    })
  end
end
