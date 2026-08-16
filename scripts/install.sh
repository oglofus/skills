#!/usr/bin/env bash
# Install the GitHub Issues task manager into a target git repository.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: install.sh [options] [target-repo]

Copies AGENTS.md, the Cursor rule and skill, issue/PR templates, and
agent entry-file symlinks into the target repository.

Options:
  --force            Overwrite existing AGENTS.md and our template files
  --skip-templates   Do not copy issue/PR templates
  --skip-labels      Do not create suggested area:* / agent labels
  -h, --help         Show this help

Target defaults to the current directory.
EOF
}

FORCE=0
SKIP_TEMPLATES=0
SKIP_LABELS=0
TARGET="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --skip-templates) SKIP_TEMPLATES=1; shift ;;
    --skip-labels) SKIP_LABELS=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) TARGET="$1"; shift ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/../skills/github-issues-task-manager" && pwd)"
TARGET="$(cd "$TARGET" && pwd)"

if [[ ! -d "$TARGET/.git" ]]; then
  echo "error: $TARGET is not a git repository" >&2
  exit 1
fi

copy_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" && "$FORCE" -ne 1 ]]; then
    echo "skip (exists): ${dest#"$TARGET"/}  (use --force to overwrite)"
    return 0
  fi
  cp "$src" "$dest"
  echo "wrote ${dest#"$TARGET"/}"
}

ensure_symlink() {
  local dest="$1" rel_target="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" ]]; then
    ln -sfn "$rel_target" "$dest"
    echo "link ${dest#"$TARGET"/} -> $rel_target"
    return 0
  fi
  if [[ -e "$dest" && "$FORCE" -ne 1 ]]; then
    echo "skip (exists, not a symlink): ${dest#"$TARGET"/}  (use --force to replace)"
    return 0
  fi
  rm -f "$dest"
  ln -s "$rel_target" "$dest"
  echo "link ${dest#"$TARGET"/} -> $rel_target"
}

echo "Installing github-issues-task-manager into $TARGET"

copy_file "$SKILL_DIR/AGENTS.md" "$TARGET/AGENTS.md"
copy_file "$SKILL_DIR/rule.mdc" "$TARGET/.cursor/rules/github-issues-task-manager.mdc"
copy_file "$SKILL_DIR/SKILL.md" "$TARGET/.cursor/skills/github-issues-task-manager/SKILL.md"

ensure_symlink "$TARGET/CLAUDE.md" "AGENTS.md"
ensure_symlink "$TARGET/GEMINI.md" "AGENTS.md"
ensure_symlink "$TARGET/.github/copilot-instructions.md" "../AGENTS.md"
ensure_symlink "$TARGET/.claude/skills/github-issues-task-manager/SKILL.md" \
  "../../../.cursor/skills/github-issues-task-manager/SKILL.md"

if [[ "$SKIP_TEMPLATES" -eq 0 ]]; then
  copy_file "$SKILL_DIR/templates/ISSUE_TEMPLATE/config.yml" "$TARGET/.github/ISSUE_TEMPLATE/config.yml"
  copy_file "$SKILL_DIR/templates/ISSUE_TEMPLATE/bug.yml" "$TARGET/.github/ISSUE_TEMPLATE/bug.yml"
  copy_file "$SKILL_DIR/templates/ISSUE_TEMPLATE/feature.yml" "$TARGET/.github/ISSUE_TEMPLATE/feature.yml"
  copy_file "$SKILL_DIR/templates/ISSUE_TEMPLATE/task.yml" "$TARGET/.github/ISSUE_TEMPLATE/task.yml"
  copy_file "$SKILL_DIR/templates/pull_request_template.md" "$TARGET/.github/pull_request_template.md"
fi

if [[ "$SKIP_LABELS" -eq 0 ]] && command -v gh >/dev/null; then
  if gh -R "$TARGET" repo view >/dev/null 2>&1 || (cd "$TARGET" && gh repo view >/dev/null 2>&1); then
    create_label() {
      local name="$1" color="$2" desc="$3"
      (cd "$TARGET" && gh label create "$name" --color "$color" --description "$desc" 2>/dev/null) \
        || (cd "$TARGET" && gh label edit "$name" --color "$color" --description "$desc" >/dev/null)
    }
    echo "Ensuring suggested labels on the GitHub repo"
    create_label "agent" "5319e7" "Created or executed by an agent"
    create_label "area:api" "5319e7" "API routes and handlers"
    create_label "area:ui" "e99695" "Pages, components, and styles"
    create_label "area:db" "1d76db" "Database, migrations, seeds, repositories"
    create_label "area:i18n" "bfd4f2" "Locales and translations"
    create_label "area:infra" "006b75" "Deploy, CI, hosting, workers"
    create_label "area:dx" "c2e0c6" "Agent workflow, tooling, repo process"
  else
    echo "skip labels: no GitHub remote detected (use gh from the target repo)"
  fi
fi

echo "Done. Commit AGENTS.md, .cursor/, .claude/, CLAUDE.md, GEMINI.md, and .github/ in the target repo."
