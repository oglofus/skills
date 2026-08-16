## Summary

<!-- What changed and why. Link the root issue. -->

Closes #

## Test plan

<!-- Run each item. Check off what the agent ran and note the command/result. -->

- [ ] `jq empty skills.sh.json` — result:
- [ ] `bash -n scripts/install.sh` — result:
- [ ] `npx --yes skills add . --list` — result:
- [ ] `git diff --check` — result:

## Manual tests

<!-- If a test could not be run, add numbered steps someone else can follow. Omit when everything was run. -->

## Accessibility

<!-- Complete when applicable; mark N/A with a reason for docs/CLI-only changes. -->

- [ ] Keyboard-only operation and visible focus checked
- [ ] Labels, instructions, and errors are understandable and announced where applicable
- [ ] Color is not the only way meaning is conveyed
- [ ] Reduced motion, screen reader, zoom/reflow, and contrast checks completed where applicable
- [ ] N/A — reason:

## Security and documentation

- [ ] No secrets or sensitive data included
- [ ] Documentation and user-facing examples are updated where needed
- [ ] Security implications were considered; sensitive reports use SECURITY.md

## Checklist

- [ ] Root GitHub issue is the source of truth and was followed (body + comments + type/fields/dependencies)
- [ ] Sub-issues finished in this PR are closed, with comments and checklists updated
- [ ] Assigned
- [ ] Issue/PR tests were run, or Manual tests has step-by-step instructions
