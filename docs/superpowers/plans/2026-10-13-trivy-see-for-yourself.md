# Trivy "See for Yourself" README Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add README commands to reproduce Trivy scans for upstream, rebuilt, and non-root images and display concise severity totals.

**Architecture:** Add one subsection under the existing Trivy Before/After Reports section. Resolve exact image refs from generated `reports/trivy.json` with `jq`, run each scan using CI's vulnerability-only severity configuration, and filter terminal output to `Total:` lines with `grep`.

**Tech Stack:** Markdown, Bash, Trivy CLI, jq, grep.

---

### Task 1: Document repeatable image scans

**Files:**

- Modify: `README.md` under `## Trivy Before/After Reports`

- [ ] **Step 1: Add the See for Yourself subsection**

Add this after the existing workflow-artifact instructions and before the
paragraph describing artifact retention:

````markdown
### See for Yourself

Install Trivy and `jq`, then run this from the repository root. It scans the
upstream, rebuilt, and non-root image references recorded in the latest report.
Trivy uses your local vulnerability database, so counts can differ from the
committed report as that database changes.

```sh
set -o pipefail
jq -r '[.upstream.reference, .rebuilt.reference, .nonroot.reference][]' reports/trivy.json |
while IFS= read -r image; do
  printf '\n%s\n' "$image"
  trivy image \
    --scanners vuln \
    --severity CRITICAL,HIGH,MEDIUM,LOW,UNKNOWN \
    --exit-code 0 \
    "$image" | grep '^Total:'
done
```
````

- [ ] **Step 2: Verify report reference extraction**

Run: `jq -r '[.upstream.reference, .rebuilt.reference, .nonroot.reference][]' reports/trivy.json`

Expected: exactly three image references, in upstream, rebuilt, and non-root order.

- [ ] **Step 3: Check documentation diff**

Run: `git diff --check && git diff -- README.md`

Expected: no whitespace errors; subsection contains all three report keys, CI severity configuration, and `grep '^Total:'` filter.
