#!/usr/bin/env bash
#
# Tests runner.
#
# You can test a specific subset by running ./dev/test.sh test/your_test_subpath
#
# Examples :
#   ./dev/test.sh test/db_schema
#   ./dev/test.sh test/captain_fact_jobs
#   ./dev/test.sh test/captain_fact_jobs/votes_test.exs
#
# ------------------------------------------------------------------------------

cd -- "$(dirname $0)"
./run_command.sh mix test.watch $@
