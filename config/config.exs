use Mix.Config

import_config "../apps/*/config/config.exs"
import_config "./*.secret.exs" # TODO should filter by env
