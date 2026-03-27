#!/bin/sh
set -e

echo "$(date): Starting backup..."

FILENAME="backup_$(date +%Y%m%d_%H%M%S).sql.gz"
TMPFILE="/tmp/${FILENAME}"

export PGPASSWORD="${POSTGRES_PASSWORD}"

echo "Dumping database ${POSTGRES_DB}..."
pg_dump \
    -h "${POSTGRES_HOST}" \
    -p "${POSTGRES_PORT:-5432}" \
    -U "${POSTGRES_USER}" \
    -d "${POSTGRES_DB}" \
    | gzip > "${TMPFILE}"

echo "Uploading to S3..."
aws s3 cp "${TMPFILE}" \
    "s3://${S3_BUCKET}/${S3_PREFIX}/${FILENAME}" \
    --endpoint-url "${S3_ENDPOINT}" \
    --region "${S3_REGION}"

rm -f "${TMPFILE}"
echo "$(date): Backup done — ${FILENAME}"
