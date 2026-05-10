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
