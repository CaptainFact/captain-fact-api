#!/usr/bin/env bash

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 build_image rest_api_image graphql_api_image"
  exit 1
fi

cd -- "$(dirname $0)"

# If any command fails, exit
set -e

# Define some global config
CF_API_BUILD_IMAGE=$1
CF_REST_API_IMAGE=$2
CF_GRAPHQL_API_IMAGE=$3

# Copy releases archive locally and cleanup
BUILD_CONTAINER=$(docker run -d ${CF_API_BUILD_IMAGE})
docker cp ${BUILD_CONTAINER}:/opt/app/rest-api_release.tar ./rest-api_release.tar
docker cp ${BUILD_CONTAINER}:/opt/app/graphql-api_release.tar ./graphql-api_release.tar
docker stop ${BUILD_CONTAINER} && docker rm ${BUILD_CONTAINER}

# Create released docker images
docker build -t ${CF_REST_API_IMAGE} -f Dockerfile.rest-api.release .
docker build -t ${CF_GRAPHQL_API_IMAGE} -f Dockerfile.graphql-api.release .

# Cleanup
#rm ./rest-api_release.tar ./graphql-api_release.tar