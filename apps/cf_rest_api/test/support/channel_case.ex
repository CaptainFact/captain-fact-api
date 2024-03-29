defmodule CF.RestApi.ChannelCase do
  @moduledoc """
  This module defines the test case to be used by
  channel tests.

  Such tests rely on `Phoenix.ChannelTest` and also
  import other functionality to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate
  import Mock

  # Mock all calls to Algolia
  setup_with_mocks([
    {Algoliax.Client, [], [request: fn _ -> nil end]}
  ]) do
    :ok
  end

  using do
    quote do
      # Import conveniences for testing with channels
      use Phoenix.ChannelTest
      import DB.Factory

      # The default endpoint for testing
      @endpoint CF.RestApi.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DB.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(DB.Repo, {:shared, self()})
    end

    :ok
  end
end
