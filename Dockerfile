FROM postgres:17-alpine

RUN apk add --no-cache \
    python3 \
    py3-pip \
    dcron \
    && pip3 install awscli --break-system-packages \
    && rm -rf /var/cache/apk/*

COPY backup.sh /backup.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /backup.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
