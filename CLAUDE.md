# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A collection of Claude Code skills, packaged as a plugin (`.claude-plugin/plugin.json`, name `will-wright-eng-skills`) and installable via `bunx skills add https://github.com/will-wright-eng/skills`. There is no build or test suite — everything is markdown.

## Commands

This repo uses [prek](https://github.com/j178/prek) (a pre-commit-compatible runner) with the standard `.pre-commit-config.yaml`.

```bash
prek run --all-files   # lint: markdownlint (--fix, non-blocking), codespell, whitespace/EOF fixers
prek install           # one-time hook setup
```

Codespell false positives go in `.codespell-ignore`. Markdownlint disables MD013 (line length), MD033 (inline HTML), and MD041 (first-line heading).

## Structure

- Each skill is a directory under `skills/<name>/` containing a `SKILL.md` with YAML frontmatter (`name`, `description`). The description must include concrete "Use when..." trigger phrases — it is what the agent matches against when deciding to invoke the skill.
- Supporting reference docs live beside `SKILL.md` (e.g. `ADR-FORMAT.md`, `CONTEXT-FORMAT.md`, `program.template.md`) and are read by the skill at runtime.
- `docs/` holds the Autoverify Kit reference material used by the autoresearch skills — it documents behavior for *target* repos, not this one.

## Adding or Changing Skills

- Register every new skill in `.claude-plugin/plugin.json` **and** in the README table under the correct provenance section.
- README is organized by provenance: **Original Skills** (authored here) vs **Replicated Skills** (copied verbatim from third-party repos to reduce prompt-injection risk). Don't rewrite replicated skills — updates should come from re-reading the upstream source.
- Skills are coupled in places: the `autoresearch-*` trio runs sequentially (method → verify → program); `improve-codebase-architecture` references `grill-with-docs`'s format docs; the design/docs skills (`design-readiness`, `distill-adrs`, `create-context`) share conventions — ADRs in `docs/adr/`, `CONTEXT.md` glossary in repo root, one-question-at-a-time interviews, and writing only on explicit user confirmation. Keep these conventions consistent across skills when editing.
