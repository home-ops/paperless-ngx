# Benefit Positioning and GitHub Releases Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make non-root support the README's primary benefit, publish immutable GitHub Releases for successful image builds, and track multi-version support as future work.

**Architecture:** Keep existing image tags and CI flow. Reposition concise README claims, then add a release step after image publication, mutable tag update, and report generation. Each release uses the existing immutable image tag and points to the source commit; notes link image refs and committed scan report. Create an exploratory issue separately without promising extra supported versions.

**Tech Stack:** Markdown, GitHub Actions YAML, GitHub CLI (`gh`), GitHub Releases and Issues.

---

### Task 1: Make README benefits explicit and evidence-based

**Files:**

- Modify: `README.md:3-66`

- [ ] **Step 1: Reorder the introduction around the differentiator**

Replace the current benefit paragraph below the published-image bullets with:

```markdown
The primary benefit is a non-root Paperless-ngx image for deployments that
require fixed UID/GID `1000:1000`. The image is tested in CI for its runtime
identity, writable application paths, and HTTP readiness; see
[Non-root Kubernetes Deployments](#non-root-kubernetes-deployments) for storage
requirements and configuration.

The root-compatible image also refreshes available Debian packages between
Paperless-ngx releases. This may reduce OS-package staleness, but does not
guarantee lower vulnerability counts. See the [Trivy comparison](reports/trivy.md)
for measured results.
```

Retain the wrapper-not-fork and application-version-preservation facts.

- [ ] **Step 2: Verify claims against implementation and reports**

Check `Dockerfile` for `USER 1000:1000`, `.github/workflows/pull-request.yaml`
for identity, writable paths, and HTTP health checks, and `reports/trivy.md` for
the current before/after figures.

Run: `git diff --check`

Expected: no whitespace errors and README makes non-root the lead benefit without
claiming a guaranteed vulnerability reduction.

### Task 2: Publish immutable GitHub Releases after successful builds

**Files:**

- Modify: `.github/workflows/build.yaml` in report generation and final publication steps

- [ ] **Step 1: Prepare release notes from this build's report**

After `Generate vulnerability comparison` and before the existing report commit,
copy `reports/trivy.md` to `$RUNNER_TEMP/release-notes.md`. The generated report
already captures this run's upstream/rebuilt/non-root refs, severity comparison,
date, and workflow-artifact link. Append a link to the committed report for the
latest comparison. Using a copied report preserves this build's scan snapshot in
historical release notes after `reports/trivy.md` changes.

- [ ] **Step 2: Add a release step using existing immutable metadata**

Add a final publication step after `Commit Trivy report to main`, gated on normal
job success. Use the existing `IMMUTABLE_REF` and `GITHUB_SHA`; derive
`release_tag="${IMMUTABLE_REF##*:}"`. Create a release for that unique tag
targeting `GITHUB_SHA`, never a moving `latest` tag. Run `gh release create`
with `--target "$GITHUB_SHA"`, `--title "Paperless-ngx $release_tag"`, and
`--notes-file "$RUNNER_TEMP/release-notes.md"`; set `GH_TOKEN: ${{ github.token }}`
for the step. Do not upload image assets. The release notes contain this build's
root-compatible and non-root image refs from the generated report.

- [ ] **Step 3: Preserve immutability and failure semantics**

Use `gh release create` without overwrite/clobber behavior. A unique tag plus no
update command prevents this workflow from replacing an existing release; do not
claim GitHub's separate immutable-release protection unless repository settings
enable it. Ensure a release/tag collision or API failure fails the workflow
visibly. Keep release creation after both immutable images, mutable aliases, and
the current report have been published. Keep `contents: write`, already required
for the report commit and sufficient for release creation.

- [ ] **Step 4: Validate workflow structure and release inputs**

Run the repository's workflow YAML validation command if available, then inspect
the step ordering and confirm the release tag and refs derive from the same
immutable values used by the image push steps.

Run: `git diff --check`

Expected: valid workflow YAML; no release step runs for failed builds or
pull-request workflow runs; no command can replace an existing release. Release
tags use the existing immutable image tag format and are never moved by this
workflow.

### Task 3: Track multi-version support as exploratory work

**Files:**

- Create: GitHub issue in `home-ops/paperless-ngx`

- [ ] **Step 1: Create issue defining the evaluation**

First check for an existing matching issue:

Run: `gh issue list --search "Evaluate support for multiple Paperless-ngx versions" --state all`

Expected: no existing issue; if one exists, do not create a duplicate and report
its URL instead.

Create the issue with this command and body:

```bash
gh issue create \
  --title "Evaluate support for multiple Paperless-ngx versions" \
  --body-file - <<'ISSUE'
## Goal

Evaluate whether this repository should maintain rebuilt images for more than
the current Paperless-ngx release. Do not add version tracks until support and
maintenance policy is agreed.

## Questions to resolve

- Which upstream release window should be supported?
- What end-of-life policy removes an image track?
- Can each track receive scheduled OS package updates while preserving its
  Paperless-ngx application version?
- What per-track build, Trivy scan, startup, and non-root runtime tests are
  required?
- What CI duration, registry storage, and maintainer workload does each added
  track introduce?
- How should tags, reports, and GitHub Releases identify each track?

## Acceptance criteria

- Proposed support window and end-of-life policy documented.
- CI and maintenance cost estimated for each proposed track.
- Decision recorded before additional versions are published.
ISSUE
```

Expected: issue created in this repository; it requests evaluation and does not
announce support for versions not currently built and tested. If an existing
issue was found, link it instead.

### Task 4: Final verification

- [ ] **Step 1: Review all changes against the approved design**

Check README benefit claims, release ordering/target/tag/notes, and issue scope.

- [ ] **Step 2: Run available local checks**

Run: `git diff --check`

Run `actionlint .github/workflows/build.yaml` if installed. Otherwise run:
`ruby -e 'require "yaml"; YAML.load_file(".github/workflows/build.yaml", aliases: true)'`.
Confirm pull-request workflow still validates README and both image variants.

Expected: all available checks pass; report any unavailable hosted-workflow or
GitHub API verification explicitly.
