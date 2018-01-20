# Start everything

ExUnit.start
Faker.start

Ecto.Adapters.SQL.Sandbox.mode(DB.Repo, {:shared, self()})
{:ok, _} = Application.ensure_all_started(:ex_machina)
{:ok, _} = Application.ensure_all_started(:bypass)
