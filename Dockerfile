FROM ubuntu:bionic

ARG CLOUD_SDK_VERSION=232.0.0

RUN apt-get update && apt-get install -y apt-transport-https ca-certificates curl git gnupg wget

# Setup postgresql repo
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt bionic-pgdg main" | tee -a /etc/apt/sources.list.d/pgdg.list

# Setup gcloud sdk repo
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

RUN apt-get update && apt-get install -y postgresql-client-11 google-cloud-sdk=${CLOUD_SDK_VERSION}-0
RUN gcloud config set core/disable_usage_reporting true
RUN gcloud config set component_manager/disable_update_check true


ADD . /postgres-gcs-backup

WORKDIR /postgres-gcs-backup

RUN chmod +x /postgres-gcs-backup/backup.sh

ENTRYPOINT ["/postgres-gcs-backup/backup.sh"]
