#!/usr/bin/env bash
# Dev release is done manually, not from CI.
# ------------------------------------------

CF_BUILD_IMAGE=captain-fact-builder:dev-release
CF_REST_API_IMAGE=registry.gitlab.com/captainfact/captain-fact-api/rest:dev
CF_GRAPHQL_API_IMAGE=captainfact/graphql-api:dev
CF_ATOM_FEED_IMAGE=captainfact/atom-feed:dev

function confirm()
{
    echo "$@"
    echo -n "(yes/no)> "
    read -e answer
    for response in y Y yes YES Yes Sure sure SURE OK ok Ok
    do
        if [ "_$answer" == "_$response" ]
        then
            return 0
        fi
    done

    # Any answer other than the list above is considerred a "no" answer
    return 1
}

# ---- Build ----
set -e

cd -- "$(dirname $0)"
docker build -t ${CF_BUILD_IMAGE} --build-arg MIX_ENV=dev -f Dockerfile.build ../../
./build_release.sh ${CF_BUILD_IMAGE} ${CF_REST_API_IMAGE} ${CF_GRAPHQL_API_IMAGE} ${CF_ATOM_FEED_IMAGE}

# ---- Push ----
set +e

confirm "Push $CF_REST_API_IMAGE ?" && docker push ${CF_REST_API_IMAGE}
confirm "Push $CF_GRAPHQL_API_IMAGE ?" && docker push ${CF_GRAPHQL_API_IMAGE}
confirm "Push $CF_ATOM_FEED_IMAGE ?" && docker push ${CF_ATOM_FEED_IMAGE}