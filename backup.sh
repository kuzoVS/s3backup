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

FILESIZE=$(du -sh "${TMPFILE}" | cut -f1)
echo "Dump size: ${FILESIZE}"

echo "Uploading ${FILENAME} (${FILESIZE}) to s3://${S3_BUCKET}/${S3_PREFIX}/..."
aws s3 cp "${TMPFILE}" \
    "s3://${S3_BUCKET}/${S3_PREFIX}/${FILENAME}" \
    --endpoint-url "${S3_ENDPOINT}" \
    --region "${S3_REGION}"

rm -f "${TMPFILE}"

echo "Rotating old backups (keeping last ${BACKUP_KEEP_COPIES:-7})..."
KEEP=${BACKUP_KEEP_COPIES:-7}

FILES=$(aws s3 ls "s3://${S3_BUCKET}/${S3_PREFIX}/" \
    --endpoint-url "${S3_ENDPOINT}" \
    --region "${S3_REGION}" \
    | grep "backup_" \
    | sort \
    | awk '{print $4}')

TOTAL=$(echo "$FILES" | grep -c "backup_")
DELETE_COUNT=$((TOTAL - KEEP))

if [ "$DELETE_COUNT" -gt 0 ]; then
    echo "Deleting ${DELETE_COUNT} old backup(s)..."
    TO_DELETE=$(echo "$FILES" | head -n "$DELETE_COUNT")
    for FILE in $TO_DELETE; do
        echo "Deleting: ${FILE}"
        aws s3 rm "s3://${S3_BUCKET}/${S3_PREFIX}/${FILE}" \
            --endpoint-url "${S3_ENDPOINT}" \
            --region "${S3_REGION}"
    done
    REMAINING=$((TOTAL - DELETE_COUNT))
else
    REMAINING=$TOTAL
fi

echo "$(date): Done. Total backups: ${REMAINING}, keeping: ${KEEP}"
