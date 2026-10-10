# Paperless-ngx Image

This repository builds a maintained wrapper around the official
[Paperless-ngx project](https://github.com/paperless-ngx/paperless-ngx). It does
not fork or redistribute Paperless-ngx source code. The Dockerfile starts from
the official upstream image below and publishes a separately maintained image:

- Source image and pinned version: see [`Dockerfile`](Dockerfile) ([upstream project](https://github.com/paperless-ngx/paperless-ngx))
- Published image: `ghcr.io/home-ops/paperless-ngx`

It provides two practical benefits: rebuilt images include available Debian
package security updates without waiting for a Paperless-ngx release, and a
separate image variant runs with fixed UID/GID `1000:1000` for deployments that
require a non-root container. Each successful build also publishes a transparent
Trivy comparison against its pinned upstream image.

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
- GitHub Actions publishes traceable image tags and records Trivy before/after
  vulnerability results.
- Vulnerability reports are evidence, not a guarantee that the image is secure.

The repository is intentionally separate from deployment configuration so the
build, update history, and published image remain independently reviewable.
Initial publication supports `linux/amd64`; multi-architecture support is
deferred until it can be tested adequately.

## Security Benefits and Limits

Each build starts from a digest-pinned Paperless-ngx image and installs
available Debian package updates. This can reduce operating-system package
staleness between upstream application releases. Renovate proposes upstream
version and digest changes as pull requests, and CI validates builds before
publishing. Immutable version-date-revision tags identify each published
result.

GitHub Actions scans the pinned upstream image and both rebuilt variants with
the same Trivy configuration. The committed
[`reports/trivy.md`](reports/trivy.md) and
[`reports/trivy.json`](reports/trivy.json) show latest severity totals and
changes; downloadable workflow artifacts contain detailed findings. This makes
the comparison inspectable, not a claim that rebuilt images always have fewer
vulnerabilities. The wrapper does not change Paperless-ngx application code, and
scan results are evidence from a particular database snapshot, not a security
guarantee.

The separate `ghcr.io/home-ops/paperless-ngx-nonroot` image runs with fixed
UID/GID `1000:1000`, providing a non-root deployment option while preserving the
upstream-compatible image in `ghcr.io/home-ops/paperless-ngx`. Storage must be
configured to allow that UID/GID to access application data; see
[Non-root Kubernetes Deployments](#non-root-kubernetes-deployments).

Builds are not bit-for-bit reproducible: `apt-get upgrade -y` resolves to
whatever Debian packages are current at build time. Tags identify exactly which
source revision and upstream digest produced an image, not a rebuildable result.

## Build Behavior

The Dockerfile pins the source image by digest. During the image build it runs
`apt-get update` followed by `apt-get upgrade -y`, then removes the APT package
lists. This applies available Debian package upgrades from the source image at
build time; it does not change the upstream application version.

## Build Frequency and Delays

Scheduled builds run four times daily at `00:00`, `06:00`, `12:00`, and `18:00 UTC`.
The image is not rebuilt continuously whenever Debian publishes a package update,
so an operating-system update can wait up to roughly 6 hours for the next scheduled
build. Normal
GitHub Actions build, scan, report, and publish processing usually adds several
minutes after the job starts.

Paperless-ngx version or digest updates follow a pull request path: Renovate
opens a pull request, the pull-request workflow builds and scans the image
without publishing it, and the update is automerged when that validation passes.
The publishing build then starts from the merge to `main`. Manual workflow
dispatch can start an immediate build when needed.

If the build or either scan fails, the existing `latest` tag remains unchanged.
The previous published image remains available while the failure is
investigated; successful later runs publish the next update. Reports are
generated in the workflow, uploaded as run artifacts, and committed directly to
`main` by the workflow. `main` is not a protected branch; the report commit is
restricted to these generated report paths: `reports/trivy.md`,
`reports/trivy.json`, `reports/source-vulnerabilities.md`, and
`reports/source-vulnerabilities.json`. The workflow fails if any other path is
staged.

Initial builds target `linux/amd64` only. Multi-architecture publishing is
deferred until `arm64` builds and runtime behavior have been tested.

## Image Tags

Published tags:

- `ghcr.io/home-ops/paperless-ngx:latest`: newest successful root-compatible
  build. Mutable.
- `ghcr.io/home-ops/paperless-ngx:<version>-<timestamp>-<sha>`: root-compatible
  build reference with format
  `version-YYYYMMDDTHHMMSSZ-<12-character-git-sha>`.
- `ghcr.io/home-ops/paperless-ngx-nonroot:latest`: newest successful fixed-UID
  non-root build. Mutable.
- `ghcr.io/home-ops/paperless-ngx-nonroot:<version>-<timestamp>-<sha>`:
  fixed-UID non-root build reference with the same immutable tag format.

Root-compatible tags remain in `ghcr.io/home-ops/paperless-ngx` and keep their
existing behavior. Non-root tags are published only in
`ghcr.io/home-ops/paperless-ngx-nonroot`; use its full immutable reference for
non-root deployments. Existing same-package `:nonroot` tags are not deleted
automatically.

Before first non-root publish, ensure the dedicated
`ghcr.io/home-ops/paperless-ngx-nonroot` package is linked to this repository
and accessible to its `GITHUB_TOKEN` with `packages:write` permission.

Example:

```text
3.1.3-20260915T043012Z-0123456789ab
```

Timestamp uses UTC (`Z`). The 12-character SHA prefix identifies source revision.
Use full tag plus image digest for the strongest guarantee that you pull
identical content.
Timestamped tags are intended to be immutable; this depends on registry-side tag
protection. The workflow's existence check alone is not atomic. `latest` always
moves to newest successful build.

## Which Tag Should I Pull?

Choose tag based on need:

| Use case | Recommended reference | Reason |
| --- | --- | --- |
| Quick local testing | `ghcr.io/home-ops/paperless-ngx:latest` | Follows newest successful build. |
| Non-production root tracking | `ghcr.io/home-ops/paperless-ngx:latest` | Convenient, but changes over time. |
| Non-production non-root tracking | `ghcr.io/home-ops/paperless-ngx-nonroot:latest` | Convenient, but changes over time. |
| Deployment pinning | Full `version-YYYYMMDDTHHMMSSZ-sha` tag | Identifies exact upstream version, build time, and source revision. |
| Strongest pull determinism | Immutable tag plus image digest | Digest prevents tag movement from changing pulled content. |
| Rollback | Previously recorded immutable tag or digest | Restores known image without rebuilding. |
| Comparing builds | Two immutable tags | Makes Before/After image comparisons repeatable. |

For example:

```sh
# Convenience pull: moves when newer builds succeed.
podman pull ghcr.io/home-ops/paperless-ngx:latest
```

For deterministic pulls, copy current `After` image reference from
[`reports/trivy.md`](reports/trivy.md), or use its digest. Do not copy an old
example tag: immutable tags identify specific historical builds and may no
longer be the current report value.

Production deployments should use a full immutable tag or digest, not
`latest`. The shorter upstream-version and date aliases are not published yet;
they should only be added once their mutable or immutable behavior is defined
and documented.

## Non-root Kubernetes Deployments

Use `ghcr.io/home-ops/paperless-ngx-nonroot:latest` for tracking the newest
non-root build, or a full immutable tag from that package for deployments.
Configure Kubernetes with the fixed UID and GID contract used by this image:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
```

Persistent volumes must allow UID/GID `1000:1000` to read and write required
application data. Existing volume ownership may need to be changed to
`1000:1000` before starting a non-root deployment. `fsGroup` behavior varies by
storage backend; some backends, including root-squash/NFS-like storage, require
ownership to be pre-provisioned or configured through backend-specific
settings, and may not apply `fsGroup` changes. The image supports this fixed
UID/GID contract; arbitrary numeric UIDs or GIDs are unsupported and not
guaranteed to work. See [issue #5](https://github.com/home-ops/paperless-ngx/issues/5)
for tracking of broader arbitrary-UID support.

## Updates and Security

The Mend Renovate App proposes dependency and base-image updates as pull
requests.

Upstream `ghcr.io/paperless-ngx/paperless-ngx` version and digest updates are
automerged once the pull-request workflow builds and scans the image
successfully. These updates publish a new image without human review, which is a
deliberate tradeoff: it keeps the published image close to upstream, and every
merge and published tag stays auditable in the commit and workflow history. All
other updates, including GitHub Actions and workflow changes, remain manual.

Vulnerability findings are informational and never fail a build. Build, push,
and Trivy *execution* failures fail CI.

## Trivy Before/After Reports

Every successful build scans both image references with the same Trivy
configuration:

- **Before:** pinned upstream Paperless-ngx image.
- **After:** newly built `ghcr.io/home-ops/paperless-ngx` image.

See [`reports/trivy.md`](reports/trivy.md) and its
[`reports/trivy.json`](reports/trivy.json) companion for latest merged severity
totals, changes, image references, and scan run link. These two files are
committed summary files regenerated by GHA after every scan; full findings
remain in workflow artifacts for each run.

Source dependency reports are available in
[`reports/source-vulnerabilities.md`](reports/source-vulnerabilities.md) and
[`reports/source-vulnerabilities.json`](reports/source-vulnerabilities.json).
These scans check source dependency manifests for vulnerabilities only; they do
not scan images. The upstream report scans the Paperless-ngx tag pinned in the
Dockerfile, while the repository report scans this repository at the workflow
commit. Each build refreshes scans against the current vulnerability database.
Counts are descriptive and not vulnerabilities fixed: the reports cover
different dependency inventories. Detailed findings are available in workflow
artifacts.

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
nonroot.json        # raw non-root findings
nonroot.md          # detailed non-root findings
comparison.md       # severity counts and image references
trivy-source/wrapper.json  # raw source scan of this repository
trivy-source/upstream.json # raw source scan of pinned upstream
```

The workflow retains report artifacts for 30 days. Vulnerability counts are
evidence from that specific build and database snapshot, not a guarantee that
either image is free of vulnerabilities.

## Contributions

Issues and pull requests are welcome. Keep changes focused and explain the
reason for the change, especially when changing the Dockerfile or workflow.

Before opening a pull request:

- Run `git diff --check`.
- Validate `renovate.json` as JSON.
- Validate `.github/workflows/build.yaml` as YAML.
- Build locally for `linux/amd64` when changing the Dockerfile.
- Do not add credentials, private infrastructure details, or deployment-specific
  configuration.
- Treat `reports/trivy.md` and `reports/trivy.json` as generated files; the
  build workflow overwrites them on every scan, so edit the generator rather
  than the files.

Renovate handles upstream Paperless-ngx version and digest updates through
reviewable pull requests. Multi-architecture support is deferred until arm64
builds and runtime behavior can be tested adequately.

Report security issues privately through GitHub's repository security
reporting instead of opening a public issue with exploitable details.

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
