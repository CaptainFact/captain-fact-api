defmodule CF.Graphql.Schema.Utils do
  @moduledoc """
  Utility functions for types and resolvers.
  """

  @default_join_complexity 50

  @doc """
  Sets the join complexity for given association. Default join complexity is
  set in @default_join_complexity which value is `50`
  """
  defmacro join_complexity(complexity \\ @default_join_complexity) do
    quote do
      fn _, child_complexity -> unquote(complexity) + child_complexity end
    end
  end
end
