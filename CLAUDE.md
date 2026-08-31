# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A collection of Claude Code skills, packaged as a plugin (`.claude-plugin/plugin.json`, name `will-wright-eng-skills`) and installable via `bunx skills add https://github.com/will-wright-eng/skills`. There is no build or test suite — everything is markdown.

## Commands

This repo uses [prek](https://github.com/j178/prek) (a pre-commit-compatible runner) with the standard `.pre-commit-config.yaml`.

```bash
prek run --all-files   # lint: markdownlint (--fix, non-blocking), codespell, whitespace/EOF fixers, agentskills spec validation
prek install           # one-time hook setup
```

Skill directories are validated against the [agentskills.io spec](https://agentskills.io/specification) via `python3 scripts/validate_skill.py skills/<name>` — run locally by the `agentskills-validate` prek hook (requires `uv`) and in CI by `.github/workflows/validate-skills.yml`. The script strips Claude Code frontmatter extensions (`argument-hint`, `context`, etc. — see `CLAUDE_CODE_FIELDS` in the script) from a temp copy before running `uvx --from skills-ref agentskills validate`, since the spec disallows them; skills using those fields are a deliberate spec deviation and can't be uploaded to claude.ai as-is.

Codespell false positives go in `.codespell-ignore`. Markdownlint disables MD013 (line length), MD033 (inline HTML), MD041 (first-line heading), and MD003/MD020/MD021 — headings ending in `#` (e.g. `## C#`) are misparsed as closed ATX, which the MD020 fixer mangles and MD003 false-flags.

## Structure

- Each skill is a directory under `skills/<name>/` containing a `SKILL.md` with YAML frontmatter (`name`, `description`). The description must include concrete "Use when..." trigger phrases — it is what the agent matches against when deciding to invoke the skill.
- Supporting reference docs live beside `SKILL.md` (e.g. `ADR-FORMAT.md`, `CONTEXT-FORMAT.md`, `program.template.md`) and are read by the skill at runtime.
- `docs/` holds the Autoverify Kit reference material used by the autoresearch skills — it documents behavior for *target* repos, not this one.

## Adding or Changing Skills

- Register every new skill in `.claude-plugin/plugin.json` **and** in the README table under the correct provenance section.
- **Cross-skill file references are an antipattern.** Every skill must be self-contained: never link to files in sibling skill directories — the skills CLI installs skills individually with no dependency resolution, so cross-skill links dangle. Vendor a copy into the skill's own directory with a provenance comment instead, and update vendored copies only by re-copying their source. (In replicated skills, keep the prose verbatim but repoint cross-skill links to vendored copies, and note the deviation in the README.) See the README's "Skill Self-Containment" section.
- README is organized by provenance: **Original Skills** (authored here) vs **Replicated Skills** (copied verbatim from third-party repos to reduce prompt-injection risk). Don't rewrite replicated skills — updates should come from re-reading the upstream source.
- Skills are coupled in places: the `autoresearch-*` trio runs sequentially (method → verify → program); `improve-codebase-architecture` vendors `grill-with-docs`'s format docs (same re-copy rule); `anneal` vendors copies of `improve-codebase-architecture`'s LANGUAGE.md and `grill-with-docs`'s ADR-FORMAT.md (re-copy from the source when the originals change — never edit the copies), and shells out to the external [hc](https://github.com/will-wright-eng/hc) CLI (raw-git fallback when absent); the design/docs skills (`design-readiness`, `distill-adrs`, `create-context`) share conventions — ADRs in `docs/adr/`, `CONTEXT.md` glossary in repo root, one-question-at-a-time interviews, and writing only on explicit user confirmation. Keep these conventions consistent across skills when editing.
