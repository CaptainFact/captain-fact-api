#!/usr/bin/env bash
#---------------------------------------------------------------------------------------------------
# Start a docker release with dev params
# Usage ./test_docker_release.sh
#
# /!\ Obviously database must be started
#---------------------------------------------------------------------------------------------------

CF_REST_API_IMAGE=captain-fact-api:dev-test
CF_GRAPHQL_API_IMAGE=captain-fact-api-graphql:dev-test

# If any command fails, exit
set -e

# Build
cd -- "$(dirname $0)"
./build_release.sh dev $CF_REST_API_IMAGE $CF_GRAPHQL_API_IMAGE

# Run server
echo "Let's test REST API =>"
docker run -it \
  -p 4000:80 \
  -p 4001:443 \
  -e "CF_HOST=localhost" \
  -e "CF_SECRET_KEY_BASE=8C6FsJwjV11d+1WPUIbkEH6gB/VavJrcXWoPLujgpclfxjkLkoNFSjVU9XfeNm6s" \
  -e "CF_DB_HOSTNAME=localhost" \
  -e "CF_DB_USERNAME=postgres" \
  -e "CF_DB_PASSWORD=postgres" \
  -e "CF_DB_NAME=captain_fact_dev" \
  -e "CF_FACEBOOK_APP_ID=506726596325615" \
  -e "CF_FACEBOOK_APP_SECRET=4b320056746b8e57144c889f3baf0424" \
  -e "CF_FRONTEND_URL=http://localhost:3333" \
  -e "CF_CHROME_EXTENSION_ID=chrome-extension://lpdmcoikcclagelhlmibniibjilfifac" \
  -v "$(pwd)/priv/keys:/run/secrets:ro" \
  --network host \
  --rm ${CF_REST_API_IMAGE} console

echo "Let's test GraphQL API =>"
echo "[TODO]"

# Cleanup
docker rmi -f ${CF_REST_API_IMAGE}
