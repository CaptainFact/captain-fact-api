#!/usr/bin/env bash

cd -- "$(dirname $0)/.."
source "./dev/_common.sh"

docker run -it \
  --rm \
  --workdir=/app \
  --link $CF_DB_DEV_IMAGE:localhost \
  -v `pwd`:/app \
  ${CF_ELIXIR_IMAGE} \
  mix ecto.migrate
