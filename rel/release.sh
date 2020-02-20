#!/usr/bin/env bash
# Build all releases for given tags and push them to Docker registry
# ------------------------------------------------------------------

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 environment"
  echo "Example: $0 staging"
  exit 1
fi

if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PASSWORD" ]; then
  echo "[Warning] Docker credentials not provided. You must be logged in to push to registry."
fi

set -e

# ---- Images names ----
CF_API_REST_IMAGE=captainfact/rest-api:$1
CF_API_GRAPHQL_IMAGE=captainfact/graphql-api:$1
CF_API_ATOM_FEED=captainfact/atom-feed:$1
CF_API_JOBS_IMAGE=captainfact/jobs:$1

# ---- Build ----
echo "[RELEASE] Building Apps 🔨"
docker build --build-arg APP=cf_rest_api  -t ${CF_API_REST_IMAGE} .
docker build --build-arg APP=cf_graphql   -t ${CF_API_GRAPHQL_IMAGE} .
docker build --build-arg APP=cf_atom_feed -t ${CF_API_ATOM_FEED} .
docker build --build-arg APP=cf_jobs      -t ${CF_API_JOBS_IMAGE} .

# ---- Push release ----
echo "[RELEASE] Pushing Apps 🚀"
docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD";
docker push $CF_API_REST_IMAGE
docker push $CF_API_GRAPHQL_IMAGE
docker push $CF_API_ATOM_FEED
docker push $CF_API_JOBS_IMAGE
