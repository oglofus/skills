# Contributing to Oglofus skills

Thank you for helping improve this project. Contributions should be focused, documented, testable, and accessible to the people who read and use them.

## Before you start

1. Search open and recently closed issues for an existing request.
2. Open a detailed GitHub issue before making a change. The issue is the source of truth for scope, acceptance criteria, and tests.
3. For security vulnerabilities, follow [the security policy](SECURITY.md) instead of opening a public issue.
4. For accessibility barriers, use the [accessibility issue form](https://github.com/oglofus/skills/issues/new?template=accessibility.yml).

The repository also contains the [GitHub Issues task-manager policy](skills/github-issues-task-manager/AGENTS.md), which describes the agent workflow, native issue fields, linked branches, CI, and pull requests.

## Local setup

You need Git, Bash, `jq`, Node.js/npm with `npx`, and the GitHub CLI (`gh`) for the repository validation workflow. Authenticate `gh` when you need to inspect or update GitHub issues, branches, or pull requests.

Clone the repository and run the checks from its root:

```bash
git clone https://github.com/oglofus/skills.git
cd skills
```

## Make a change

Create a GitHub-linked branch from the issue, when you have repository access:

```bash
gh issue develop ISSUE_NUMBER \
  --name issue-ISSUE_NUMBER-short-slug \
  --base main \
  --checkout
```

Keep changes focused. Do not include unrelated local files. Update documentation and templates when behavior or contributor expectations change.

## Validation

Run the checks relevant to your change and record the exact commands and results in the issue and pull request:

```bash
jq empty skills.sh.json
bash -n scripts/install.sh
npx --yes skills add . --list
git diff --check
```

For Markdown and issue-form changes, also check heading order, descriptive link text, valid YAML, keyboard-readable checklists, and whether every referenced file exists.

## Accessibility expectations

Accessibility is part of quality and done criteria. For documentation and templates:

- Use logical heading levels, plain language, descriptive links, and real lists.
- Do not communicate meaning only through color, position, or styling.
- Provide text alternatives for meaningful images and diagrams.
- Keep instructions understandable without relying on visual layout.

For UI changes, test keyboard navigation, visible focus, form labels and error messages, color-independent meaning, reduced motion, screen-reader behavior, zoom/reflow, and high-contrast or forced-colors modes where applicable. Include the results in the pull request.

Read the [Accessibility Best Practices for Your Project](https://opensource.guide/accessibility-best-practices-for-your-project/) guide for the rationale and additional techniques.

## Pull requests

Open the pull request against `main` after the issue's implementation and tests are complete. The pull request should:

- Explain what changed and why.
- Include `Closes #ISSUE_NUMBER` or the appropriate GitHub closing reference.
- List runnable test commands and their results.
- Include numbered manual-test instructions for anything that could not be run.
- Identify documentation, security, and accessibility considerations.
- Keep the review focused and respond constructively to feedback.

Do not merge your own pull request unless repository policy and the required review/checks allow it. Maintainers handle final merge decisions.
