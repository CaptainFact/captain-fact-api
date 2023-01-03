#!/usr/bin/env bash

cd "$(dirname "$(realpath "$0")")"/..

# Start API
cd ./api
mix run --no-halt &

# Start Frontend
cd ../frontend
npm run dev &

# Waiting for API to be ready
timeout 1m bash -c "until curl localhost:4000; do sleep 1; done"

# Waiting for Frontend to be ready
timeout 1m bash -c "until curl localhost:3333 > /dev/null; do sleep 1; done"

# Run tests
npm run cypress
