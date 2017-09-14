#!/usr/bin/env bash
#---------------------------------------------------------------------------------------------------
# Start a docker release with dev params
# Usage ./test_docker_release.sh
#
# /!\ Obviously database must be started
#---------------------------------------------------------------------------------------------------


cd -- "$(dirname $0)/.."

CF_API_BUILD_IMAGE=captain-fact-api-build:dev-check
CF_API_IMAGE=captain-fact-api:dev-check

# Build
docker build -t ${CF_API_BUILD_IMAGE} -f Dockerfile.build .
BUILD_CONTAINER=$(docker run -d ${CF_API_BUILD_IMAGE})
docker cp ${BUILD_CONTAINER}:/opt/app/captain-fact-api_release.tar ./captain-fact-api_release.tar
docker stop ${BUILD_CONTAINER} && docker rm ${BUILD_CONTAINER}
docker build -t ${CF_API_IMAGE} -f Dockerfile.release .
rm ./captain-fact-api_release.tar

# Run server
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
  --rm ${CF_API_IMAGE} foreground

# Cleanup
#docker rmi -f ${CF_API_IMAGE}
