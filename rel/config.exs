use Distillery.Releases.Config, default_environment: :prod

# Environments

environment :dev do
  # Disable symlinks that breaks docker dev image release. Uncomment to debug build
  set(dev_mode: false)
  set(include_erts: false)
  set(include_src: false)
  set(cookie: :dev_cookie)
end

environment :prod do
  set(dev_mode: false)
  set(include_erts: false)
  set(include_src: false)

  set(
    cookie: String.to_atom(binary_part(Base.url_encode64(:crypto.strong_rand_bytes(32)), 0, 32))
  )

  set(
    config_providers: [
      {Distillery.Releases.Config.Providers.Elixir, ["${RELEASE_ROOT_DIR}/etc/config.exs"]}
    ]
  )

  set(
    overlays: [
      {:copy, "rel/runtime_config/config.exs", "etc/config.exs"}
    ]
  )
end

# Releases

release :cf_full_app do
  set(version: current_version(:cf_rest_api))
  set(applications: [:cf_rest_api, :cf_jobs, :cf_graphql, :cf_atom_feed])
  set(post_start_hooks: "rel/hooks/migrate_db")

  set(
    commands: [
      migrate: "rel/commands/migrate.sh",
      seed: "rel/commands/seed.sh",
      seed_politicians: "rel/commands/seed_politicians.sh"
    ]
  )
end

release :cf_rest_api do
  set(version: current_version(:cf_rest_api))
  set(applications: [:cf_rest_api])
  set(post_start_hooks: "rel/hooks/migrate_db")

  set(
    commands: [
      migrate: "rel/commands/migrate.sh",
      seed: "rel/commands/seed.sh",
      seed_politicians: "rel/commands/seed_politicians.sh"
    ]
  )
end

release :cf_jobs do
  set(version: current_version(:cf_jobs))
  set(applications: [:cf_jobs])
  set(commands: [migrate: "rel/commands/migrate.sh"])
end

release :cf_graphql do
  set(version: current_version(:cf_graphql))
  set(applications: [:cf_graphql])
  set(commands: [migrate: "rel/commands/migrate.sh"])
end

release :cf_atom_feed do
  set(version: current_version(:cf_atom_feed))
  set(applications: [:cf_atom_feed])
end
