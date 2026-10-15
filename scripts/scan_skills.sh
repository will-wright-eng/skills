#!/usr/bin/env bash
# Static security scan of skills with cisco-ai-skill-scanner (no LLM; policy in scripts/skill-scanner-policy.yaml).
# Usage: scan_skills.sh [--report FILE] [--] [SKILL...]
# Scans every skill when none are named. Exit 1 on HIGH/CRITICAL findings, 2 on error.
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
policy="$script_dir/skill-scanner-policy.yaml"
version="${SKILL_SCANNER_VERSION:-2.2.2}"
report=""
selected=""

while [ $# -gt 0 ]; do
  case "$1" in
    --report)
      report="$2"
      shift 2
      ;;
    -h | --help)
      sed -n '2,4p' "$0" | sed 's/^# //'
      exit 0
      ;;
    --)
      shift
      for skill in "$@"; do
        selected="$selected$skill"$'\n'
      done
      break
      ;;
    *)
      selected="$selected$1"$'\n'
      shift
      ;;
  esac
done

for tool in uvx jq; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "error: $tool is required" >&2
    exit 2
  }
done

if [ -z "$selected" ]; then
  for dir in "$repo_root"/skills/*/; do
    selected="$selected$(basename "$dir")"$'\n'
  done
fi

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
mkdir "$workdir/scans"

while IFS= read -r skill; do
  [ -n "$skill" ] || continue
  [ -f "$repo_root/skills/$skill/SKILL.md" ] || {
    echo "error: skills/$skill/SKILL.md not found" >&2
    exit 2
  }
  uvx --quiet --from "cisco-ai-skill-scanner==$version" skill-scanner scan "$repo_root/skills/$skill" \
    --use-behavioral --use-trigger --policy "$policy" \
    --format json --output-json "$workdir/scans/$skill.json" >/dev/null || {
    echo "error: skill-scanner failed on $skill" >&2
    exit 2
  }
done <<<"$selected"

results="$workdir/results.json"
jq -s 'map(.skill = (.skill_path | split("/") | last))' "$workdir"/scans/*.json >"$results"

scanned=$(jq length "$results")
blocking=$(jq '[.[].findings[] | select(.severity == "HIGH" or .severity == "CRITICAL")] | length' "$results")

skills_md=$(jq -r '
  .[] | (.findings | length) as $n
  | if $n == 0 then "- ✅ `\(.skill)`: no findings"
    else "- \(if .max_severity == "HIGH" or .max_severity == "CRITICAL" then "❌" else "⚠️" end) `\(.skill)`: \($n) finding\(if $n > 1 then "s" else "" end), max \(.max_severity)"
    end
' "$results")

findings_md=$(jq -r '
  def rank: {"CRITICAL": 4, "HIGH": 3, "MEDIUM": 2, "LOW": 1, "INFO": 0}[.] // -1;
  def cell: tostring | gsub("\\|"; "\\|") | gsub("\n"; " ");
  [.[] | .skill as $skill | .findings[] | . + {skill: $skill}]
  | sort_by(-(.severity | rank), .skill)
  | .[]
  | "| `\(.skill)` | \(.severity) | `\(.rule_id)` | `\(.file_path // "?")\(if .line_number then ":\(.line_number)" else "" end)` | \(.title | cell) |"
' "$results")

if [ "$blocking" -eq 0 ]; then
  headline="✅ No HIGH or CRITICAL findings in $scanned scanned skill(s)."
else
  headline="❌ $blocking HIGH/CRITICAL finding(s) in $scanned scanned skill(s)."
fi

body="$skills_md"
if [ -n "$findings_md" ]; then
  body="$body"$'\n\n'"| Skill | Severity | Rule | Location | Finding |"$'\n'"| --- | --- | --- | --- | --- |"$'\n'"$findings_md"
fi
footer="_Static rules and dataflow only ([cisco-ai-skill-scanner](https://github.com/cisco-ai-defense/skill-scanner) $version, no LLM judge): semantic prompt injection goes undetected, so a clean result is not a guarantee. Reproduce with \`bash scripts/scan_skills.sh <skill>\`._"

if [ -n "$report" ]; then
  printf '%s\n\n%s\n\n%s\n' "$headline" "$body" "$footer" >"$report"
else
  printf '%s\n\n%s\n' "$headline" "$body"
fi
[ "$blocking" -eq 0 ]
