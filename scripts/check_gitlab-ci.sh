#!/usr/bin/env bash

CONTENT=$(cat .gitlab-ci.yml | yaml2json | tr -d '\n' | python -c 'import json,sys; print(json.dumps(sys.stdin.read()))')
curl --header "Content-Type: application/json" https://gitlab.com/api/v4/ci/lint --data "{\"content\": $CONTENT}"
