FROM bitwalker/alpine-elixir:1.10.2
RUN apk update && apk upgrade
RUN apk add bash imagemagick curl gcc make libc-dev libgcc && rm -rf /var/cache/apk/*

ENV HOME=/opt/app/ SHELL=/bin/bash MIX_ENV=prod
WORKDIR /opt/build

# Cache dependencies
COPY mix.exs mix.lock ./
COPY apps/cf/mix.exs ./apps/cf/
COPY apps/cf_atom_feed/mix.exs ./apps/cf_atom_feed/
COPY apps/cf_graphql/mix.exs ./apps/cf_graphql/
COPY apps/cf_jobs/mix.exs ./apps/cf_jobs/
COPY apps/cf_rest_api/mix.exs ./apps/cf_rest_api/
COPY apps/cf_reverse_proxy/mix.exs ./apps/cf_reverse_proxy/
COPY apps/db/mix.exs ./apps/db/
RUN HEX_HTTP_CONCURRENCY=4 HEX_HTTP_TIMEOUT=180 mix deps.get --only $MIX_ENV

# Build dependencies
COPY . .
RUN mix deps.compile

# Build app
RUN mix compile
RUN mix release

# Copy app to workdir and remove build files
WORKDIR /opt/app
RUN mv /opt/build/_build/$MIX_ENV/rel/full_app/* /opt/app/
RUN rm -rf /opt/build
RUN ln -s /opt/app/bin/full_app /opt/app/entrypoint
RUN ls

EXPOSE 80
ENTRYPOINT /opt/app/entrypoint start
