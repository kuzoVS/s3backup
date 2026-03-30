#!/bin/sh

# Если уже запущен — не стартовать снова
if [ -f /tmp/backup.lock ]; then
    echo "Already running, exiting..."
    exit 0
fi
touch /tmp/backup.lock

mkdir -p ~/.aws

cat > ~/.aws/credentials <<EOF
[default]
aws_access_key_id=${S3_ACCESS_KEY_ID}
aws_secret_access_key=${S3_SECRET_ACCESS_KEY}
EOF

cat > ~/.aws/config <<EOF
[default]
region=${S3_REGION}
EOF

echo "Running initial backup on startup..."
/backup.sh

if [ -n "${SCHEDULE}" ]; then
    echo "Setting up cron: ${SCHEDULE}"
    env >> /etc/environment
    echo "${SCHEDULE} . /etc/environment; /backup.sh >> /var/log/backup.log 2>&1" | crontab -

    crond -l 2
    echo "Cron is running. Waiting..."
    touch /var/log/backup.log
    tail -f /var/log/backup.log
else
    echo "No SCHEDULE set, exiting after initial backup."
fi
