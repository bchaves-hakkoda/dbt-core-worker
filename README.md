# DBT CORE WORKER

This project is a Docker image that has installed:

- GCP CLI<br />
- GIT<br />
- DBT<br />

The purpose of the image is to deploy it to Google Cloud Platform's Container Registry (gcr.io) in order to use it in Google Kubernetes Engine (GKE). This enables directing an Airflow instance to run DAGs in a GKE Cluster via the [KubernetesPodOperator](https://airflow.apache.org/docs/apache-airflow-providers-cncf-kubernetes/stable/operators.html).

Flow of execution for [daily_job.sh](./app/daily_job.sh) when called:<br />

- Retrieve Snowflake credentials from GCP Secrets Manager<br />
- Clone client dbt project repository<br />
- Execute `dbt deps` command<br />
- Execute `dbt run` command<br />

## Installation

In order to test this container locally and contribute to it:

Build the image:

```
docker build -f dbt_worker.Dockerfile -t dbtcoreworker:latest --build-arg github_token="$(<github token>)" --build-arg google_credentials="$(<path to the GCP service account credentials>)" .
```

Running the container:

```
docker run -it dbtcoreworker bash
```

After you are in the bash for the container you can try out git commands, dbt commands and GCP CLI commands.

# Testing

To add more tests to the image:

- Add a new file in the tests/ folder with .sh extension and modify the command called and the expectation.

To run the tests run the command:
`./main_tests.sh dbtcoreworker`
