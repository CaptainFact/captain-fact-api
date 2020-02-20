<p align="center"><img src="https://avatars0.githubusercontent.com/u/28169525?s=200&v=4" height="100"/></p>
<h1 align="center"><a href="https://captainfact.io">CaptainFact.io</a></h1>
<p align="center"><a href="https://discord.gg/2Qd7hMz" title="Discord"><img src="https://discordapp.com/api/guilds/416782744748687361/widget.png" alt="Discord"></a>
<a href="https://twitter.com/CaptainFact_io" title="Twitter"><img src="https://img.shields.io/twitter/follow/CaptainFact_io.svg?style=social&label=Follow"></a>
<a href="https://opencollective.com/captainfact_io" title="Backers on Open Collective"><img src="https://opencollective.com/captainfact_io/backers/badge.svg"></a>
<a href="./LICENSE"><img src="https://img.shields.io/github/license/CaptainFact/captain-fact-api.svg" alt="AGPL3"></a>
<a href="https://travis-ci.com/CaptainFact/captain-fact-api"><img src="https://travis-ci.com/CaptainFact/captain-fact-api.svg?branch=staging"></a>
<a href='https://coveralls.io/github/CaptainFact/captain-fact-api?branch=staging'><img src='https://coveralls.io/repos/github/CaptainFact/captain-fact-api/badge.svg?branch=staging' alt='Coverage Status' /></a>
</p>
<hr/>
<p align="center">
<a href="https://opencollective.com/captainfact_io/donate" target="_blank">
  <img src="https://opencollective.com/captainfact_io/donate/button@2x.png?color=white" width=300 />
</a>
</p>
<hr/>
<br/>

# Install & Run

## Prerequisites

You need to install Elixir. We recommand using [asdf-vm](https://github.com/asdf-vm/asdf#setup).
Check their documentation on how to install it, then run `asdf install` from
root `captain-fact-api` folder.

## Start DB

Create / launch a PostgreSQL instance on your local machine. If you have
Docker installed, you can use the pre-Seed PostgreSQL Docker image:

`docker run -d --name cf_dev_db -p 5432:5432 captainfact/dev-db:latest`

## Start API

- `mix deps.get` --> Get dependencies
- `mix ecto.migrate` --> Migrate DB
- `iex -S mix` --> Start project

Following services will be started:

- [localhost:4000](http://localhost:4000) - REST API
- [localhost:4001](https://localhost:4001) - REST API (HTTPS)
- [localhost:4002](http://localhost:4002) - GraphQL API
- [localhost:4003](https://localhost:4003) - GraphQL API (HTTPS)
- [localhost:4004](http://localhost:4004) - Atom feed

You can also see all e-mail sent, by going to http://localhost:4000/_dev/mail

## Other useful commands

- `mix test` --> Run tests
- `mix test.watch` --> Run test watcher
- `mix format` --> Format code
- `mix ecto.gen.migration [migration_name]` --> Generate migration

# Project architecture

This application is organized as an [umbrella project](https://elixir-lang.org/getting-started/mix-otp/dependencies-and-umbrella-apps.html) which allows us to divide CaptainFact API into small apps.

```
.
├── apps
│   ├── cf => Core functions as a library. **Not deployed**
│   ├── cf_atom_feed => Atom feed.
│   ├── cf_graphql => GraphQL API (public).
│   ├── cf_jobs => Jobs.
│   ├── cf_rest_api => REST/WS API (private).
│   └── db => DB repository and schemas **Not deployed**
│       ├── lib
│       │   ├── db
│       │   ├── db_schema => Contains all the schemas (Video, Speaker, Comment…etc)
│       │   ├── db_type => Special types (SpeakerPicture…etc.)
│       │   └── db_utils => Some utility functions
│       └── priv
│           └── repo/migrations => All DB migrations files
├── README.md => You're reading it right now. Are you?
├── rel => Release configs & tools
│   ├── commands => Commands that will be available to run on the release (seed DB…etc.)
│   ├── hooks => Some hooks for automatically run commands when release run.
│   ├── runtime_config => Runtime configurations for all apps.
│   └── config.exs => Release configuration.
```

# Linked projects

- [Community discussions and documentation](https://github.com/CaptainFact/captain-fact/)
- [Front-end](https://github.com/CaptainFact/captain-fact-frontend)
- [Extension](https://github.com/CaptainFact/captain-fact-extension)
- [Overlay injector](https://github.com/CaptainFact/captain-fact-overlay-injector)
