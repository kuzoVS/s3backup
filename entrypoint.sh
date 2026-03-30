#!/bin/sh

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
    
    # Запускаем crond и держим контейнер живым через tail
    crond -l 2
    echo "Cron is running. Waiting..."
    tail -f /var/log/backup.log
else
    echo "No SCHEDULE set, exiting after initial backup."
fi
