#!/usr/bin/env bash
# validate-skills.sh — verify every SKILL.md against the OpenCode Agent Skills
# contract (https://opencode.ai/docs/skills) and confirm cross-references
# between skills and shared helpers resolve.
#
# Exits 0 on clean, non-zero on any validation failure.
#
# Checks (per OpenCode spec):
#   - Filename is exactly "SKILL.md" (caps) — enforced even on
#     case-insensitive filesystems
#   - Frontmatter `name`: kebab-case (^[a-z0-9]+(-[a-z0-9]+)*$),
#     1–64 chars, matches directory
#   - Frontmatter `description`: 1–1024 chars
#   - Frontmatter `compatibility`: "opencode" (warning only, optional)
#   - Cross-references: every (skills/<name>/SKILL.md) and (shared/<name>.md)
#     link in any markdown file resolves to an existing file
#   - Bare `shared/<name>.md` prose references also resolve

set -euo pipefail

# Resolve repo root (script lives in scripts/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

errors=0
warnings=0

err()  { printf 'ERROR: %s\n' "$*" >&2; errors=$((errors + 1)); }
warn() { printf 'WARN:  %s\n' "$*" >&2; warnings=$((warnings + 1)); }
info() { printf '→ %s\n' "$*"; }

# --- Frontmatter validation -------------------------------------------------

skills=()
while IFS= read -r d; do
  skills+=("$d")
done < <(find skills -mindepth 1 -maxdepth 1 -type d | sort)

info "Validating ${#skills[@]} skills..."

for dir in "${skills[@]}"; do
  name="${dir##*/}"
  skill_file="$dir/SKILL.md"

  if [[ ! -f "$skill_file" ]]; then
    err "$dir: missing SKILL.md"
    continue
  fi

  # Enforce exact filename case — matters on case-insensitive filesystems
  # (macOS default) where `skill.md` would pass `-f SKILL.md` but fail on
  # Linux CI. Use `find -iname` to catch any case variant and compare.
  while IFS= read -r wrong; do
    base="${wrong##*/}"
    if [[ "$base" != "SKILL.md" ]]; then
      err "$dir: filename must be exactly 'SKILL.md' — found '$base'"
    fi
  done < <(find "$dir" -maxdepth 1 -type f -iname 'skill.md' 2>/dev/null)

  # Extract the first frontmatter block (lines between the first two --- lines)
  fm=$(awk 'BEGIN{inside=0} /^---$/{inside++; next} inside==1{print}' "$skill_file")

  if [[ -z "$fm" ]]; then
    err "$skill_file: missing or empty frontmatter"
    continue
  fi

  fm_name=$(printf '%s\n' "$fm" | awk -F': *' '/^name:/{print $2; exit}')
  fm_desc=$(printf '%s\n' "$fm" | awk '/^description:/{sub(/^description: */, ""); print; exit}')
  fm_compat=$(printf '%s\n' "$fm" | awk -F': *' '/^compatibility:/{print $2; exit}')

  # name
  if [[ -z "$fm_name" ]]; then
    err "$skill_file: missing 'name' in frontmatter"
  elif [[ "$fm_name" != "$name" ]]; then
    err "$skill_file: frontmatter name '$fm_name' does not match directory '$name'"
  elif ! [[ "$fm_name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    err "$skill_file: name '$fm_name' does not match ^[a-z0-9]+(-[a-z0-9]+)*\$"
  elif (( ${#fm_name} < 1 || ${#fm_name} > 64 )); then
    err "$skill_file: name '$fm_name' is ${#fm_name} chars (OpenCode spec: 1-64)"
  fi

  # description
  if [[ -z "$fm_desc" ]]; then
    err "$skill_file: missing 'description' in frontmatter"
  elif (( ${#fm_desc} > 1024 )); then
    err "$skill_file: description is ${#fm_desc} chars (max 1024)"
  fi

  # compatibility (warning only — optional per OpenCode spec)
  if [[ "$fm_compat" != "opencode" ]]; then
    warn "$skill_file: compatibility is '${fm_compat:-<missing>}' (convention is 'opencode')"
  fi
done

# --- Cross-reference validation --------------------------------------------

info "Checking cross-references..."

# 1. (skills/<name>/SKILL.md) markdown link targets
while IFS=: read -r file rest; do
  # Pull every (skills/<name>/SKILL.md) path out of the line
  while read -r target; do
    [[ -z "$target" ]] && continue
    if [[ ! -f "$target" ]]; then
      err "$file: dead link to '$target'"
    fi
  done < <(printf '%s\n' "$rest" | grep -oE 'skills/[a-z0-9-]+/SKILL\.md' || true)
done < <(grep -rn -E '\(skills/[a-z0-9-]+/SKILL\.md\)' --include='*.md' . || true)

# 2. (shared/<name>.md) markdown link targets
while IFS=: read -r file rest; do
  while read -r target; do
    [[ -z "$target" ]] && continue
    if [[ ! -f "$target" ]]; then
      err "$file: dead link to '$target'"
    fi
  done < <(printf '%s\n' "$rest" | grep -oE 'shared/[a-z0-9-]+\.md' || true)
done < <(grep -rn -E '\(shared/[a-z0-9-]+\.md\)' --include='*.md' . || true)

# 3. Bare shared/<name>.md prose references (caught even without parens)
while IFS=: read -r file rest; do
  while read -r target; do
    [[ -z "$target" ]] && continue
    if [[ ! -f "$target" ]]; then
      err "$file: dead prose reference to '$target'"
    fi
  done < <(printf '%s\n' "$rest" | grep -oE 'shared/[a-z0-9/-]+\.md' || true)
done < <(grep -rn -E 'shared/[a-z0-9/-]+\.md' --include='*.md' . || true)

# --- Report ----------------------------------------------------------------

echo
if (( errors > 0 )); then
  printf 'FAILED: %d error(s), %d warning(s)\n' "$errors" "$warnings" >&2
  exit 1
fi

if (( warnings > 0 )); then
  printf 'OK with warnings: %d skills valid, %d warning(s)\n' "${#skills[@]}" "$warnings"
  exit 0
fi

printf 'OK: %d skills valid, all cross-references resolve\n' "${#skills[@]}"
