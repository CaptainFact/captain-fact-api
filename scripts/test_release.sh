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
# mix release --overwrite
# _build/prod/rel/full_app/bin/full_app start

# With Docker
docker build -t cf-test-release .
docker run \
  -e MIX_ENV \
  -e CF_SECRET_KEY_BASE \
  -e CF_HOST \
  -e CF_DB_HOSTNAME \
  -e CF_DB_USERNAME \
  -e CF_DB_PASSWORD \
  -e CF_DB_NAME \
  -e CF_FACEBOOK_APP_ID \
  -e CF_FACEBOOK_APP_SECRET \
  -e CF_FRONTEND_URL \
  -e CF_CHROME_EXTENSION_ID \
  -e CF_PORT \
  --network="host" \
  cf-test-release
