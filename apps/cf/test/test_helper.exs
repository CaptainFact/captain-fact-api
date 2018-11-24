# Start everything

Ecto.Adapters.SQL.Sandbox.mode(DB.Repo, {:shared, self()})
{:ok, _} = Application.ensure_all_started(:bypass)

ExUnit.start()
