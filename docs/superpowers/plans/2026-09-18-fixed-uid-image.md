# Fixed-UID Image Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish an additional Paperless-ngx image variant whose default runtime identity is fixed at UID/GID `1000:1000`, without changing existing image tags.

**Architecture:** Keep existing root-compatible image behavior as default Dockerfile target and add named `nonroot` target with fixed UID/GID `1000:1000`. Pull-request workflow owns non-root runtime validation. Publication workflow keeps root refs under `ghcr.io/home-ops/paperless-ngx`, publishes non-root refs under dedicated package `ghcr.io/home-ops/paperless-ngx-nonroot`, uses same immutable tag format without variant suffix, then updates each package's `latest` tag while retaining existing Trivy report semantics. Document fixed UID/GID Kubernetes usage and persistent-volume requirements.

**Tech Stack:** Dockerfile, Docker Buildx, GitHub Actions, Trivy, shell checks, Kubernetes securityContext documentation.

---

## File Map

- Modify `Dockerfile`: add named `nonroot` build target after existing image definition and set `USER 1000:1000` only in that target.
- Modify `.github/workflows/build.yaml`: define `IMAGE=ghcr.io/home-ops/paperless-ngx` and `NONROOT_IMAGE=ghcr.io/home-ops/paperless-ngx-nonroot`, build and load both image variants locally, scan both package-specific immutable refs, push them, preserve report generation, then update each package's `latest` tag.
- Modify `.github/workflows/pull-request.yaml`: build and validate non-root variant during pull requests.
- Modify `README.md`: document separate root/non-root packages, exact immutable references, Kubernetes security context, and volume permissions.
- Do not manually edit `reports/trivy.md` or `reports/trivy.json`; workflow generation owns them.

### Task 1: Add Non-Root Build Target

**Files:**
- Modify: `Dockerfile`

- [ ] **Step 1: Add named target without changing default target**

Name current final image stage `rebuilt`, then add named target based on it:

```dockerfile
FROM rebuilt AS nonroot
USER 1000:1000
```

Preserve default target behavior, upstream `/init` entrypoint, and volume declarations. Do not alter application files or ownership.

- [ ] **Step 2: Verify Dockerfile metadata locally**

Run:

```sh
docker buildx build --platform linux/amd64 --target nonroot --tag paperless-ngx:nonroot --load .
docker image inspect paperless-ngx:nonroot --format '{{.Config.User}} {{json .Config.Entrypoint}}'
```

Expected: output starts with `1000:1000` and entrypoint is `/init`.

- [ ] **Step 3: Commit focused Dockerfile change**

```sh
git add Dockerfile
git commit -m "feat: add fixed UID image variant"
```

### Task 2: Add Pull-Request Runtime Validation

**Files:**
- Modify: `.github/workflows/pull-request.yaml`

- [ ] **Step 1: Build non-root target in pull-request workflow**

Add a second Buildx build using target `nonroot`, `linux/amd64`, `load: true`, and tag `paperless-ngx:nonroot-pull-request`.

- [ ] **Step 2: Add effective identity check**

Run:

```sh
test "$(docker run --rm --entrypoint id paperless-ngx:nonroot-pull-request -u)" = 1000
test "$(docker run --rm --entrypoint id paperless-ngx:nonroot-pull-request -g)" = 1000
```

- [ ] **Step 3: Add runtime filesystem check**

Run the image with temporary writable mounts for `/usr/src/paperless/data`, `/usr/src/paperless/media`, `/usr/src/paperless/consume`, and `/usr/src/paperless/export`. Confirm UID/GID `1000:1000` can create and remove a file in each mount. Do not require external database or Redis services for this filesystem check.

- [ ] **Step 4: Scan non-root image**

Run Trivy against `paperless-ngx:nonroot-pull-request` with the existing scanner, severity, timeout, parallelism, and informational exit-code settings.

- [ ] **Step 5: Commit workflow validation**

```sh
git add .github/workflows/pull-request.yaml
git commit -m "ci: validate fixed UID image"
```

### Task 3: Publish Both Variants

**Files:**
- Modify: `.github/workflows/build.yaml`

- [ ] **Step 1: Derive separate immutable references**

Retain current immutable reference for existing image. Derive non-root reference from dedicated package without appending a suffix:

```sh
immutable_tag="${upstream_version}-$(date -u +%Y%m%dT%H%M%SZ)-${GITHUB_SHA}"
NONROOT_IMAGE=ghcr.io/home-ops/paperless-ngx-nonroot
NONROOT_IMMUTABLE_REF="${NONROOT_IMAGE}:${immutable_tag}"
```

- [ ] **Step 2: Build and load both local images**

Build existing target and `nonroot` target with `linux/amd64`, `load: true`, and their immutable local tags. Do not push from Buildx; publication happens after scans.

- [ ] **Step 3: Scan local images**

Run Trivy against loaded local tags `${IMMUTABLE_REF}` and `${NONROOT_IMMUTABLE_REF}`. Write generated raw and comparison reports. Trivy findings use informational exit code `0`; command failures still fail workflow.

- [ ] **Step 4: Push immutable tags**

After both local image scans and report generation succeed, push both immutable references:

```sh
docker push "$IMMUTABLE_REF"
docker push "$NONROOT_IMMUTABLE_REF"
```

Registry tag immutability prevents overwrites.

- [ ] **Step 5: Update mutable tags and verify workflow references**

After immutable pushes succeed, update mutable tags:

```sh
docker buildx imagetools create --tag "${IMAGE}:latest" "$IMMUTABLE_REF"
docker buildx imagetools create --tag "${NONROOT_IMAGE}:latest" "$NONROOT_IMMUTABLE_REF"
```

Run shell/YAML validation locally and inspect workflow expressions for quoting, tag collisions, and failure ordering. Ensure failed build, scan, report generation, or immutable push cannot move either mutable tag. Do not repoint `latest` to non-root image.

- [ ] **Step 6: Commit publication changes**

```sh
git add .github/workflows/build.yaml
git commit -m "ci: publish fixed UID image"
```

### Task 4: Document Consumer Contract

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Document tags**

Document `ghcr.io/home-ops/paperless-ngx:latest`, `ghcr.io/home-ops/paperless-ngx-nonroot:latest`, and package-specific immutable references without a `-nonroot` suffix. State that existing root-package tags retain current behavior and old same-package `:nonroot` tags are not deleted automatically.

- [ ] **Step 2: Add Kubernetes security context**

Document:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
```

State that persistent volumes must allow UID/GID `1000`, and that storage backends may require pre-provisioned ownership or backend-specific configuration.

- [ ] **Step 3: Mark arbitrary UID support as unsupported**

Link GitHub issue `#5` and state that arbitrary numeric `runAsUser`/`runAsGroup` support is future work, not guaranteed by `nonroot`.

- [ ] **Step 4: Commit documentation**

```sh
git add README.md
git commit -m "docs: document fixed UID image"
```

### Task 5: Full Verification

**Files:**
- Verify: `Dockerfile`, `.github/workflows/build.yaml`, `.github/workflows/pull-request.yaml`, `README.md`

- [ ] **Step 1: Check formatting and YAML/JSON inputs**

Run:

```sh
git diff --check
python3 -m json.tool renovate.json >/dev/null
```

Validate both workflow files with an available YAML parser or GitHub Actions syntax checker.

- [ ] **Step 2: Build both local images**

Run both amd64 Buildx builds, then inspect image users, entrypoints, and volume declarations.

- [ ] **Step 3: Run non-root filesystem test**

Start non-root image with temporary mounts and verify all four Paperless volume paths are writable as UID/GID `1000:1000`.

- [ ] **Step 4: Run application smoke test**

Start non-root image with required test dependencies or the project-supported SQLite mode. Wait for health endpoint and record any startup permission errors. If full service startup cannot run locally, preserve CI runtime test as required evidence and document local limitation.

- [ ] **Step 5: Review final diff**

Run:

```sh
git status --short
```

Confirm generated reports were not hand-edited and existing image tags remain compatible.

## Self-Review

- Fixed UID contract maps to `Dockerfile` target `nonroot` and README.
- Existing tags remain unchanged by default Dockerfile target and separate tag paths.
- CI validates identity, filesystem writes, scanning, and publication ordering.
- Arbitrary UID/GID work is represented by GitHub issue `#5`, not silently implied.
- Exact paths, commands, tags, and security settings are specified.
