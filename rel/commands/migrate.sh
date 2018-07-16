#!/usr/bin/env bash

if [[ -f "bin/captain_fact" ]]; then
  bin/captain_fact command Elixir.DB.ReleaseTasks migrate
elif [[ -f "bin/cf_graphql" ]]; then
  bin/cf_graphql command Elixir.DB.ReleaseTasks migrate
elif [[ -f "bin/cf_atom_feed" ]]; then
  bin/cf_atom_feed command Elixir.DB.ReleaseTasks migrate
fi
