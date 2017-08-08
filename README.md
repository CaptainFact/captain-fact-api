# CaptainFact

## Install

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  
## Configure

Configuration should not be necessary in dev if you're using a Jetbrains IDE with main repo's
configuration.

Following environment variables are required :

* FACEBOOK_CLIENT_ID
* FACEBOOK_CLIENT_SECRET
* SECRET_KEY
* SSL_KEY_PATH
* SSL_CERT_PATH
  
## Run

Start Phoenix endpoint with `mix phx.server`

API is started on [`localhost:4000`](http://localhost:4000) for http and
[`localhost:4001`](http://localhost:4001) for https.


## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Source: https://github.com/phoenixframework/phoenix
