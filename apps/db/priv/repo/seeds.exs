require Logger

# Create Cypress video (hash Jzqg), seed statement, then admin — order keeps video id=1 for /videos/Jzqg
if Application.get_env(:db, :env) == :dev do
  Logger.warning("API is running in dev mode. Running dev seeds (admin user + Cypress video)")

  DB.Seeds.seed_dev_data()
end
