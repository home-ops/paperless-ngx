FROM ghcr.io/paperless-ngx/paperless-ngx:3.3.2@sha256:d232cba37cc0bab0d6c6581ecd320383b7a6f49f33e0fd16adda4d009eb600dd AS rebuilt

LABEL org.opencontainers.image.source="https://github.com/home-ops/paperless-ngx" \
      org.opencontainers.image.description="Paperless-ngx upstream image rebuilt with current Debian package updates"

RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

FROM rebuilt AS nonroot
USER 1000:1000

FROM rebuilt
