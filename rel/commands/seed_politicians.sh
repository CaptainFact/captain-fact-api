#!/usr/bin/env bash

if [[ -f "bin/captain_fact" ]]; then
  bin/captain_fact command Elixir.DB.ReleaseTasks seed_politicians_from_github
elif [[ -f "bin/cf_graphql" ]]; then
  bin/cf_graphql command Elixir.DB.ReleaseTasks seed_politicians_from_github
elif [[ -f "bin/cf_atom_feed" ]]; then
  bin/cf_atom_feed command Elixir.DB.ReleaseTasks seed_politicians_from_github
fi
