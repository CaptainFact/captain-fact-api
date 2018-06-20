#!/usr/bin/env bash

cd -- "$(dirname $0)/.."
source "./dev/_common.sh"

docker run -it \
  --rm \
  --workdir=/app \
  -p 4000:4000 \
  -p 4001:4001 \
  -p 4002:4002 \
  -p 4003:4003 \
  -p 4004:4004 \
  --link $CF_DB_DEV_IMAGE:localhost \
  -v `pwd`:/app \
  ${CF_ELIXIR_IMAGE} \
  iex -S mix phx.server
