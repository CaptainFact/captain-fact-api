alias CaptainFact.Repo
alias CaptainFact.Accounts.{User, Achievement}


# Create achievements
# [!] Don't change the order - new items must be inserted at the end
achievements = [
  %{slug: "welcome", rarity: 0},
  %{slug: "not-a-robot", rarity: 0},
  %{slug: "help", rarity: 0},
  %{slug: "bulletproof", rarity: 0},
  %{slug: "you-re-fake-news", rarity: 1},
]

for params <- achievements do
  case Repo.get_by(Achievement, slug: params.slug) do
    nil -> Repo.insert!(Achievement.changeset(%Achievement{}, params))
    existing -> Repo.update(Achievement.changeset(existing, params))
  end
end

# Create Admin for dev
if Kernel.function_exported?(Mix, :env, 0) && Mix.env == :dev do
  admin = User.registration_changeset(%User{reputation: 4200}, %{
    username: "Betree",
    email: "admin@captainfact.io",
    password: "password"
  })

  Repo.insert(admin) # No need to warn if already exists
end