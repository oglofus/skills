# Oglofus skills

Public agent skills from [Oglofus](https://github.com/oglofus), packaged for the open [skills.sh](https://skills.sh/) ecosystem.

## Available skills

### GitHub Issues task manager

Turns GitHub Issues into the source of truth for agent work: duplicate search, native issue fields, sub-issues and dependencies, progress comments, per-issue commits, test evidence, CI pipeline diagnosis and remediation, pull requests, and a mandatory post-creation self-review/remediation loop.

Install it into the current project:

```bash
npx skills add oglofus/skills@github-issues-task-manager
```

Install it globally for all supported agents:

```bash
npx skills add oglofus/skills@github-issues-task-manager -g -a '*' -y
```

## Community health

- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Contributing guide](CONTRIBUTING.md)
- [Accessibility statement](ACCESSIBILITY.md)
- [Security policy](SECURITY.md)
- [Issue forms](https://github.com/oglofus/skills/issues/new/choose)

List the skills in this repository without installing:

```bash
npx skills add oglofus/skills --list
```

The standard skills.sh installation installs the skill folder and its supporting resources. It does not automatically make the skill's policy the root policy of an existing repository.

## Full repository-policy installation

Use the bundled installer when you want GitHub Issues to become the task manager for a target repository. It installs the canonical `AGENTS.md`, agent entry-point symlinks, Cursor rule and skill, GitHub issue forms, and pull-request template.

From the target repository:

```bash
tmpdir="$(mktemp -d)"
gh repo clone oglofus/skills "$tmpdir"
"$tmpdir/scripts/install.sh" .
```

Or from a local clone of this catalog:

```bash
./scripts/install.sh /path/to/target-repository
```

Installer flags:

- `--force` overwrites an existing `AGENTS.md` and managed templates.
- `--skip-templates` omits GitHub issue and pull-request templates.
- `--skip-labels` omits the suggested `area:*` and `agent` labels.

After installation, review the generated files, commit them on a branch, and open a pull request.

## Repository layout

```text
skills/
└── github-issues-task-manager/
    ├── SKILL.md
    ├── AGENTS.md
    ├── rule.mdc
    └── templates/
scripts/
└── install.sh
```

Each public skill lives under `skills/<name>/SKILL.md` with valid `name` and `description` YAML frontmatter. This is a standard discovery location supported by the skills CLI.

## Contributing

Open a detailed GitHub issue before changing a skill. Keep each skill self-contained, validate its `SKILL.md`, and include runnable verification steps. New skills should use lowercase hyphenated directory and frontmatter names. See [CONTRIBUTING.md](CONTRIBUTING.md) for the complete workflow.

## License

MIT
