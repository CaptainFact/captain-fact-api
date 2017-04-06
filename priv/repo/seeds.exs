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
Repo.insert!(%Speaker{full_name: "Nicolas Sarkozy", is_user_defined: false})
Repo.insert!(%Speaker{full_name: "Donald Trump", is_user_defined: false})
Repo.insert!(%Speaker{full_name: "Marine Lepen", is_user_defined: false})
Repo.insert!(%Speaker{full_name: "Francois Fillon", is_user_defined: false})
Repo.insert!(%Speaker{full_name: "Cécile Duflot", is_user_defined: false})
Repo.insert!(%Speaker{full_name: "Jean-Luc Mélenchon", is_user_defined: false})
