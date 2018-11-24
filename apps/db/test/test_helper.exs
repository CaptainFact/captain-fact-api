# Start everything

Faker.start()

Ecto.Adapters.SQL.Sandbox.mode(DB.Repo, {:shared, self()})
{:ok, _} = Application.ensure_all_started(:ex_machina)

ExUnit.start()
