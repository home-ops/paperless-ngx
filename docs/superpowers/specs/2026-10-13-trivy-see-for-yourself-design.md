# Trivy "See for Yourself" README Design

## Goal

Make the image vulnerability comparison independently reproducible from the
README, including scans of upstream, rebuilt root-compatible, and rebuilt
non-root images.

## Scope and Behavior

- Add a `See for Yourself` subsection to the Trivy report documentation in
  `README.md`.
- Read exact current image references from `reports/trivy.json` with `jq` so
  commands do not rely on stale immutable tags or mutable `latest` tags.
- Run `trivy image` for upstream, rebuilt, and non-root references with the
  vulnerability scanner and severity set used by CI.
- Pipe scan output through `grep` to display each image's final `Total:` summary
  lines, keeping detailed findings out of the terminal output.
- State that Trivy and `jq` must be installed and run commands from repository
  root. Note that scans use the local Trivy database snapshot and may differ from
  committed report counts as the database changes.

## Validation

- Check the documented JSON paths against `reports/trivy.json`.
- Check command quoting and shell syntax for extracting and scanning all three
  references.
- Run `git diff --check` and review the README section in context.
