# CaptainFact API

Staging-[![pipeline status](https://gitlab.com/CaptainFact/captain-fact-api/badges/staging/pipeline.svg)](https://gitlab.com/CaptainFact/captain-fact-api/commits/staging)
&nbsp;&nbsp;
Master-[![pipeline status](https://gitlab.com/CaptainFact/captain-fact-api/badges/master/pipeline.svg)](https://gitlab.com/CaptainFact/captain-fact-api/commits/master)

## Install & Run

  * [Install Elixir & Phoenix](https://elixir-lang.org/install.html)
  * Install Phoenix (web framework): `mix local.hex && mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new.ez`
  * Install dependencies with `mix deps.get`
  * Create / launch a postrges instance on your local machine:
  `docker run -d --name postgres_dev -p 5432:5432 -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=captain_fact_dev postgres:9.6`
  * Create and migrate your database with `mix ecto.setup`
  * Start server with `mix phx.server` or with `iex -S mix phx.server` if you need access to an Elixir console
  * You can also run tests with `mix test` (may generate some warnings, only check final results)

## Project architecture

Elixir offers very nice ways to separate concerns and work with microservices.
This application is organized as an [umbrella project](https://elixir-lang.org/getting-started/mix-otp/dependencies-and-umbrella-apps.html)
which allows us to divide CaptainFact API into small apps.

* Current architecture (blue = deployed releases, others = libraries)

```mermaid
graph BT;
    CaptainFact[Core, REST API and Jobs] --> DB[DB - Repository and schemas];
    GraphQL[GraphQL API] --> DB;
    
    style CaptainFact fill:#BBF;
    style GraphQL fill:#BBF;
```

* Future architecture (blue = deployed releases, others = libraries)

```mermaid
graph BT;
    Core --> DB[DB - Repository and schemas];
    GraphQL[GraphQL API] --> Core;
    REST_API[REST API] --> Core;
    Jobs --> Core;
    
    style GraphQL fill:#BBF;
    style REST_API fill:#BBF;
    style Jobs fill:#BBF;
    style Core fill:#BBF;
```

### File structure


```
.
├── apps
│   ├── captain_fact => Currently, a monolith containing REST API, jobs and core functions
│   │   ├── lib
│   │   │   ├── captain_fact => Core functions + jobs
│   │   │   └── captain_fact_web => REST API
│   │   └── priv/secrets => dev secrets for this app
│   ├── captain_fact_graphql => GraphQL API
│   │   └── priv/secrets => dev secrets for this app
│   └── db => DB repository and schemas
│       ├── lib
│       │   ├── db
│       │   ├── db_schema => Contains all the schemas (Video, Speaker, Comment...etc)
│       │   ├── db_type => Special types (SpeakerPicture...etc)
│       │   └── db_utils => Some utils functions
│       └── priv
│           ├── repo/migrations => All DB migrations files
│           └── secrets => dev secrets for DB (db username, password...etc)
├── README.md => You're reading it right now. Are you ?
├── rel => Release configs & tools
│   ├── commands => Commands that will be available to run on the release (seed DB...etc)
│   ├── config.exs => Releases configuration
│   └── docker => Docker-specific files & configs
```
