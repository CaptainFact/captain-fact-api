FROM bitwalker/alpine-elixir:1.6.6
RUN apk add bash imagemagick curl gcc make libc-dev libgcc && rm -rf /var/cache/apk/*

ENV HOME=/opt/app/ SHELL=/bin/bash MIX_ENV=prod
WORKDIR /opt/build

ARG APP

# Cache dependencies
COPY mix.exs mix.lock ./
COPY apps/captain_fact/mix.exs ./apps/captain_fact/
COPY apps/cf_atom_feed/mix.exs ./apps/cf_atom_feed/
COPY apps/cf_graphql/mix.exs ./apps/cf_graphql/
COPY apps/cf_opengraph/mix.exs ./apps/cf_opengraph/
COPY apps/cf_utils/mix.exs ./apps/cf_utils/
COPY apps/db/mix.exs ./apps/db/
RUN mix deps.get

COPY . .
RUN mix release --name ${APP} --env=$MIX_ENV

WORKDIR /opt/app
RUN cp -R /opt/build/_build/$MIX_ENV/rel/${APP}/* /opt/app/
RUN rm -rf /opt/build
RUN ln -s /opt/app/bin/${APP} bin/entrypoint

EXPOSE 80
ENTRYPOINT ["./bin/entrypoint"]
