#!/usr/bin/env bash

set +e

while true; do
  nodetool ping
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 0 ]; then
    echo "Application is up!"
    break
  fi
  sleep 1
done

set -e

echo "Running migrations"
bin/captain_fact command Elixir.DB.ReleaseTasks migrate
echo "Migrated"