alias CaptainFact.Repo
alias CaptainFact.Accounts.User

admin = User.changeset(%User{reputation: 4200}, %{
  username: "Betree",
  email: "admin@captainfact.io",
  password: "password"
})

Repo.insert!(admin)
