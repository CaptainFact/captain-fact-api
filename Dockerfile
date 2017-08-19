FROM betree/alpine-elixir-gcc:1.5.1 as builder

ENV HOME=/opt/app/ TERM=xterm

WORKDIR /opt/app
ENV MIX_ENV=prod REPLACE_OS_VARS=true

COPY . .
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix deps.compile
RUN mix release --env=prod
RUN ls -R _build/prod/rel


FROM bitwalker/alpine-elixir:1.5.1
ENV MIX_ENV=prod REPLACE_OS_VARS=true SHELL=/bin/bash PORT=80 PORT_SSL=443

WORKDIR /opt/app
COPY --from=builder /opt/app/_build/prod/rel/captain_fact .

EXPOSE 80 443
ENTRYPOINT ["bin/captain_fact"]