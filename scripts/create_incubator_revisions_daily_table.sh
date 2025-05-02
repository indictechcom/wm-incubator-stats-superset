#!/bin/bash

CNF_PATH="$HOME/replica.my.cnf"

SQL_FILE="$HOME/www/python/src/queries/create_incubator_revisions_daily.sql"

DATABASE="s56696__incubator_stats_superset"
HOST="tools.db.svc.wikimedia.cloud"

mariadb --defaults-file="$CNF_PATH" -h "$HOST" "$DATABASE" < "$SQL_FILE" && \
echo "table incubator_revisions_daily created in $DATABASE."
