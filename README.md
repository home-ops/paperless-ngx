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

## Why This Repository/Image Is Safer

This image is safer than using an unrebuildable, older copy of the upstream
image because each build starts from a digest-pinned Paperless-ngx image and
installs current Debian package updates. Renovate proposes upstream version and
digest changes for review, while immutable version-date-revision tags make each
published result identifiable and reproducible. GitHub Actions scans the
upstream image and rebuilt image with the same Trivy configuration and publishes
the Before/After results in [`reports/trivy.md`](reports/trivy.md). The wrapper
does not change Paperless-ngx application code or runtime behavior. These
controls reduce package staleness and improve evidence and traceability, but do
not guarantee that image has no vulnerabilities or that every runtime risk is
eliminated.

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

## Trivy Before/After Reports

Every successful build scans both image references with the same Trivy
configuration:

- **Before:** pinned upstream Paperless-ngx image.
- **After:** newly built `ghcr.io/home-ops/paperless-ngx` image.

See the [current visual Before/After report](reports/trivy.md) for latest
severity totals, changes, image references, and scan run link. GHA regenerates
that page after every successful scan and commits only the generated report.

View results in the [Build and scan image workflow][workflow]:

1. Open a completed workflow run.
2. Read the job summary for the severity comparison table.
3. Download the `trivy-reports-<run-id>` artifact for detailed reports.

Artifacts contain:

```text
upstream.json       # raw before scan
upstream.md         # detailed before findings
immutable.json      # raw after scan
immutable.md        # detailed after findings
comparison.md       # severity counts and image references
```

The workflow retains report artifacts for 30 days. Vulnerability counts are
evidence from that specific build and database snapshot, not a guarantee that
either image is free of vulnerabilities.

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

[workflow]: https://github.com/home-ops/paperless-ngx/actions/workflows/build.yaml
