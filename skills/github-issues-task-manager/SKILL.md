---
name: github-issues-task-manager
description: Runs the repo GitHub Issues task-manager loop — duplicate search, native issue type/Priority/Effort, sub-issues, blocked-by/blocking, tests or manual instructions, comments, checklists, branch from main, commit/push per issue, assigned PRs, and mandatory post-creation PR self-review with inline findings, finding sub-issues, per-finding fixes, and resolved review threads. Use when planning, implementing, filing or updating GitHub issues, checking duplicates, committing finished work, installing this skill into a repo, opening a pull request, or self-reviewing and remediating a PR.
---

# GitHub Issues task manager

Canonical policy: [AGENTS.md](AGENTS.md) in this skill folder, or the target repo’s root `AGENTS.md` after install. Claude/Gemini/Copilot paths and `.claude/skills/.../SKILL.md` are symlinks — edit `AGENTS.md` and this skill only.

Always send `-H "GraphQL-Features: issue_fields"` on GraphQL that reads or writes issue fields.

Resolve the current repo. Do not hardcode owner/name:

```bash
REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
OWNER=$(gh repo view --json owner --jq .owner.login)
NAME=$(gh repo view --json name --jq .name)
```

## Install into a repository

If the user asked to install this skill, follow the package README. Preferred:

```bash
tmpdir="$(mktemp -d)"
gh repo clone oglofus/skills "$tmpdir"
"$tmpdir/scripts/install.sh" .
```

Then commit the installed files. Do not recreate the workflow from memory.

## 1. Search before creating

```bash
gh issue list --state open --limit 50
gh issue list --state closed --limit 20
gh search issues --repo "$REPO" "keywords"
```

- **Duplicate / near-duplicate:** comment that it was requested again; continue on that issue.
- **Similar, small differences:** comment the deltas. New issue only for a distinct deliverable; set **blocked by** / **blocking** when order matters.

## 2. Look up type and field option IDs

```bash
gh api graphql -H "GraphQL-Features: issue_fields" -f query="
query {
  repository(owner:\"$OWNER\", name:\"$NAME\") {
    id
    issueTypes(first:20) { nodes { id name } }
    issueFields(first:50) {
      nodes {
        __typename
        ... on IssueFieldSingleSelect {
          id name
          options { id name }
        }
      }
    }
  }
}"
```

Typical GitHub defaults: types **Bug / Feature / Task**, **Priority** Urgent|High|Medium|Low, **Effort** High|Medium|Low. Use whatever this owner actually has.

`gh issue create` cannot set type or fields. Use GraphQL `createIssue`.

## 3. Create a detailed issue

```bash
# $REPO_ID $TYPE_ID $PRIORITY_FIELD $PRIORITY_OPT $EFFORT_FIELD $EFFORT_OPT
# $ASSIGNEE_ID from: gh api graphql -f query='query { viewer { id } }'
# Area/agent label node ids from: repository { label(name:"area:dx") { id } }

gh api graphql -H "GraphQL-Features: issue_fields" --input payload.json
```

`payload.json` shape:

```json
{
  "query": "mutation($input:CreateIssueInput!) { createIssue(input:$input) { issue { number url id } } }",
  "variables": {
    "input": {
      "repositoryId": "REPO_ID",
      "title": "...",
      "body": "## Summary\n\n## Duplicate check\n\n## Scope\n\n### In scope\n\n### Out of scope\n\n## Implementation details\n\n## Testing\n- [ ]\n\n## Acceptance criteria\n- [ ]\n",
      "assigneeIds": ["ASSIGNEE_ID"],
      "issueTypeId": "TYPE_ID",
      "labelIds": ["LABEL_AGENT", "LABEL_AREA"],
      "issueFields": [
        { "fieldId": "PRIORITY_FIELD", "singleSelectOptionId": "PRIORITY_OPT" },
        { "fieldId": "EFFORT_FIELD", "singleSelectOptionId": "EFFORT_OPT" }
      ]
    }
  }
}
```

Required on every new issue: **type**, **Priority**, **Effort** (when those fields exist), assignee, `area:*`, and `agent` when an agent created or is executing it.

Do **not** add labels `type:*`, `difficulty:*`, `priority:*`, or `status:*`.

After-the-fact:

```bash
gh api graphql -H "GraphQL-Features: issue_fields" -f query='
mutation {
  updateIssueIssueType(input: { issueId: "ISSUE_NODE_ID", issueTypeId: "TYPE_ID" }) {
    issue { number }
  }
}'

gh api graphql -H "GraphQL-Features: issue_fields" -f query='
mutation {
  setIssueFieldValue(input: {
    issueId: "ISSUE_NODE_ID"
    issueFields: [
      { fieldId: "PRIORITY_FIELD", singleSelectOptionId: "PRIORITY_OPT" }
    ]
  }) { clientMutationId }
}'
```

## 4. Sub-issues

Pass `parentIssueId` (GraphQL node id) on `createIssue`, or:

```bash
CHILD_REST_ID=$(gh api "repos/${REPO}/issues/${CHILD_NUM}" --jq .id)
gh api -X POST "repos/${REPO}/issues/${PARENT_NUM}/sub_issues" \
  -F sub_issue_id="$CHILD_REST_ID"
```

## 5. Blocked by / blocking

**Blocked by** = this issue waits. **Blocking** = others wait on this (they proceed after it).

```bash
gh api graphql -f query='
mutation {
  addBlockedBy(input: {
    issueId: "ISSUE_NODE"
    blockingIssueId: "BLOCKER_NODE"
  }) { issue { number } blockingIssue { number } }
}'
```

REST equivalent (numeric database ids, not issue numbers):

```bash
M_ID=$(gh api "repos/${REPO}/issues/${M}" --jq .id)
gh api -X POST "repos/${REPO}/issues/${N}/dependencies/blocked_by" \
  -F issue_id="$M_ID"
```

To make this issue **block** #N (N proceeds after this): add blocked-by on #N pointing at this issue.

```bash
gh api graphql -f query="
query {
  repository(owner:\"$OWNER\", name:\"$NAME\") {
    issue(number: N) {
      blockedBy(first:20) { nodes { number title state } }
      blocking(first:20) { nodes { number title state } }
    }
  }
}"
```

## 6. Branch

```bash
git fetch origin
git switch -c "issue-${ROOT_NUM}-short-slug" origin/main
```

Do not include unrelated local files.

## 7. While working

```bash
gh issue view "$N" --comments
gh issue comment "$N" --body "..."
```

Read comments, type, fields, sub-issues, and dependencies before continuing. Update checklist boxes in the issue body. Do not toggle `status:*` labels.

## 8. Finish an issue or sub-issue

Commit (message = why), push the branch, then:

```bash
gh issue comment "$N" --body "## Done\n\nCommit \`SHA\` on \`branch\`. ..."
# mark checklist items [x] via gh issue edit --body-file
gh issue close "$N" --reason completed
```

Finishing includes commit + push. Closing a blocker unblocks issues that were blocked by it.

## 9. Run the issue and PR tests

Before opening or updating the PR, execute every Testing / Test plan item from the issue and the PR body.

- Check off items you ran. Comment with the command and result.
- If you cannot run an item, add **Manual tests** on the PR with numbered steps the user can follow. Leave that checkbox unchecked or mark it `manual`.
- Prefer agent-runnable checks when writing Testing sections (`gh`, git, `pnpm test`, curl). Label human-only checks as such in the issue.

## 10. Open the PR when the root issue implementation is done

```bash
gh pr create \
  --base main \
  --assignee "@me" \
  --label "area:dx,agent" \
  --title "..." \
  --body "$(cat <<EOF
## Summary
- …

Closes #${ROOT_NUM}

## Test plan
- [x] … (agent ran: command + result)
- [ ] … (manual — see below)

## Manual tests
### Title of the unrunnable check
1. …
2. …

## Checklist
- [x] Root GitHub issue is the source of truth and was followed (body + comments + fields)
- [x] Sub-issues finished in this PR are closed, with comments and checklists updated
- [x] Assigned
- [x] Issue/PR tests were run, or Manual tests has step-by-step instructions
EOF
)"
```

Do not merge unless asked.

PR creation is a checkpoint, not completion. Continue through the self-review loop below without waiting for another prompt.

## 11. Self-review the created PR

Resolve the current PR and inspect its complete diff:

```bash
PR_NUM=$(gh pr view --json number --jq .number)
HEAD_SHA=$(gh pr view "$PR_NUM" --json headRefOid --jq .headRefOid)
gh pr view "$PR_NUM" --comments
gh pr diff "$PR_NUM"
gh api --paginate "repos/${REPO}/pulls/${PR_NUM}/files?per_page=100"
```

Review correctness, security, regressions, error handling, tests, accessibility, maintainability, and every root-issue requirement. Treat an item as actionable only when code or documentation must change. Do not file praise, questions, or optional preferences as findings.

Prepare all findings before changing code. Publish one inline review comment per finding in a single review; `line` must be a line in the PR diff and `side` is normally `RIGHT`:

```bash
FINDING_PATH='path/to/file'
FINDING_LINE=42
FINDING_BODY='Problem: ...

Impact: ...

Expected correction: ...'

jq -n \
  --arg commit_id "$HEAD_SHA" \
  --arg path "$FINDING_PATH" \
  --argjson line "$FINDING_LINE" \
  --arg body "$FINDING_BODY" \
  '{
    commit_id: $commit_id,
    event: "COMMENT",
    body: "Self-review found actionable items; each thread will be tracked by a sub-issue.",
    comments: [{path: $path, line: $line, side: "RIGHT", body: $body}]
  }' > /tmp/self-review.json

gh api -X POST "repos/${REPO}/pulls/${PR_NUM}/reviews" \
  --input /tmp/self-review.json
```

For multiple findings, pass a separate `--arg pathN`, `--argjson lineN`, and `--arg bodyN` for each finding and add its object to `comments`. Always let `jq` encode finding text; do not interpolate arbitrary text into handwritten JSON. Confirm `jq -r .commit_id /tmp/self-review.json` equals `$HEAD_SHA` before submitting.

Retrieve the created comments and their URLs. For a finding spanning several files, anchor it to the most relevant changed line and state the full scope. If GitHub cannot truthfully anchor an actionable finding to any changed line, post it in the review body, then follow the same sub-issue workflow and record why it has no inline thread.

```bash
gh api --paginate "repos/${REPO}/pulls/${PR_NUM}/comments?per_page=100" \
  --jq '.[] | {id, node_id, path, line, html_url, body}'
```

If there are no actionable findings, post a PR comment stating what was reviewed and that the pass was clean, comment the same result on the root issue, then perform the final checks in step 14. Never invent findings to populate the loop.

## 12. Create a sub-issue for every finding

Create one sub-issue of the root issue per actionable comment. Use the normal detailed issue format and native fields described above. Each finding issue must include:

- PR and inline comment/thread URLs
- affected path and line
- problem, impact, and expected correction
- scope in/out, implementation details, testing, acceptance criteria, and checklist
- an explicit acceptance item to resolve the linked review thread after verifying the pushed fix

Pass `parentIssueId` during creation or attach it through the sub-issues API in step 4. Assign the current user and add `agent` plus the relevant `area:*` label. Comment on the root issue with the self-review summary and links to every finding sub-issue and PR thread before fixing any finding.

## 13. Fix, push, and resolve findings one at a time

For each finding sub-issue, sequentially:

1. Read its full body/comments and the linked PR thread. Comment that remediation started.
2. Make only that finding's change and run every test in the sub-issue.
3. Commit the focused fix and push immediately. One finding sub-issue gets one commit unless its own implementation genuinely requires multiple commits; never combine separate findings in one commit.
4. Comment on the sub-issue with the commit SHA, pushed branch, commands/results, and PR thread URL. Update its checklist.
5. Re-read the pushed PR diff and verify the finding. Leave the thread and issue open if the correction is incomplete.
6. Resolve the review thread only after verification. Comment on and close the sub-issue after the thread is resolved.
7. Comment on the root issue after each finding closes so progress remains visible.

List self-review threads and map them to their comments:

```bash
gh api graphql -f owner="$OWNER" -f name="$NAME" -F number="$PR_NUM" -f query='
query($owner:String!, $name:String!, $number:Int!) {
  repository(owner:$owner, name:$name) {
    pullRequest(number:$number) {
      reviewThreads(first:100) {
        nodes {
          id isResolved isOutdated
          comments(first:20) { nodes { databaseId url path line body } }
        }
      }
    }
  }
}'
```

Resolve the matching thread, not merely the review comment:

```bash
gh api graphql -f threadId="$THREAD_ID" -f query='
mutation($threadId:ID!) {
  resolveReviewThread(input:{threadId:$threadId}) {
    thread { id isResolved }
  }
}'
```

Typical progress comments:

```bash
gh issue comment "$CHILD_NUM" --body "## Started

Addressing the finding in ${THREAD_URL}. I will push this finding separately and report tests here."

gh issue comment "$CHILD_NUM" --body "## Fixed and verified

- Commit: \`${FIX_SHA}\` on \`${BRANCH}\` (pushed)
- Tests: \`${TEST_COMMAND}\` — passed
- Review thread: ${THREAD_URL} — resolved after diff verification"

gh issue close "$CHILD_NUM" --reason completed
gh issue comment "$ROOT_NUM" --body "Self-review finding #${CHILD_NUM} is fixed, pushed, verified, and its PR thread is resolved."
```

Do not resolve a thread because a commit exists; verify the actual pushed diff and relevant tests first. If a thread becomes outdated, still verify the fix, record the outdated state in the sub-issue, and resolve the thread when GitHub permits it.

## 14. Repeat review and report completion

After all finding sub-issues close, re-run the full issue and PR test plans when cumulative fixes could interact. Then review the entire updated PR again using step 11. Every new actionable finding restarts steps 11–13 with a new inline comment and sub-issue.

Completion requires all of the following:

- no actionable findings remain in the final self-review
- every self-review finding has a linked sub-issue and PR review comment (or documented no-inline exception)
- every finding fix is committed and pushed independently
- every finding sub-issue has progress, test, commit, and completion comments and is closed
- every associated self-review thread is resolved after verification
- root issue and PR checklists are current

Post a final PR comment and root-issue comment listing the final review result, finding sub-issues, commits, test evidence, and remaining manual tests. Do not merge unless asked.
