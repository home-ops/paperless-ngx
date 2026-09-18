# Automated Trivy Report PR Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish persistent Before/After Trivy reports through one automatically merged pull request without writing directly to protected `main`.

**Architecture:** Keep report generation and image publication in `.github/workflows/build.yaml`. After scans and `latest` publication, update a dedicated `automation/trivy-report` branch, create or reuse one PR targeting `main`, and request auto-merge. Use only trusted `push` and `schedule` executions for report-branch writes; retain artifacts and job summaries as the detailed evidence channel.

**Tech Stack:** GitHub Actions, GitHub CLI (`gh`), GitHub REST/GraphQL APIs, Bash, YAML, Markdown, JSON.

---

### Task 1: Preserve report files in workflow output

**Files:**
- Modify: `.github/workflows/build.yaml`

- [ ] **Step 1: Add explicit permissions**

Set workflow permissions to:

```yaml
permissions:
  contents: write
  packages: write
  pull-requests: write
```

Keep these permissions at workflow scope. Do not add permissions to the pull-request validation workflow.

- [ ] **Step 2: Verify report generation remains unconditional after scans**

Keep `Generate vulnerability comparison` with `if: ${{ always() }}` and retain generation of:

```text
reports/trivy.md
reports/trivy.json
reports/upstream.md
reports/immutable.md
reports/comparison.md
```

Do not allow report-branch updates unless both `reports/upstream.json` and `reports/immutable.json` exist and the image build/scans completed successfully.

- [ ] **Step 3: Run syntax checks**

Run:

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/build.yaml'))"
git diff --check
```

Expected: both commands exit 0.

### Task 2: Publish `latest` before report automation

**Files:**
- Modify: `.github/workflows/build.yaml`

- [ ] **Step 1: Keep image publication before report PR operations**

Keep `Update latest after successful build and scans` immediately after report
generation and before report branch or pull request API operations. This keeps
image publication independent from report PR failures.

### Task 3: Replace direct main push with report branch update

**Files:**
- Modify: `.github/workflows/build.yaml`

- [ ] **Step 1: Add a trusted report-update step after `Update latest`**

Add a step after `Update latest`:

```yaml
- name: Update Trivy report branch
  if: ${{ success() }}
  id: report-branch
  env:
    GH_TOKEN: ${{ github.token }}
    REPORT_BRANCH: automation/trivy-report
  shell: bash
  run: |
    set -euo pipefail
    git config user.name 'github-actions[bot]'
    git config user.email '41898282+github-actions[bot]@users.noreply.github.com'

    report_dir="$RUNNER_TEMP/trivy-report"
    rm -rf "$report_dir"
    mkdir -p "$report_dir"
    cp reports/trivy.md reports/trivy.json "$report_dir/"

    git reset --hard HEAD
    git fetch origin main
    git fetch origin "$REPORT_BRANCH" || true
    if git show-ref --verify --quiet "refs/remotes/origin/$REPORT_BRANCH"; then
      git checkout -B "$REPORT_BRANCH" "origin/$REPORT_BRANCH"
    else
      git checkout -B "$REPORT_BRANCH" origin/main
    fi

    cp "$report_dir/trivy.md" reports/trivy.md
    cp "$report_dir/trivy.json" reports/trivy.json
    git add reports/trivy.md reports/trivy.json
    if git diff --cached --quiet; then
      echo 'Trivy report unchanged'
      exit 0
    fi

    git commit -m 'docs: update Trivy report'
    git push --force-with-lease origin "HEAD:$REPORT_BRANCH"
    echo "changed=true" >> "$GITHUB_OUTPUT"
```

Set `id: report-branch` on this step. Copy generated report files to a
runner-temporary directory before switching branches, then copy only those two
files into the report branch. The implementation must not accidentally commit
workflow-generated `upstream.md`, `immutable.md`, or `comparison.md`.

- [ ] **Step 2: Make branch handling race-safe**

Before force-pushing, fetch the remote branch and use `--force-with-lease`. If another run updates the branch between fetch and push, fail rather than overwrite unknown content. Do not use plain `--force`.

- [ ] **Step 3: Verify commit scope locally**

Run the equivalent shell logic in a temporary clone or inspect the staged diff. Expected staged paths must be exactly:

```text
reports/trivy.md
reports/trivy.json
```

### Task 4: Create or reuse one report PR and enable auto-merge

**Files:**
- Modify: `.github/workflows/build.yaml`

- [ ] **Step 1: Add PR automation after branch push**

Add a step after the branch update. Set `if: steps.report-branch.outputs.changed == 'true'`.
It must execute:

```bash
existing_pr="$(gh pr list \
  --repo "$GITHUB_REPOSITORY" \
  --head "$REPORT_BRANCH" \
  --base main \
  --state open \
  --json number \
  --jq '.[0].number')"

if [[ -z "$existing_pr" ]]; then
  existing_pr="$(gh pr create \
    --repo "$GITHUB_REPOSITORY" \
    --head "$REPORT_BRANCH" \
    --base main \
    --title 'docs: update Trivy report' \
    --body 'Automated Before/After Trivy report update.' \
    --json number \
    --jq '.number')"
fi

gh pr merge "$existing_pr" \
  --repo "$GITHUB_REPOSITORY" \
  --auto \
  --squash \
  --delete-branch=false
```

Use `GH_TOKEN: ${{ github.token }}`. Do not run this step from `pull_request` events. Treat API failures as workflow failures and leave the branch/PR available for retry.

- [ ] **Step 2: Confirm auto-merge compatibility**

Inspect the active `main` ruleset. If it has no required checks or reviews, auto-merge may merge immediately. If required checks are configured, ensure the report PR receives the required workflow check and that the check name is stable. Do not add a self-triggering `push` loop: the build workflow only runs on `main` pushes, not report-branch pushes.

- [ ] **Step 3: Verify only one PR exists**

Run:

```bash
gh pr list --repo home-ops/paperless-ngx --head automation/trivy-report --base main --state open
```

Expected: zero or one open PR, never multiple report PRs.

### Task 5: Update README report documentation

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Describe stable checked-in reports**

Document that `reports/trivy.md` and `reports/trivy.json` are updated through an automated PR and remain the public compact Before/After evidence.

- [ ] **Step 2: Distinguish artifacts from checked-in reports**

State that workflow artifacts contain detailed per-run Markdown and raw JSON findings, while the checked-in files contain the latest merged compact report.

- [ ] **Step 3: Document auto-merge and protection**

Explain that report updates use `automation/trivy-report`, open or reuse one PR, and auto-merge through the `main` ruleset. Do not claim direct workflow writes to `main`.

### Task 6: Validate end to end

**Files:**
- Verify: `.github/workflows/build.yaml`
- Verify: `README.md`

- [ ] **Step 1: Validate static files**

Run:

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/build.yaml'))"
git diff --check
```

- [ ] **Step 2: Dispatch trusted workflow**

Run:

```bash
gh workflow run build.yaml --repo home-ops/paperless-ngx --ref main
gh run watch "$(gh run list --repo home-ops/paperless-ngx --workflow build.yaml --limit 1 --json databaseId --jq '.[0].databaseId')" --repo home-ops/paperless-ngx --exit-status
```

Expected: image build, scans, report generation, report branch update, artifact upload, and `latest` publication succeed.

- [ ] **Step 3: Inspect report branch and PR**

Run:

```bash
gh api repos/home-ops/paperless-ngx/contents/reports/trivy.md?ref=automation/trivy-report
gh pr list --repo home-ops/paperless-ngx --head automation/trivy-report --base main --state all
```

Expected: report branch contains current generated report, one PR exists or has auto-merged, and no unrelated files changed.

- [ ] **Step 4: Verify final repository state**

Run:

```bash
git status --short
git diff --check
gh api repos/home-ops/paperless-ngx/rulesets/23631600
```

Expected: no accidental generated files or secrets, clean diff after intended commit, and active ruleset remains enabled.
