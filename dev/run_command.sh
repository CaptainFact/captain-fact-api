#!/usr/bin/env bash

IMAGE=bitwalker/alpine-elixir-phoenix:1.6.0

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 command"
  echo "----------------------Examples--------------------------"
  echo "Run test suite:       $0 mix test"
  echo "Start dev server:     $0 iex -S mix phx.server"
  echo "DB - Run migrations:  $0 mix ecto.migrate"
  exit 1
fi

cd -- "$(dirname $0)/.."
docker run -it --rm --workdir=/app --network=host -v `pwd`:/app ${IMAGE} $@