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

## Install & Run

### Start DB

Create / launch a postgres instance on your local machine. If you have
docker installed, you can use the pre-seed postgres docker image:

`docker run -d --name cf_dev_db -p 5432:5432 captainfact/dev-db:latest`

### Start API services

- Without Docker (recommended if you want to make changes in the API)

  - `mix deps.get`
  - `mix ecto.migrate`
  - `iex -S mix`

- With Docker
  - Download project's dependencies with `./dev/get_dependencies.sh`
  - Migrate your database with `./dev/db_migrate.sh`
  - Start server with `./dev/start_server.sh`

Following services will be started:

- [localhost:4000](http://localhost:4000) - REST API
- [localhost:4001](https://localhost:4001) - REST API (https)
- [localhost:4002](http://localhost:4002) - GraphQL API
- [localhost:4003](https://localhost:4003) - GraphQL API (https)
- [localhost:4004](http://localhost:4004) - Atom feed

You can run tests with `./dev/test.sh`. You can filter which tests to run by
running something like `./dev/test.sh test/your_test_subpath`.
Check `./dev/test.sh` script comments for details.

## Project architecture

Elixir offers very nice ways to separate concerns and work with microservices.
This application is organized as an [umbrella project](https://elixir-lang.org/getting-started/mix-otp/dependencies-and-umbrella-apps.html) which allows us to divide CaptainFact API into small apps.

### File structure

```
.
├── apps
│   ├── cf => Core functions as a library. **Not deployed**
│   ├── cf_atom_feed => Atom feed.
│   ├── cf_graphql => GraphQL API (public).
│   ├── cf_jobs => Jobs.
│   ├── cf_opengraph => An app that generate opengraph tags.
│   ├── cf_rest_api => REST/WS API (private).
│   └── db => DB repository and schemas **Not deployed**
│       ├── lib
│       │   ├── db
│       │   ├── db_schema => Contains all the schemas (Video, Speaker, Comment...etc)
│       │   ├── db_type => Special types (SpeakerPicture...etc)
│       │   └── db_utils => Some utils functions
│       └── priv
│           └── repo/migrations => All DB migrations files
├── README.md => You're reading it right now. Are you?
├── rel => Release configs & tools
│   ├── commands => Commands that will be available to run on the release (seed DB...etc)
│   ├── hooks => Some hooks for automatically run commands when release run.
│   ├── runtime_config => Runtime configurations for all apps.
│   └── config.exs => Releases configuration.
```

## Styling

Code should follow [Elixy Style Guide](https://github.com/christopheradams/elixir_style_guide)
and [Credo style guide](https://github.com/rrrene/elixir-style-guide)
as much as possible.

Avoid lines longer than 80 characters, **never** go beyond 110 characters.

## Linked projects

- [Community discussions and documentation](https://github.com/CaptainFact/captain-fact/)
- [Frontend](https://github.com/CaptainFact/captain-fact-frontend)
- [Extension](https://github.com/CaptainFact/captain-fact-extension)
- [Overlay injector](https://github.com/CaptainFact/captain-fact-overlay-injector)

# Feature requests

[![Feature Requests](http://feathub.com/CaptainFact/captain-fact?format=svg)](http://feathub.com/CaptainFact/captain-fact)
