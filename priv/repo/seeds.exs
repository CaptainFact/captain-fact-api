# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     CaptainFact.Repo.insert!(%CaptainFact.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias CaptainFact.Repo
alias CaptainFact.User
alias CaptainFact.Speaker

admin = User.changeset(%User{}, %{
  username: "Betree",
  email: "admin@captainfact.com",
  password: "password"
})

Repo.insert!(admin)

# Some speakers
speakers = [
  %Speaker{full_name: "Nicolas Sarkozy", title: "Former French President"},
  %Speaker{full_name: "Donald Trump", title: "President of the USA"},
  %Speaker{full_name: "Marine Lepen", title: "French Politician"},
  %Speaker{full_name: "Francois Fillon", title: "French Politician"},
  %Speaker{full_name: "Cécile Duflot", title: "French Politician"},
  %Speaker{full_name: "Jean-Luc Mélenchon", title: "French Politician"}
]

Enum.each speakers, fn(speaker) ->
  speaker = Map.put(speaker, :is_user_defined, false)
  Repo.insert!(speaker)
end
