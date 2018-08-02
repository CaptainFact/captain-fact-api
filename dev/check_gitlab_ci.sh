#!/usr/bin/env bash

cd -- "$(dirname $0)/.."


echo "Converting YAML file to JSON"
echo "============================"

CONTENT=$(
  cat .gitlab-ci.yml \
  | yaml2json \
  | tr -d '\n' \
  | python -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
)

echo $CONTENT

echo ""
echo ""
echo "Checking CI config against Gitlab's API"
echo "======================================="

curl --header "Content-Type: application/json" https://gitlab.com/api/v4/ci/lint --data "{\"content\": $CONTENT}"