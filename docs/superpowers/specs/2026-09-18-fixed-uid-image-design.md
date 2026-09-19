# Fixed-UID Image Design

## Goal

Publish an additional Paperless-ngx image variant that runs by default as the
upstream application's fixed non-root identity, UID/GID `1000:1000`. Preserve
the existing image behavior and document arbitrary Kubernetes numeric-user
support as future work rather than implementing it in this change.

## Image Contract

- Existing `latest` and immutable image tags remain unchanged.
- Root-compatible image references remain under
  `ghcr.io/home-ops/paperless-ngx`.
- Fixed-UID image references use dedicated package
  `ghcr.io/home-ops/paperless-ngx-nonroot`.
- `ghcr.io/home-ops/paperless-ngx-nonroot:latest` points to newest fixed-UID
  variant.
- Immutable non-root tags use existing
  `version-YYYYMMDDTHHMMSSZ-<40-character-git-sha>` format without suffix, for
  example `ghcr.io/home-ops/paperless-ngx-nonroot:3.1.3-20260915T043012Z-0123456789abcdef0123456789abcdef01234567`.
- Existing same-package `:nonroot` tags are not deleted automatically.
- The non-root variant sets Docker `USER 1000:1000`.
- Existing `/init` entrypoint, application configuration, and volume paths stay
  unchanged.
- Persistent volumes used by the non-root variant must permit UID/GID `1000`.

## CI and Verification

CI builds and scans both variants. Non-root validation checks the effective
identity and starts the image with Kubernetes-equivalent non-root settings:

- `runAsNonRoot: true`
- `runAsUser: 1000`
- `runAsGroup: 1000`
- `fsGroup: 1000`

Validation must confirm container startup, HTTP health, and write access to
Paperless data, media, consume, and export paths. Existing vulnerability report
generation remains intact, with separate references for each variant.

## Documentation

README documents both package names, exact mutable and immutable tag forms,
fixed UID/GID contract, Kubernetes security context example, and persistent-
volume permission requirement. It explicitly states that arbitrary numeric UIDs
are not yet guaranteed.

## Future Work Issue

Create a GitHub issue for arbitrary numeric UID/GID support. The issue covers
runtime behavior under UIDs other than `1000`, volume ownership and `fsGroup`
behavior across storage backends, hardened security settings, and acceptance
criteria. No arbitrary-UID implementation is included in this change.

## Compatibility

No existing root-package tag changes default user behavior. Consumers needing
current root startup behavior continue using
`ghcr.io/home-ops/paperless-ngx:<tag>`; Kubernetes consumers requiring a fixed
non-root identity use `ghcr.io/home-ops/paperless-ngx-nonroot:<tag>`.
