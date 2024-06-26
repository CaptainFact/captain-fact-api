defmodule CF.Graphql.Schema.Middleware.RequireReputation do
  @moduledoc """
  A middleware to ensure the user has a certain reputation.
  """

  @behaviour Absinthe.Middleware

  @doc false
  def call(resolution, reputation) do
    cond do
      is_nil(resolution.context[:user]) ->
        Absinthe.Resolution.put_result(resolution, {:error, "unauthorized"})

      resolution.context[:user].reputation && resolution.context[:user].reputation < reputation ->
        Absinthe.Resolution.put_result(
          resolution,
          {:error,
           %{
             code: "unauthorized",
             message: "You do not have the required reputation to perform this action.",
             details: %{
               user_reputation: resolution.context[:user].reputation,
               required_reputation: reputation
             }
           }}
        )

      true ->
        resolution
    end
  end
end
