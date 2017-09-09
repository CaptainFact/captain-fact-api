#!/usr/bin/env bash
#---------------------------------------------------------------------------------------------------
# This script tries to run a release built with `MIX_ENV=prod mix release --env=prod` using dev
# configuration variables.
#
# /!\ Obviously database must be started
#---------------------------------------------------------------------------------------------------

MIX_ENV=prod mix release --env=prod

CF_HOST="localhost" \
CF_PORT="4000" \
CF_PORT_SSL="4001" \
CF_SECRET_KEY_BASE="8C6FsJwjV11d+1WPUIbkEH6gB/VavJrcXWoPLujgpclfxjkLkoNFSjVU9XfeNm6s" \
CF_DB_HOSTNAME="localhost" \
CF_DB_USERNAME="postgres" \
CF_DB_PASSWORD="postgres" \
CF_DB_NAME="captain_fact_dev" \
CF_FACEBOOK_APP_ID="506726596325615" \
CF_FACEBOOK_APP_SECRET="4b320056746b8e57144c889f3baf0424" \
./_build/prod/rel/captain_fact/bin/captain_fact foreground