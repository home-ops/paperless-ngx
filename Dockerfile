FROM ghcr.io/paperless-ngx/paperless-ngx:3.4.0@sha256:7c1d98afd200def9e2bad3a377d30829e8d486554b3c818995af5860114ea17f AS rebuilt

LABEL org.opencontainers.image.source="https://github.com/home-ops/paperless-ngx" \
      org.opencontainers.image.description="Paperless-ngx upstream image rebuilt with current Debian package updates"

RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

FROM rebuilt AS nonroot
USER 1000:1000

FROM rebuilt
