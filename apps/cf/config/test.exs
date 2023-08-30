use Mix.Config

# General config
config :cf, frontend_url: "https://TEST_FRONTEND/", deploy_env: "test"

# Don't fetch user picture on test environment
config :cf, fetch_default_user_picture: false

# Configure Guardian (authentication)
config :cf,
       CF.Authenticator.GuardianImpl,
       secret_key: "psZ6n/fq0b444U533yKtve2R0rpjk/IxRGpuanNE92phSDy8/Z2I8lHaIugCMOY7"

# Print only warnings and errors during test
config :logger, level: :warn

# Mails
config :cf, CF.Mailer, adapter: Bamboo.TestAdapter

# Reduce the number of round for encryption during tests
config :bcrypt_elixir, :log_rounds, 4

# Behaviours mock for testing
config :cf, captions_fetcher: CF.Videos.CaptionsFetcherTest
config :cf, use_test_video_metadata_fetcher: true
