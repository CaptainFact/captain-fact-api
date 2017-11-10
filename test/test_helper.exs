# Start everything

ExUnit.start
Faker.start

Ecto.Adapters.SQL.Sandbox.mode(CaptainFact.Repo, {:shared, self()})
{:ok, _} = Application.ensure_all_started(:ex_machina)
{:ok, _} = Application.ensure_all_started(:bypass)


# Some helpers

defmodule CaptainFact.TestHelpers do
  import CaptainFact.Factory

  def flag_comments(comments, nb_flags, reason \\ 1) do
    users = insert_list(nb_flags, :user, %{reputation: 1000})
    Enum.map(comments, fn comment ->
      Enum.map(users, fn user ->
        CaptainFact.Actions.Flagger.flag!(user.id, comment, reason)
      end)
    end)
  end
end