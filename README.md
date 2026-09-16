# Paperless-ngx Image

Container image wrapper for Paperless-ngx. The Dockerfile starts from the
upstream image below and publishes a separately maintained image:

- Source: `ghcr.io/paperless-ngx/paperless-ngx:3.1.3`
- Published image: `ghcr.io/home-ops/paperless-ngx`

## Why This Repository Exists

Paperless-ngx publishes the upstream application image, but its underlying
Debian packages can become stale between Paperless releases. This repository
rebuilds that image with `apt-get upgrade -y` so available operating-system
package security updates can be published independently of the Paperless
application release cycle.

This is a wrapper, not a Paperless-ngx fork:

- The upstream image remains the application source.
- Its entrypoint, user, runtime configuration, and application version are preserved.
- Renovate tracks upstream image releases and digest changes.
- GitHub Actions publishes reproducible image tags and records Trivy before/after
  vulnerability results.
- Vulnerability reports are evidence, not a guarantee that the image is secure.

The repository is intentionally separate from deployment configuration so the
build, update history, and published image remain independently reviewable.
Initial publication supports `linux/amd64`; multi-architecture support is
deferred until it can be tested adequately.

## Build Behavior

The Dockerfile pins the source image by digest. During the image build it runs
`apt-get update` followed by `apt-get upgrade -y`, then removes the APT package
lists. This applies available Debian package upgrades from the source image at
build time; it does not change the upstream application version.

Initial builds target `linux/amd64` only. Multi-architecture publishing is
deferred until `arm64` builds and runtime behavior have been tested.

## Image Tags

Published tags include:

- `latest` for the current build
- `version-date-fullsha` immutable tags, such as
  `3.1.3-20260915-0123456789abcdef0123456789abcdef01234567`, combining upstream
  version, UTC build date, and full source revision

Use the composite immutable tag or image digest when reproducibility matters.
Treat `latest` as a moving convenience tag.

## Updates and Security

The Mend Renovate App proposes dependency and base-image updates as reviewable
changes. Updates are not automerged.

Vulnerability findings are informational. Build, push, and Trivy scan execution
failures fail CI.

## Local amd64 Commands

Build locally:

```sh
docker build --platform linux/amd64 \
  --tag ghcr.io/home-ops/paperless-ngx:latest .
```

Pull the published image:

```sh
docker pull --platform linux/amd64 ghcr.io/home-ops/paperless-ngx:latest
```
