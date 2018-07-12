defmodule CF.Opengraph.Case do
  use ExUnit.CaseTemplate

  @moduledoc """
  Custom ExUnit case which setup DB for tests
  """

  using do
    quote do
      setup do
        # Explicitly get a connection before each test
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(DB.Repo)
      end
    end
  end
end
