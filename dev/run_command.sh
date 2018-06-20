#!/usr/bin/env bash

cd -- "$(dirname $0)/.."
source "./dev/_common.sh"

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 command"
  echo "----------------------Examples--------------------------"
  echo "Run test suite:       $0 mix test"
  echo "Start dev server:     $0 iex -S mix phx.server"
  echo "DB - Run migrations:  $0 mix ecto.migrate"
  exit 1
fi

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
  $@
  