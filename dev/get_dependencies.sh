#!/usr/bin/env bash

cd -- "$(dirname $0)/.."
source "./dev/_common.sh"

docker run -it \
  --rm \
  --workdir=/app \
  -v `pwd`:/app \
  ${CF_ELIXIR_IMAGE} \
  mix deps.get
