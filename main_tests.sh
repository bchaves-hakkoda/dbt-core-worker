#!/bin/bash
set -eo pipefail

[ "$DEBUG" ] && set -x

# Navigate to the directory containing test scripts
cd "$(dirname "$0")/tests"

# Docker image to be tested
dockerImage=$1

if [ -z "$dockerImage" ]; then
    echo "Error: No Docker image specified."
    exit 1
fi

# test
# Run each test script
./test_dbt_version.sh "$dockerImage"
ret_script1=$?
./test_git_version.sh "$dockerImage"
ret_script2=$?
./test_gcp_version.sh "$dockerImage"
ret_script3=$?

if [ $ret_script1 -eq 0 ] && [ $ret_script2 -eq 0 ] && [ $ret_script3 -eq 0 ]; then
  echo "All tests passed successfully."
  exit 0  # success
else
  echo "At least one of the test scripts failed"
  exit 1  # error
fi
