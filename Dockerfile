# ---- BUILD ----

FROM bitwalker/alpine-elixir:1.5.1 as build_container

# Install build requirements
RUN apk add gcc make libc-dev libgcc

# Configure
ENV HOME=/opt/app/ MIX_ENV=prod
WORKDIR /opt/app

# Cache dependencies
COPY mix.exs mix.lock ./
RUN mix local.hex --force && mix local.rebar --force
RUN mix deps.get

# Copy main project and build release
COPY . .
RUN mix release --env=prod
RUN tar c -C ./_build/prod/rel/captain_fact/ -f captain-fact-api_release.tar bin lib releases

# ---- RELEASE ----

FROM bitwalker/alpine-elixir:1.5.1
RUN apk add bash imagemagick && rm -rf /var/cache/apk/*

ENV HOME=/opt/app/ SHELL=/bin/bash MIX_ENV=prod
WORKDIR /opt/app

COPY --from=build_container /opt/app/captain-fact-api_release.tar .
RUN tar x -f captain-fact-api_release.tar && rm captain-fact-api_release.tar

EXPOSE 80 443
ENTRYPOINT ["bin/captain_fact"]
