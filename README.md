# autoresearch skills

A Claude Code plugin that ships three sequential skills for adding a verifiable autonomous experiment loop to a git repository, generalized from [karpathy/autoresearch](https://github.com/karpathy/autoresearch).

| Skill | Purpose |
|---|---|
| `autoresearch-method` | Explain the methodology and evaluate whether the current repo is a good fit. |
| `autoresearch-verify` | Build a repo-specific verifier script with `light` (per-candidate metric) and `heavy` (integrity matrix) modes. |
| `autoresearch-program` | Generate `program.md` at the repo root — the operating directive a fresh agent session uses to run the loop. |

## Install

```bash
bunx skills add https://github.com/will-wright-eng/skills
```

This installs the `autoresearch` plugin and all three skills via the [vercel-labs/skills](https://github.com/vercel-labs/skills) CLI. After install, invoke them in order: `autoresearch-method` → `autoresearch-verify` → `autoresearch-program`. Once `program.md` is generated, hand it to a fresh agent session and the loop runs from there.

## Architecture skills

Replicated from [mattpocock/skills](https://github.com/mattpocock/skills/tree/main/skills/engineering) so the content is auditable in-repo rather than fetched at runtime — replicating third-party skills (after reading them) reduces prompt-injection risk versus installing from a remote source that can change underneath you.

| Skill | Purpose |
|---|---|
| `improve-codebase-architecture` | Surface deepening opportunities — refactors that turn shallow modules into deep ones, using a fixed architectural vocabulary. |
| `grill-with-docs` | Interview-style session that stress-tests a plan against the project's domain language and updates `CONTEXT.md` / ADRs inline as decisions crystallise. |

`improve-codebase-architecture` references `grill-with-docs` for `CONTEXT.md` and ADR format docs, so the two skills are designed to be installed together.

## Other Repos

- [Learning Opportunities: A Claude Code and Codex Skill for Deliberate Skill Development](https://github.com/DrCatHicks/learning-opportunities)
