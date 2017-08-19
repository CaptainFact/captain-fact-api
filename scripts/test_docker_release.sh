#!/usr/bin/env bash
#---------------------------------------------------------------------------------------------------
# Start a docker release with dev params
# Usage ./test_docker_release.sh container
#
# /!\ Obviously database must be started
#---------------------------------------------------------------------------------------------------

docker run -it \
  -p 4000:80 \
  -p 4001:443 \
  -e "HOST=localhost" \
  -e "PORT=4000" \
  -e "PORT_SSL=4001" \
  -e "SECRET_KEY_BASE=8C6FsJwjV11d+1WPUIbkEH6gB/VavJrcXWoPLujgpclfxjkLkoNFSjVU9XfeNm6s" \
  -e "SSL_KEY_PATH=priv/keys/localhost.key" \
  -e "SSL_CERT_PATH=priv/keys/localhost.cert" \
  -e "DB_HOSTNAME=localhost" \
  -e "DB_USERNAME=postgres" \
  -e "DB_PASSWORD=postgres" \
  -e "DB_NAME=captain_fact_dev" \
  -e "FACEBOOK_APP_ID=506726596325615" \
  -e "FACEBOOK_APP_SECRET=4b320056746b8e57144c889f3baf0424" \
  -e "FRONTEND_URL=http://localhost:3333" \
  -e "CHROME_EXTENSION_ID=chrome-extension://lpdmcoikcclagelhlmibniibjilfifac" \
  --network host \
  --rm $1 foreground
