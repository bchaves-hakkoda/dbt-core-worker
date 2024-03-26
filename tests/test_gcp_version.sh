#!/bin/bash
set -eo pipefail

[ "$DEBUG" ] && set -x

dockerImage=$1

echo "Running GCP CLI test on $dockerImage..."
if ! docker run --rm $dockerImage gcloud --version &> /dev/null; then
    echo "Error:  GCP CLI not found on image $dockerImage."
    exit 1
else
    echo "Test Passed:  GCP CLI version check."
fi
