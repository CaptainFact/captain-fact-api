defmodule CF.GraphQL.Schema.Middleware.RequireAuthentication do
  @moduledoc """
  A middleware to force authentication.
  """

  @behaviour Absinthe.Middleware

  @doc false
  def call(resolution, _args) do
    if is_nil(resolution.context[:user]) do
      Absinthe.Resolution.put_result(resolution, {:error, "unauthorized"})
    else
      resolution
    end
  end
end
