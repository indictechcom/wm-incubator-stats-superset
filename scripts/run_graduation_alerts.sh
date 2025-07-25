#!/bin/bash

# Graduation Alert System Runner
# This script runs the graduation alert system to check for projects ready for graduation

source ~/www/python/venv/bin/activate
cd ~/www/python/src/scripts

echo "Starting Wikimedia Incubator Graduation Alert System..."
echo "Date: $(date)"
echo "----------------------------------------"

python3 fetch_project_user_stats.py

echo "----------------------------------------"
echo "Graduation Alert System completed at $(date)" 