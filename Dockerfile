FROM ghcr.io/paperless-ngx/paperless-ngx:3.3.1@sha256:cb91bfb468e63025a9d10c01b54c33665113668eee61b490db96de19b860b9c4 AS rebuilt

LABEL org.opencontainers.image.source="https://github.com/home-ops/paperless-ngx" \
      org.opencontainers.image.description="Paperless-ngx upstream image rebuilt with current Debian package updates"

RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

FROM rebuilt AS nonroot
USER 1000:1000

FROM rebuilt
