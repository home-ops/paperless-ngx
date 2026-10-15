# Benefit Positioning and GitHub Releases Design

## Goal

Make the repository's concrete user benefit easy to understand, expose each
successful published image build in GitHub Releases, and capture multi-version
support as future work without claiming it exists today.

## Scope and Behavior

- Reorder the README's opening benefit summary to lead with the fixed UID/GID
  `1000:1000` non-root image for deployments that require non-root containers.
- Describe Debian package refreshes as a secondary benefit, explicitly avoiding
  any promise that vulnerability totals will always improve. Keep the current
  Trivy evidence and limitations visible.
- Create one versioned GitHub Release per successful build, after both immutable image
  variants and mutable tags have published and the Trivy report has been
  committed.
- Bind each release to the existing image tag format
  `<paperless-version>-<UTC-timestamp>-<source-SHA>` as the GitHub release tag so
  each release maps to image refs and source revision without a moving release
  tag. Do not overwrite an existing release or tag. Unique release tags and
  release records provide traceability; strict GitHub immutable-release
  protection remains dependent on repository settings.
- Include root-compatible and non-root image refs and links to the generated
  Trivy comparison in release notes. Do not attach container images as release
  assets; GHCR remains the image registry.
- Ensure GitHub Release creation failures fail the workflow visibly without
  changing already published immutable or `latest` image refs.
- Open an exploratory GitHub issue for multi-version support. Ask to define a
  support window and end-of-life policy, per-version build/scan/runtime test
  requirements, and ongoing maintenance cost before promising specific tracks.
- Do not add support for additional Paperless-ngx versions in this change.

## Out of Scope

- Moving `latest` release tag or maintaining one rolling GitHub Release.
- Creating a release for failed, incomplete, or pull-request-only builds.
- Changing image tags, build cadence, or current upstream version policy.
- Claiming a fixed vulnerability reduction or security guarantee.

## Validation

- Check README claims against current Dockerfile and existing CI/runtime tests.
- Verify release creation runs only after successful image publication and uses
  the exact immutable tag and image references emitted by the build workflow.
- Verify release notes link to current report and identify both image variants.
- Verify release creation does not use overwrite behavior and fails if a release
  with that tag already exists. Do not imply protected immutability unless the
  repository setting is enabled.
- Verify workflow token permissions are limited to what release creation needs.
- Run workflow YAML validation, `git diff --check`, and relevant pull-request
  validation locally where available.
- Verify multi-version issue content requests evaluation and does not announce
  support for versions not currently built and tested.
