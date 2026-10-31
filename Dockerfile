FROM ghcr.io/paperless-ngx/paperless-ngx:3.4.1@sha256:1a08d8dfc2b51a08de09652dd86ad4d0c611c362382f944533ad38b73125fbc4 AS rebuilt

LABEL org.opencontainers.image.source="https://github.com/home-ops/paperless-ngx" \
      org.opencontainers.image.description="Paperless-ngx upstream image rebuilt with current Debian package updates"

RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

FROM rebuilt AS nonroot
USER 1000:1000

FROM rebuilt
