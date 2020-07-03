#!/usr/bin/env bash
# Build the release and test it against a dev environment. Yay!
# ------------------------------------------------------------------

export MIX_ENV=prod
export CF_SECRET_KEY_BASE="8C6FsJwjV11d+1WPUIbkEH6gB/VavJrcXWoPLujgpclfxjkLkoNFSjVU9XfeNm6s"
export CF_HOST=localhost
export CF_DB_HOSTNAME=localhost
export CF_DB_USERNAME=postgres
export CF_DB_PASSWORD=postgres
export CF_DB_NAME=captain_fact_dev
export CF_FACEBOOK_APP_ID=xxxxxxxxxxxxxxxxxxxx
export CF_FACEBOOK_APP_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
export CF_FRONTEND_URL="http://localhost:3333"
export CF_CHROME_EXTENSION_ID="chrome-extension://fnnhlmbnlbgomamcolcpgncflofhjckm"
export CF_PORT=4242

# With Mix
mix release --overwrite
_build/prod/rel/full_app/bin/full_app start

# With Distillery
# mix distillery.release --env prod --name cf_full_app
# _build/prod/rel/cf_full_app/bin/cf_full_app foreground