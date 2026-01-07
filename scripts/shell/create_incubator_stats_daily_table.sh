#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CNF_PATH="$HOME/replica.my.cnf"
SQL_FILE="$REPO_ROOT/queries/create_incubator_stats_daily.sql"

DATABASE="s56696__incubator_stats_daily_p"
HOST="tools.db.svc.wikimedia.cloud"

mariadb --defaults-file="$CNF_PATH" -h "$HOST" "$DATABASE" < "$SQL_FILE" && \
echo "table incubator_stats_daily created in $DATABASE."
