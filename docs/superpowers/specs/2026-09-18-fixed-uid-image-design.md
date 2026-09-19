# Fixed-UID Image Design

## Goal

Publish an additional Paperless-ngx image variant that runs by default as the
upstream application's fixed non-root identity, UID/GID `1000:1000`. Preserve
the existing image behavior and document arbitrary Kubernetes numeric-user
support as future work rather than implementing it in this change.

## Image Contract

- Existing `latest` and immutable image tags remain unchanged.
- New `nonroot` tag points to the fixed-UID variant.
- New immutable non-root tags use the existing version/timestamp/commit format
  with a `-nonroot` suffix.
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

README documents the `nonroot` tag, immutable tag form, fixed UID/GID contract,
Kubernetes security context example, and persistent-volume permission
requirement. It explicitly states that arbitrary numeric UIDs are not yet
guaranteed.

## Future Work Issue

Create a GitHub issue for arbitrary numeric UID/GID support. The issue covers
runtime behavior under UIDs other than `1000`, volume ownership and `fsGroup`
behavior across storage backends, hardened security settings, and acceptance
criteria. No arbitrary-UID implementation is included in this change.

## Compatibility

No existing tag changes default user behavior. Consumers needing current root
startup behavior continue using existing tags; Kubernetes consumers requiring a
fixed non-root identity use `nonroot` or its immutable equivalent.
