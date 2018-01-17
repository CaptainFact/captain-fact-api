# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
Path.join(["rel", "plugins", "*.exs"])
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
    # This sets the default release built by `mix release`
    default_release: :default,
    # This sets the default environment used by `mix release`
    default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/configuration.html


# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :"MfqNgHUln;rEBpHUv^)@~8.b1wJ)>0W3<drs>ZRk0(S>qMU):<JtlEIiwR|/Oc>R"
end

environment :prod do
  set include_erts: false
  set include_src: false
  set cookie: :"86@K5T~*`8U71EA5oGP?zEy~`b]@~CS{I|]OJn6EW|>V2A]r|(w[LYl69!;;[n$P"
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :captain_fact do
  set version: current_version(:captain_fact)
  set applications: [:runtime_tools]
  set post_start_hook: "rel/hooks/post_start.sh"
  set commands: [
    "migrate": "rel/commands/migrate.sh",
    "seed": "rel/commands/seed.sh",
    "seed_politicians": "rel/commands/seed_politicians.sh"
  ]
end

release :captain_fact_graphql do
  set version: current_version(:captain_fact_graphql)
  set applications: [:runtime_tools]
  set post_start_hook: "rel/hooks/post_start.sh"
  set commands: [
    "migrate": "rel/commands/migrate.sh",
    "seed": "rel/commands/seed.sh",
    "seed_politicians": "rel/commands/seed_politicians.sh"
  ]
end
