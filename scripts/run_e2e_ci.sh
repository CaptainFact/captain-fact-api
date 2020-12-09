#!/usr/bin/env bash

# Start API
iex -S mix run &

# Start Frontend
cd captain-fact-frontend
npm run dev &

# Waiting for API to be ready
timeout 1m bash -c "until curl localhost:4000; do sleep 1; done"

# Waiting for Frontend to be ready
timeout 1m bash -c "until curl localhost:3333 > /dev/null; do sleep 1; done"

# Run tests
npm run cypress
RETURN_CODE=$?

# Shutdown everything
kill $(jobs -p) || true

exit $RETURN_CODE