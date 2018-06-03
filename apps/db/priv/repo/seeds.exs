alias DB.Repo
alias DB.Schema.User
require Logger

# Create Admin in dev or if we're running image locally
if Application.get_env(:db, :env) == :dev do
  Logger.warn("API is running in dev mode. Inserting default user admin@captainfact.io")

  admin =
    User.registration_changeset(%User{reputation: 4200, username: "Captain"}, %{
      email: "admin@captainfact.io",
      password: "password"
    })

  # No need to warn if already exists
  Repo.insert(admin)
end
