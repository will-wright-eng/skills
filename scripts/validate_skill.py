#!/usr/bin/env python3
"""Validate skill directories against the agentskills.io spec.

Claude Code frontmatter extensions (argument-hint, context, ...) are not part
of the spec, so validation runs on a temp copy of each skill with those fields
stripped — every other spec check still applies. Accepts skill dirs or any
repo-relative file paths under skills/<name>/ (as passed by the prek hook);
paths whose skill no longer exists are skipped.
"""

import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

SKILLS_REF = "skills-ref==0.1.1"

CLAUDE_CODE_FIELDS = {
    "agent",
    "argument-hint",
    "arguments",
    "background",
    "context",
    "disable-model-invocation",
    "disallowed-tools",
    "effort",
    "hooks",
    "model",
    "paths",
    "shell",
    "user-invocable",
    "when_to_use",
}

FRONTMATTER = re.compile(r"^---\n(.*?\n)---\n", re.DOTALL)
TOP_LEVEL_KEY = re.compile(r"^([A-Za-z0-9_-]+):")


def strip_claude_code_fields(skill_md: Path) -> None:
    text = skill_md.read_text(encoding="utf-8")
    match = FRONTMATTER.match(text)
    if not match:
        return
    kept = []
    skipping = False
    # a stripped key's indented continuation lines are dropped with it
    for line in match.group(1).splitlines(keepends=True):
        key = TOP_LEVEL_KEY.match(line)
        if key:
            skipping = key.group(1) in CLAUDE_CODE_FIELDS
        if not skipping:
            kept.append(line)
    skill_md.write_text(
        "---\n" + "".join(kept) + "---\n" + text[match.end():], encoding="utf-8"
    )


def validate(skill_dir: Path) -> bool:
    with tempfile.TemporaryDirectory() as tmp:
        copy = Path(tmp) / skill_dir.name
        shutil.copytree(skill_dir, copy)
        strip_claude_code_fields(copy / "SKILL.md")
        result = subprocess.run(
            ["uvx", "--from", SKILLS_REF, "agentskills", "validate", str(copy)],
            capture_output=True,
            text=True,
        )
        # report against the real path, not the temp copy
        sys.stdout.write(
            (result.stdout + result.stderr).replace(str(copy), str(skill_dir))
        )
        return result.returncode == 0


def main() -> int:
    skill_dirs = set()
    for arg in sys.argv[1:]:
        parts = Path(arg).parts
        if len(parts) >= 2 and parts[0] == "skills":
            skill_dirs.add(Path(parts[0], parts[1]))
    fail = 0
    for skill_dir in sorted(skill_dirs):
        if not (skill_dir / "SKILL.md").is_file():
            continue
        if not validate(skill_dir):
            fail = 1
    return fail


if __name__ == "__main__":
    raise SystemExit(main())
