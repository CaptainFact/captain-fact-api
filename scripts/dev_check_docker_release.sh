#!/usr/bin/env bash
#---------------------------------------------------------------------------------------------------
# Start a docker release with dev params
# Usage ./test_docker_release.sh
#
# /!\ Obviously database must be started
#---------------------------------------------------------------------------------------------------


CF_API_IMAGE=captain-fact-api:dev-check
CF_API_BUILD_IMAGE=captain-fact-api-build:dev-check

# Build
docker build -t ${CF_API_BUILD_IMAGE} -f Dockerfile.build .
BUILD_CONTAINER=$(docker run -d ${CF_API_BUILD_IMAGE})
docker cp ${BUILD_CONTAINER}:/opt/app/captain-fact-api_release.tar ./captain-fact-api_release.tar
docker build -t ${CF_API_IMAGE} -f Dockerfile.release .

# Run server
docker run -it \
  -p 4000:80 \
  -p 4001:443 \
  -e "HOST=localhost" \
  -e "PORT=4000" \
  -e "PORT_SSL=4001" \
  -e "SECRET_KEY_BASE=8C6FsJwjV11d+1WPUIbkEH6gB/VavJrcXWoPLujgpclfxjkLkoNFSjVU9XfeNm6s" \
  -e "SSL_KEY_PATH=priv/keys/privkey.pem" \
  -e "SSL_CERT_PATH=priv/keys/cert.pem" \
  -e "DB_HOSTNAME=localhost" \
  -e "DB_USERNAME=postgres" \
  -e "DB_PASSWORD=postgres" \
  -e "DB_NAME=captain_fact_dev" \
  -e "FACEBOOK_APP_ID=506726596325615" \
  -e "FACEBOOK_APP_SECRET=4b320056746b8e57144c889f3baf0424" \
  -e "FRONTEND_URL=http://localhost:3333" \
  -e "CHROME_EXTENSION_ID=chrome-extension://lpdmcoikcclagelhlmibniibjilfifac" \
  --network host \
  --rm ${CF_API_IMAGE} foreground

# Cleanup
docker stop ${BUILD_CONTAINER} && docker rm ${BUILD_CONTAINER}
docker rmi -f ${CF_API_IMAGE} ${CF_API_BUILD_IMAGE}
rm captain-fact-api_release.tar
