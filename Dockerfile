FROM ghcr.io/paperless-ngx/paperless-ngx:3.5.1@sha256:8508853b8a0f8394074260957d0be186c8c64f346973b24a7583de4580f306b9 AS rebuilt

LABEL org.opencontainers.image.source="https://github.com/home-ops/paperless-ngx" \
      org.opencontainers.image.description="Paperless-ngx rebuilt with current Debian package updates; supports arbitrary non-zero numeric UID/GID when writable paths are prepared" \
      io.home-ops.paperless-ngx.uid-gid-support="arbitrary-nonzero-numeric"

RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

FROM rebuilt AS nonroot
USER 1000:1000

FROM rebuilt
