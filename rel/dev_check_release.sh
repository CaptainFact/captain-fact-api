#!/usr/bin/env bash
#---------------------------------------------------------------------------------------------------
# Start a docker release with dev params
# Usage ./test_docker_release.sh
#
# /!\ Database must be started
#---------------------------------------------------------------------------------------------------

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 app_name"
  echo "Example: $0 cf_jobs"
  exit 1
fi


TMP_IMAGE_NAME=cf_dev_check_release

# If any command fails, exit
set -e

# Build
cd -- "$(dirname $0)"
docker build -t $TMP_IMAGE_NAME --build-arg APP=$1 ../

# Run server
echo "Let's test this app! =>"
docker run -it \
  -e "CF_HOST=localhost" \
  -e "CF_SECRET_KEY_BASE=8C6FsJwjV11d+1WPUIbkEH6gB/VavJrcXWoPLujgpclfxjkLkoNFSjVU9XfeNm6s" \
  -e "CF_S3_ACCESS_KEY_ID=test" \
  -e "CF_S3_SECRET_ACCESS_KEY=test" \
  -e "CF_S3_BUCKET=test" \
  -e "CF_DB_HOSTNAME=localhost" \
  -e "CF_DB_USERNAME=postgres" \
  -e "CF_DB_PASSWORD=postgres" \
  -e "CF_DB_NAME=captain_fact_dev" \
  -e "CF_FACEBOOK_APP_ID=506726596325615" \
  -e "CF_FACEBOOK_APP_SECRET=4b320056746b8e57144c889f3baf0424" \
  -e "CF_FRONTEND_URL=http://localhost:3333" \
  -e "CF_CHROME_EXTENSION_ID=chrome-extension://lpdmcoikcclagelhlmibniibjilfifac" \
  -e "CF_BASIC_AUTH_PASSWORD=password" \
  -v "$(pwd)/../priv/secrets:/run/secrets:ro" \
  --network host \
  --rm ${TMP_IMAGE_NAME} console
