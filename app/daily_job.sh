#!/bin/bash

# Enable or disable debug mode. Set DEBUG_MODE=1 to enable.
DEBUG_MODE=${DEBUG_MODE:-0}

debug_print() {
    if [ "$DEBUG_MODE" -eq 1 ]; then
        echo "DEBUG: $1"
    fi
}

# Initialize variables
SITE_NAME=""
DBT_MODE="incremental"  # Default to incremental if not provided
DRY_RUN=false
RAW_DBT_CLONE=false

# Define the options
TEMP=$(getopt -o n:m:i: --long site-name:,dbt-mode:,dry-run,raw-dbt-clone -n 'script.sh' -- "$@")

eval set -- "$TEMP"

# Parse options
while true; do
  case "$1" in
    -n | --site-name ) SITE_NAME="$2"; shift 2 ;;
    -m | --dbt-mode ) DBT_MODE="$2"; shift 2 ;;
    --dry-run ) DRY_RUN=true; shift ;;
    --raw-dbt-clone ) RAW_DBT_CLONE=true; shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done


# Check required arguments
if [ -z "$SITE_NAME" ]; then
    echo "Usage: $0 --site-name SITE_NAME [--dbt-mode DBT_MODE]"
    exit 1
fi

# Validate DBT_MODE is either 'incremental', 'full-refresh' or empty
if [ -n "$DBT_MODE" ] && [ "$DBT_MODE" != "incremental" ] && [ "$DBT_MODE" != "full-refresh" ]; then
    echo "Invalid DBT mode: $DBT_MODE. Allowed modes are 'incremental', 'full-refresh', or leave blank for default ('incremental')."
    exit 1
fi

# Get snowflake credentials
gcloud auth login --cred-file=gcp-creds.json

# Check if authentication was successful
if [ $? -ne 0 ]; then
    echo "Error: Authentication failed."
    exit 1
fi

# Fetch snowflake credentials
export SNOWFLAKE_USER=$(gcloud secrets versions access latest --secret=SNOWFLAKE_USER --project=terraform-poc-417803)
export SNOWFLAKE_PASSWORD=$(gcloud secrets versions access latest --secret=SNOWFLAKE_PASSWORD --project=terraform-poc-417803)

# Check if fetching secrets was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch secrets."
    exit 1
fi

GIT_REPO_URL="https://gxo-data-engineering:${GITHUB_TOKEN}@github.com/gxo-data-engineering/site-${SITE_NAME}.git"


debug_print "Cloning the Git repository: $GIT_REPO_URL"
git clone $GIT_REPO_URL ./project
if [ $? -ne 0 ]; then
    echo "Failed to clone the repository."
    exit 1
fi

cd ./project

debug_print "Checking out branch: $DBT_ENV_BRANCH"
git checkout $DBT_ENV_BRANCH
if [ $? -ne 0 ]; then
    echo "Failed to checkout branch $DBT_ENV_BRANCH."
    exit 1
fi

debug_print "Executing dbt deps command."
dbt deps --profiles-dir . --project-dir .
if [ $? -ne 0 ]; then
    echo "dbt deps command failed."
    exit 1
fi


if [ "$DRY_RUN" == true ]; then
    debug_print "Dry run mode enabled. Skipping dbt run command."
else
    debug_print "Executing dbt run command."
    # Append the --full-refresh option if DBT_MODE is "full-refresh", else run as incremental (default behavior or empty string)
    if [ "$DBT_MODE" == "full-refresh" ]; then
        dbt run --profiles-dir . --project-dir . --full-refresh
    else
        dbt run --profiles-dir . --project-dir .
    fi
    

    if [ $? -ne 0 ]; then
        echo "dbt run command failed."
        exit 1
    else
        echo "dbt run command succeeded."
    fi
fi
