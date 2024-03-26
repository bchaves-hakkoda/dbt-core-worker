#!/bin/bash
set -eo pipefail

[ "$DEBUG" ] && set -x

dockerImage=$1

echo "Running dbt version test on $dockerImage..."
if ! docker run --rm $dockerImage dbt --version &> /dev/null; then
    echo "Error: DBT not found on image $dockerImage."
    exit 1
else
    echo "Test Passed: DBT version check."
fi
