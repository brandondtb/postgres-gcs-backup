#!/bin/bash

set -o pipefail
set -o errexit
set -o errtrace
set -o nounset

set -x

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

EXCLUDE_TABLE_DATA=${EXCLUDE_TABLE_DATA:-}  # Space delimited list of tables


backup() {
  exclude_table_args=""
  if [[ ! -z $EXCLUDE_TABLE_DATA ]]
  then
    for val in $EXCLUDE_TABLE_DATA; do
      exclude_table_args="${exclude_table_args} --exclude-table-data ${val} "
    done
  fi

  mkdir -p $BACKUP_DIR
  date=$(date +"%Y%m%d%H%M")
  archive_name="$JOB_NAME-backup-$date.gz"

  export PGPASSWORD=$POSTGRES_PASSWORD
  cmd="pg_dump -Fc --host=\"$POSTGRES_HOST\" --port=\"$POSTGRES_PORT\" --username=\"$POSTGRES_USER\" $POSTGRES_DB $exclude_table_args | gzip > $BACKUP_DIR/$archive_name"
  echo "starting to backup database $POSTGRES_DB host=$POSTGRES_HOST port=$POSTGRES_PORT with exclude_table_args=$exclude_table_args"

  eval "$cmd"
}


upload_to_gcs() {
  echo "uploading backup archive to GCS bucket=$GCS_BUCKET"
  cmd_creds_part=""
  if [ ! -z "$GCLOUD_SERVICE_ACCOUNT_FILE_PATH" ]
  then
    cmd_creds_part="-o Credentials:gs_service_key_file=${GCLOUD_SERVICE_ACCOUNT_FILE_PATH}"
  fi
  
  gsutil ${cmd_creds_part} cp $BACKUP_DIR/$archive_name $GCS_BUCKET
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
