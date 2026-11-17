FROM ghcr.io/paperless-ngx/paperless-ngx:3.5.0@sha256:8c1e2c4e0abb50576c7a09f062ed581e2d955e298a302e1e196a35338639005e AS rebuilt

LABEL org.opencontainers.image.source="https://github.com/home-ops/paperless-ngx" \
      org.opencontainers.image.description="Paperless-ngx rebuilt with current Debian package updates; supports arbitrary non-zero numeric UID/GID when writable paths are prepared" \
      io.home-ops.paperless-ngx.uid-gid-support="arbitrary-nonzero-numeric"

RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

FROM rebuilt AS nonroot
USER 1000:1000

FROM rebuilt
