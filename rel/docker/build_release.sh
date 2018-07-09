#!/usr/bin/env bash

if [ "$#" -ne 5 ]; then
  echo "Usage: $0 build_image rest_api_image graphql_api_image atom_feed_image opengraph_image"
  exit 1
fi

cd -- "$(dirname $0)"

# If any command fails, exit
set -e

# Define some global config
CF_API_BUILD_IMAGE=$1
CF_REST_API_IMAGE=$2
CF_GRAPHQL_API_IMAGE=$3
CF_ATOM_FEED_IMAGE=$4
CF_OPENGRAPH=$5

# Copy releases archive locally and cleanup
BUILD_CONTAINER=$(docker run -d ${CF_API_BUILD_IMAGE})
docker cp ${BUILD_CONTAINER}:/opt/app/rest-api_release.tar ./rest-api_release.tar
docker cp ${BUILD_CONTAINER}:/opt/app/graphql-api_release.tar ./graphql-api_release.tar
docker cp ${BUILD_CONTAINER}:/opt/app/atom-feed_release.tar ./atom-feed_release.tar
docker cp ${BUILD_CONTAINER}:/opt/app/cf_opengraph.tar ./cf_opengraph.tar
docker stop ${BUILD_CONTAINER} && docker rm ${BUILD_CONTAINER}

# Create released docker images
docker build -t ${CF_REST_API_IMAGE} -f Dockerfile.rest-api.release .
docker build -t ${CF_GRAPHQL_API_IMAGE} -f Dockerfile.graphql-api.release .
docker build -t ${CF_ATOM_FEED_IMAGE} -f Dockerfile.atom-feed.release .
docker build -t ${CF_OPENGRAPH} -f Dockerfile.cf_opengraph.release .

# Cleanup
#rm ./rest-api_release.tar ./graphql-api_release.tar
