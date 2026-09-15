#!/usr/bin/env bash
# Diff each replicated skill against its upstream source (scripts/replicated-skills.json).
# Usage: check_replicated_skills.sh [--report FILE] [--max-diff-lines N] [SKILL...]
# Exit 1 on drift, 2 on error. Manifest "ignore" lists files vendored from sibling skills.
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
manifest="$script_dir/replicated-skills.json"
report=""
max_lines=300
selected=""

while [ $# -gt 0 ]; do
  case "$1" in
    --report)
      report="$2"
      shift 2
      ;;
    --max-diff-lines)
      max_lines="$2"
      shift 2
      ;;
    -h | --help)
      sed -n '2,4p' "$0" | sed 's/^# //'
      exit 0
      ;;
    *)
      selected="$selected$1"$'\n'
      shift
      ;;
  esac
done

for tool in git jq diff; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "error: $tool is required" >&2
    exit 2
  }
done

[ -n "$selected" ] || selected=$(jq -r 'keys_unsorted[]' "$manifest")

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

body=""
drifted=""
clean=""

while IFS= read -r skill; do
  [ -n "$skill" ] || continue
  entry=$(jq -ce --arg s "$skill" '.[$s]' "$manifest") || {
    echo "error: $skill is not in $manifest" >&2
    exit 2
  }
  repo=$(jq -r .repo <<<"$entry")
  ref=$(jq -r '.ref // "main"' <<<"$entry")
  dest="$workdir/$skill"

  git init -q "$dest"
  git -C "$dest" remote add origin "https://github.com/$repo.git"
  git -C "$dest" fetch -q --depth 1 origin "$ref"
  git -C "$dest" checkout -q FETCH_HEAD
  sha=$(git -C "$dest" rev-parse HEAD)
  short=${sha:0:7}

  ignore_args=""
  while IFS= read -r pattern; do
    [ -n "$pattern" ] && ignore_args="$ignore_args -x $pattern"
  done <<<"$(jq -r '.ignore // [] | .[]' <<<"$entry")"

  diff_out=""
  while IFS=$'\t' read -r upstream_path local_path; do
    [ -n "$upstream_path" ] || continue
    local_abs="$repo_root/skills/$skill"
    [ "$local_path" = "." ] || local_abs="$local_abs/$local_path"
    set +e
    # shellcheck disable=SC2086 # ignore_args is a deliberately word-split list of -x flags
    chunk=$(diff -ruN $ignore_args "$dest/$upstream_path" "$local_abs" 2>&1)
    rc=$?
    set -e
    [ "$rc" -le 1 ] || {
      echo "error: diff failed for $skill ($upstream_path): $chunk" >&2
      exit 2
    }
    chunk=$(sed -e "s#$dest/#upstream:#g" -e "s#$repo_root/#local:#g" <<<"$chunk")
    [ -n "$chunk" ] && diff_out="$diff_out$chunk"$'\n'
  done <<<"$(jq -r '.paths | to_entries[] | "\(.key)\t\(.value)"' <<<"$entry")"

  link="https://github.com/$repo/tree/$sha"
  if [ -z "$diff_out" ]; then
    clean="$clean$skill"$'\n'
    echo "ok       $skill  ($repo@$short)"
    body="$body"$'\n'"- ✅ \`$skill\` matches [$repo@$short]($link) (\`$ref\`)"
  else
    drifted="$drifted$skill"$'\n'
    total=$(wc -l <<<"$diff_out" | tr -d ' ')
    echo "DRIFTED  $skill  ($repo@$short, $total diff lines)"
    shown="$diff_out"
    note=""
    if [ "$max_lines" -gt 0 ] && [ "$total" -gt "$max_lines" ]; then
      shown=$(head -n "$max_lines" <<<"$diff_out")
      note=$'\n'"_Truncated to $max_lines of $total lines. Run \`bash scripts/check_replicated_skills.sh $skill\` for the full diff._"
    fi
    body="$body"$'\n'"- ❌ \`$skill\` drifted from [$repo@$short]($link) (\`$ref\`), $total diff lines"
    body="$body"$'\n\n'"<details><summary><code>$skill</code> diff</summary>"$'\n\n```diff\n'"$shown"$'\n```\n'"$note"$'\n\n</details>\n'
    [ -n "$report" ] || printf '%s\n' "$diff_out"
  fi
done <<<"$selected"

n_drifted=$(grep -c . <<<"$drifted" || true)
n_clean=$(grep -c . <<<"$clean" || true)
if [ "$n_drifted" -eq 0 ]; then
  headline="All $n_clean replicated skills match upstream."
else
  headline="$n_drifted of $((n_drifted + n_clean)) replicated skills drifted from upstream. Re-copy from the linked commit to resync (see README → Replicated Skills)."
fi

if [ -n "$report" ]; then
  printf '%s\n%s\n' "$headline" "$body" >"$report"
fi
echo "$headline"
[ "$n_drifted" -eq 0 ]
