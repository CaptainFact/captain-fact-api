#!/usr/bin/env bash
#---------------------------------------------------------------------------------------------------
# This script tries to run a release built with `MIX_ENV=prod mix release --env=prod` using dev
# configuration variables.
#
# /!\ Obviously database must be started
#---------------------------------------------------------------------------------------------------

REPLACE_OS_VARS=true \
HOST="localhost" \
PORT="4000" \
PORT_SSL="4001" \
SECRET_KEY_BASE="8C6FsJwjV11d+1WPUIbkEH6gB/VavJrcXWoPLujgpclfxjkLkoNFSjVU9XfeNm6s" \
SSL_KEY_PATH="priv/keys/localhost.key" \
SSL_CERT_PATH="priv/keys/localhost.cert" \
DB_HOSTNAME="localhost" \
DB_USERNAME="postgres" \
DB_PASSWORD="postgres" \
DB_NAME="captain_fact_dev" \
FACEBOOK_APP_ID="506726596325615" \
FACEBOOK_APP_SECRET="4b320056746b8e57144c889f3baf0424" \
./_build/prod/rel/captain_fact/bin/captain_fact foreground