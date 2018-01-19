# Start everything

ExUnit.start
Faker.start

Ecto.Adapters.SQL.Sandbox.mode(DB.Repo, :manual)
