#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$HOME/pyvenv/bin/activate"
python3 "$REPO_ROOT/scripts/python/update_incubator_active_editors_monthly.py"
