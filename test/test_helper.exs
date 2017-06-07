ExUnit.start
Faker.start

Ecto.Adapters.SQL.Sandbox.mode(CaptainFact.Repo, {:shared, self()})
