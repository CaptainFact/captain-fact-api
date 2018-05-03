#!/usr/bin/env bash

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 MigrationName [MigrationParams...]"
  echo "----------------------Examples--------------------------"
  echo "$0 AddLocaleToInvitationRequest"
  exit 1
fi

IMAGE=bitwalker/alpine-elixir-phoenix:1.6.0
cd -- "$(dirname $0)/.."
docker run -it --rm --workdir=/app/apps/db --network=host -v `pwd`:/app ${IMAGE} mix ecto.gen.migration $@