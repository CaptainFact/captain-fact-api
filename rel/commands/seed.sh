#!/usr/bin/env bash

if [[ -f "bin/captain_fact" ]]; then
  bin/captain_fact command Elixir.DB.ReleaseTasks seed
elif [[ -f "bin/captain_fact_graphql" ]]; then
  bin/captain_fact_graphql command Elixir.DB.ReleaseTasks seed
elif [[ -f "bin/captain_fact_atom_feed" ]]; then
  bin/captain_fact_atom_feed command Elixir.DB.ReleaseTasks seed
fi
