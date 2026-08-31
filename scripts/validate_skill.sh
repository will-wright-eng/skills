#!/usr/bin/env bash
# Validate skill directories against the agentskills.io spec.
#
# Claude Code frontmatter extensions (argument-hint, context, ...) are not part
# of the spec, so each skill is validated from a temp copy with those fields
# stripped — every other spec check still applies. Accepts skill dirs or any
# repo-relative file paths under skills/<name>/ (as passed by the prek hook);
# paths whose skill no longer exists are skipped.
set -uo pipefail

SKILLS_REF="skills-ref==0.1.1"

CLAUDE_CODE_FIELDS='agent|argument-hint|arguments|background|context|disable-model-invocation|disallowed-tools|effort|hooks|model|paths|shell|user-invocable|when_to_use'

fail=0
for d in $(printf '%s\n' "$@" | cut -d/ -f1-2 | sort -u); do
  [ -f "$d/SKILL.md" ] || continue
  tmp=$(mktemp -d)
  cp -R "$d" "$tmp/"
  copy="$tmp/$(basename "$d")"
  # frontmatter only: drop stripped keys and their indented continuation lines
  awk -v fields="^(${CLAUDE_CODE_FIELDS}):" '
    NR == 1 && $0 == "---" { fm = 1; print; next }
    fm && $0 == "---"      { fm = 0; print; next }
    fm && $0 ~ fields      { skip = 1; next }
    fm && skip && /^[ \t]/ { next }
    fm                     { skip = 0; print; next }
    { print }
  ' "$d/SKILL.md" > "$copy/SKILL.md"
  out=$(uvx --from "$SKILLS_REF" agentskills validate "$copy" 2>&1) || fail=1
  printf '%s\n' "${out//$copy/$d}"
  rm -rf "$tmp"
done
exit $fail
