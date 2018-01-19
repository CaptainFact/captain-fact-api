# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
Path.join(["rel", "plugins", "*.exs"])
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
    default_release: :default,
    default_environment: Mix.env()

# Environments

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

# Releases

release :captain_fact_rest do
  set version: current_version(:captain_fact_rest)
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
