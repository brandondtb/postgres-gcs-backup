#!/bin/bash

set -o pipefail
set -o errexit
set -o errtrace
set -o nounset
# set -o xtrace

JOB_NAME=${JOB_NAME:-default-job}
BACKUP_DIR=${BACKUP_DIR:-/tmp}
GCS_BUCKET=${GCS_BUCKET:-}
POSTGRES_HOST=${POSTGRES_HOST:-localhost}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_DB=${POSTGRES_DB:-}
POSTGRES_USER=${POSTGRES_USER:-}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-}

backup() {
  mkdir -p $BACKUP_DIR
  date=$(date "+%Y-%m-%dT%H:%M:%SZ")
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
  cmd="pg_dump -Fc --host=\"$POSTGRES_HOST\" --port=\"$POSTGRES_PORT\" $cmd_auth_part $cmd_db_part | gzip > $BACKUP_DIR/$archive_name"
  echo "starting to backup PostGRES host=$POSTGRES_HOST port=$POSTGRES_PORT"

  eval "$cmd"
}

upload_to_gcs() {
  echo "uploading backup archive to GCS bucket=$GCS_BUCKET"
  gsutil cp $BACKUP_DIR/$archive_name $GCS_BUCKET
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
