alias DB.Repo
alias DB.Accounts.User
require Logger


# Create Admin in dev or if we're running image locally
if Kernel.function_exported?(Mix, :env, 0) && Mix.env == :dev do
  Logger.warn("API is running in dev mode. Inserting default user admin@captainfact.io")
  admin = User.registration_changeset(%User{reputation: 4200, username: "Captain"}, %{
    email: "admin@captainfact.io",
    password: "password"
  })

  Repo.insert(admin) # No need to warn if already exists
end