#!/bin/bash
set -eo pipefail

[ "$DEBUG" ] && set -x

dockerImage=$1

echo "Running git version test on $dockerImage..."
if ! docker run --rm $dockerImage git --version &> /dev/null; then
   echo "Error: GIT not found on image $dockerImage."
    exit 1
else
   echo "Test Passed: GIT version check."
fi
