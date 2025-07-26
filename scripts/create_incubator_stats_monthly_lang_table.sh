#!/bin/bash

CNF_PATH="$HOME/replica.my.cnf"

SQL_FILE="$HOME/www/python/src/queries/create_incubator_active_editors_monthly.sql"

DATABASE="s56696__incubator_stats_daily_p"
HOST="tools.db.svc.wikimedia.cloud"

mariadb --defaults-file="$CNF_PATH" -h "$HOST" "$DATABASE" < "$SQL_FILE" && \
echo "table incubator_active_editors_monthly created in $DATABASE."
