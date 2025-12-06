import Config

# Import all app config files
for config <- "../apps/*/config/config.exs" |> Path.expand(__DIR__) |> Path.wildcard() do
  Config.import_config(config)
end

# Import secret config files
for config <- "./*.secret.exs" |> Path.expand(__DIR__) |> Path.wildcard() do
  Config.import_config(config)
end
