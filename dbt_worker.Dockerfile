# Stage 1: Base stage for installing dependencies
FROM python:3.11.3-slim-bullseye as base

# Install system dependencies
RUN apt-get update \
  && apt-get dist-upgrade -y \
  && apt-get install -y --no-install-recommends \
  git \
  vim \
  curl \
  gnupg \
  software-properties-common \
  make \
  build-essential \
  ca-certificates \
  libpq-dev \
  jq \ 
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set up Python environment
RUN python -m pip install --upgrade pip setuptools wheel --no-cache-dir

# Stage 3: Final stage for application setup
FROM base as final

WORKDIR /usr/app

#tokens/access
ARG github_token
ARG google_credentials
ARG env_tag
ARG dbt_schema
#This SF variables will be moved to daily_job.sh when terraform resources are defined
ARG snowflake_wh
ARG snowflake_account
ARG snowflake_db
ARG snowflake_role


ENV GITHUB_TOKEN=$github_token
ENV DEBUG_MODE=1

#Snoflake vars
ENV SNOWFLAKE_WAREHOUSE=$snowflake_wh
ENV SNOWFLAKE_ACCOUNT=$snowflake_account
ENV SNOWFLAKE_DATABASE=$snowflake_db
ENV SNOWFLAKE_ROLE=$snowflake_role

# Hardcoded for now
ENV DBT_ENV_BRANCH=main 


# Copy application code
COPY ./app/ /usr/app/

# Stage 2: Install GCP CLI
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN apt-get update && apt-get install -y google-cloud-sdk

# Copy the service account key into the container
COPY $google_credentials /usr/app/gcp-creds.json

ENV GOOGLE_APPLICATION_CREDENTIALS="/usr/app/gcp-creds.json"


# Install Python dependencies
RUN pip install dbt-core dbt-snowflake
