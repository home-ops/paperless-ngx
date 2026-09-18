# Trivy Report Pull Request Design

## Goal

Keep public, persistent Before/After Trivy evidence in this repository while
respecting protected `main`. Successful trusted builds update one automated pull
request, and GitHub auto-merges that pull request after required validation.

## Scope

The build workflow remains responsible for building and publishing the image,
scanning both pinned upstream and rebuilt image, and generating compact Markdown
and JSON reports. It will no longer push generated report commits directly to
`main`.

## Workflow

After successful report generation, the trusted `push` and `schedule` build
workflow will:

1. Check out a branch named `automation/trivy-report` from the current `main`.
2. Replace `reports/trivy.md` and `reports/trivy.json` with generated output.
3. Commit only those two files when content changed.
4. Push the branch using the workflow token.
5. Create one pull request from that branch to `main`, or reuse the existing
   open pull request.
6. Enable auto-merge on that pull request.

The workflow will not run this automation for fork pull requests. Existing
image publication and artifact upload behavior remains unchanged. If report
content does not change, no commit or pull request update is needed.

## Permissions and Protection

The build workflow will explicitly request only the permissions it needs:

- `contents: write` for the report branch
- `packages: write` for GHCR publication
- `pull-requests: write` for creating and enabling auto-merge

The workflow token does not bypass `main` rules. Report changes therefore enter
`main` through the normal pull request and ruleset path. Auto-merge requires the
ruleset's required checks and review configuration to be satisfied. The report
branch is automation-owned and is recreated or force-updated only as needed for
the current report; `main` remains protected against force pushes and deletion.

## Failure Handling

- Build or scan failures prevent image publication and do not update the report
  branch or pull request. Report PR failures occur after image publication and
  leave the published immutable image and `latest` tag available.
- A report branch push or pull request API failure fails the workflow after image
  build and scans complete; the published immutable image remains available.
- `latest` is updated only after image build and scans succeed, independent of
  report PR creation.
- Existing open report PR is reused to avoid accumulating stale report PRs.
- Report artifacts remain attached to each workflow run for detailed findings.

## Repository Documentation

README will describe the checked-in reports as maintained by an automated PR,
link to the report PR workflow behavior, and retain links to the stable report
files. It will distinguish compact checked-in reports from detailed per-run
artifacts.

## Validation

- Parse workflow YAML.
- Run `git diff --check`.
- Verify generated branch commit contains only the two report files.
- Verify a no-change run does not create a commit.
- Verify workflow API calls create or reuse one report PR and request
  auto-merge.
- Confirm a report PR satisfies the configured `main` ruleset before claiming
  end-to-end success.
