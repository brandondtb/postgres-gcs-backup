#!/bin/bash

set -o pipefail
set -o errexit
set -o errtrace
set -o nounset

JOB_NAME=${JOB_NAME:-}
GCS_BUCKET=${GCS_BUCKET:-}
GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS:-}
GCLOUD_SERVICE_ACCOUNT_FILE_PATH=${GCLOUD_SERVICE_ACCOUNT_FILE_PATH:-$GOOGLE_APPLICATION_CREDENTIALS}
POSTGRES_HOST=${POSTGRES_HOST:-}
POSTGRES_DB=${POSTGRES_DB:-}
POSTGRES_USER=${POSTGRES_USER:-}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-}
POSTGRES_PORT=${POSTGRES_PORT:-5432}

BACKUP_DIR=${BACKUP_DIR:-/tmp}

EXCLUDE_TABLES=${EXCLUDE_TABLES:-}  # Space delimited list of tables


backup() {
  exclude_table_args=""
  if [[ ! -z $EXCLUDE_TABLES ]]
  then
    for val in $EXCLUDE_TABLES; do
      exclude_table_args="${exclude_table_args} -T ${val} "
    done
  fi

  mkdir -p $BACKUP_DIR
  date=$(date +"%Y%m%d%H%M")
  archive_name="$JOB_NAME-backup-$date.gz"
  cmd_auth_part=""
  if [[ ! -z $POSTGRES_USER ]] && [[ ! -z $POSTGRES_PASSWORD ]]
  then
    cmd_auth_part="--username=\"$POSTGRES_USER\" "
  fi

  cmd_db_part=""
  if [[ ! -z $POSTGRES_DB ]]
  then
    cmd_db_part="--db=\"$POSTGRES_DB\""
  fi

  export PGPASSWORD=$POSTGRES_PASSWORD
  cmd="pg_dump -Fc --host=\"$POSTGRES_HOST\" --port=\"$POSTGRES_PORT\" $cmd_auth_part $cmd_db_part $exclude_table_args | gzip > $BACKUP_DIR/$archive_name"
  echo "starting to backup PostGRES host=$POSTGRES_HOST port=$POSTGRES_PORT with exclude_table_args=$exclude_table_args"

  eval "$cmd"
}


upload_to_gcs() {
  echo "uploading backup archive to GCS bucket=$GCS_BUCKET"
  gsutil "-o", "Credentials:gs_service_key_file=$GCLOUD_SERVICE_ACCOUNT_FILE_PATH", cp $BACKUP_DIR/$archive_name $GCS_BUCKET
}


err() {
  err_msg="${JOB_NAME} Something went wrong on line $(caller)"
  echo $err_msg >&2
}


cleanup() {
  rm $BACKUP_DIR/$archive_name
}


trap err ERR


backup

upload_to_gcs

cleanup

echo "backup done!"
