FROM ghcr.io/paperless-ngx/paperless-ngx:3.3.0@sha256:6b94799bc769a063b3340cc5847402e626d4d91d29a295a8e747f8e9bead4207 AS rebuilt

LABEL org.opencontainers.image.source="https://github.com/home-ops/paperless-ngx" \
      org.opencontainers.image.description="Paperless-ngx upstream image rebuilt with current Debian package updates"

RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

FROM rebuilt AS nonroot
USER 1000:1000

FROM rebuilt
