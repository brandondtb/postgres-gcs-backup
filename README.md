# postgres-gcs-backup

A bash script that creates a postgres database backup with `pg_dump` and uploads it to Google Cloud Storage. Adapted from [`diogopms/postgres-gcs-backup`](https://github.com/diogopms/postgres-gcs-backup).

### Docker image

Docker image is available on Docker Hub here: ['brandondtb/postgres-gcs-backup](https://hub.docker.com/repository/docker/brandondtb/postgres-gcs-backup).

### Configuration

Configuration of the script is done with envionment variables. These are the available parametesrs:

Environment Variable | Required | Default | Description
---------------------|----------|---------|-------------
`JOB_NAME` | Yes | | The name to use for the backup job. This value appears at the beginning of the filename for the saved backup file.
`GCS_BUCKET` | Yes |  | The bucket you want to upload the backup archive to.
`GCLOUD_SERVICE_ACCOUNT_FILE_PATH` | Yes |  | The location where the Google serviceaccount key file will be mounted. Alternately, the standard variable `GOOGLE_APPLICATION_CREDENTIALS` can be used, but one must be provided.
`POSTGRES_HOST` | Yes |  | The PostgreSQL server host.
`POSTGRES_PORT` | No | `5432` | The PostgreSQL port.
`POSTGRES_DB` | Yes |  | The database to backup.
`POSTGRES_USER` | Yes |  | The PostgreSQL user.
`POSTGRES_PASSWORD` | Yes |  | The PostgreSQL password.
`BACKUP_DIR` | No | `/tmp` | The directory where the temporary backup file will be placed.
`EXCLUDE_TABLE_DATA` | No | | A space delimited list of tables for which to exclude data from the backup. Maps to the `pg_dump` `--exclude-table-ata` flag.
