#!/bin/bash

find scripts/python -name "*.py" -type f -exec chmod +x {} \; -print
find scripts/shell -name "*.sh" -type f -exec chmod +x {} \; -print
