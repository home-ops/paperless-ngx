# Paperless-ngx Image

This repository builds a maintained wrapper around the official
[Paperless-ngx project](https://github.com/paperless-ngx/paperless-ngx). It does
not fork or redistribute Paperless-ngx source code. The Dockerfile starts from
the official upstream image below and publishes a separately maintained image:

- Source image and pinned version: see [`Dockerfile`](Dockerfile) ([upstream project](https://github.com/paperless-ngx/paperless-ngx))
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
- GitHub Actions publishes traceable image tags and records Trivy before/after
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
digest changes as pull requests that must pass build and scan validation, while
immutable version-date-revision tags make each published result identifiable
and traceable. GitHub Actions scans the upstream image and rebuilt image with
the same Trivy configuration and publishes the Before/After results in
[`reports/trivy.md`](reports/trivy.md). The wrapper
does not change Paperless-ngx application code or runtime behavior. These
controls reduce package staleness and improve evidence and traceability, but do
not guarantee that image has no vulnerabilities or that every runtime risk is
eliminated.

Builds are not bit-for-bit reproducible: `apt-get upgrade -y` resolves to
whatever Debian packages are current at build time. Tags identify exactly which
source revision and upstream digest produced an image, not a rebuildable result.

## Build Behavior

The Dockerfile pins the source image by digest. During the image build it runs
`apt-get update` followed by `apt-get upgrade -y`, then removes the APT package
lists. This applies available Debian package upgrades from the source image at
build time; it does not change the upstream application version.

## Build Frequency and Delays

Scheduled builds run once daily at `04:00 UTC`. The image is not rebuilt
continuously whenever Debian publishes a package update, so an operating-system
update can wait up to roughly 24 hours for the next scheduled build. Normal
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
generated in the workflow, uploaded as run artifacts, and submitted to `main`
through one automatically merged pull request from `automation/trivy-report`.
The protected branch never receives a direct workflow push.

Initial builds target `linux/amd64` only. Multi-architecture publishing is
deferred until `arm64` builds and runtime behavior have been tested.

## Image Tags

Published tags:

- `latest`: newest successful build. Mutable.
- `<version>-<timestamp>-<sha>`: build reference with format
  `version-YYYYMMDDTHHMMSSZ-<40-character-git-sha>`.

Example:

```text
3.1.3-20260915T043012Z-0123456789abcdef0123456789abcdef01234567
```

Timestamp uses UTC (`Z`). Full SHA identifies source revision. Use full tag plus
image digest for the strongest guarantee that you pull identical content.
Timestamped tags are intended to be immutable; this depends on registry-side tag
protection. The workflow's existence check alone is not atomic. `latest` always
moves to newest successful build.

## Which Tag Should I Pull?

Choose tag based on need:

| Use case | Recommended reference | Reason |
| --- | --- | --- |
| Quick local testing | `ghcr.io/home-ops/paperless-ngx:latest` | Follows newest successful build. |
| Non-production tracking | `latest` | Convenient, but changes over time. |
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
totals, changes, image references, and scan run link. GHA regenerates both files
after every scan, updates one report PR, and requests auto-merge. The job
summary contains the comparison table, while full findings remain in the
artifact for each run.

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
- Treat `reports/trivy.md` and `reports/trivy.json` as generated files; update
  them through the automated Trivy report PR rather than editing manually.

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
