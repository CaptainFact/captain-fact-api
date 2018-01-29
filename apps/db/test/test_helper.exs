# Start everything

ExUnit.start
Faker.start

# Load runtime configuration
DB.RuntimeConfiguration.setup()
DB.RuntimeConfiguration.configure()

Ecto.Adapters.SQL.Sandbox.mode(DB.Repo, {:shared, self()})
{:ok, _} = Application.ensure_all_started(:ex_machina)
