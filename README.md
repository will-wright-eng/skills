# will-wright-eng skills

Browse this collection on [skills.sh](https://www.skills.sh/will-wright-eng/skills), including per-skill security audits.

## Install

```bash
bunx skills add https://github.com/will-wright-eng/skills
```

This command uses the [vercel-labs/skills](https://github.com/vercel-labs/skills) CLI to implement skills in this repo.

## Update

```bash
bunx skills update
```

Updates all installed skills; pass a name to update one (`bunx skills update design-readiness`). The CLI has no version pinning — `update` re-fetches whatever is at the head of each source repo — so review the diff after updating.

## Skill Self-Containment

Every skill in this repo installs standalone. Cross-skill file references (`../other-skill/DOC.md`) are an antipattern: the [skills CLI](https://github.com/vercel-labs/skills) installs skills individually (`--skill <name>`, `skills use`, direct skill URLs) with no dependency resolution, so a link into a sibling skill directory dangles unless the whole repo happens to be installed. Shared docs are instead vendored into each skill that needs them, marked with a provenance comment (`<!-- Vendored verbatim from ... -->`). Vendored copies are updated by re-copying their source, never by editing in place.

## Original Skills

### Autoresearch

Three sequential skills for adding a verifiable autonomous experiment loop to a git repository, generalized from [karpathy/autoresearch](https://github.com/karpathy/autoresearch).

After install, invoke them in order: `autoresearch-method` → `autoresearch-verify` → `autoresearch-program`. Once `program.md` is generated, hand it to a fresh agent session and the loop runs from there.

| Skill | Purpose |
| --- | --- |
| `autoresearch-method` | Explain the methodology and evaluate whether the current repo is a good fit. |
| `autoresearch-verify` | Build a repo-specific verifier script with `light` (per-candidate metric) and `heavy` (integrity matrix) modes. |
| `autoresearch-program` | Generate `program.md` at the repo root — the operating directive a fresh agent session uses to run the loop. |

### Design & Documentation

Self-contained skills covering the design-doc lifecycle: verify a design before building, distill what was built into ADRs, and keep the domain glossary sharp. Each writes only on explicit confirmation.

| Skill | Purpose |
| --- | --- |
| `design-readiness` | Audit a design/implementation/proposal doc for consistency with the codebase, ADRs, and `CONTEXT.md`, plus completeness of definition, then interview through drift fixes and open design decisions — interview answers are the approval, so the revised doc is applied once findings are resolved. |
| `distill-adrs` | Distill existing implementation docs (plans, design docs, RFCs) into ADRs — extracts candidate decisions, verifies each against the code, and confirms them one at a time before writing. |
| `create-context` | Build or refine a `CONTEXT.md` glossary — explores the codebase for candidate domain terms, then confirms each term, relationship, and ambiguity one at a time before writing. |

### Refactoring

| Skill | Purpose |
| --- | --- |
| `anneal` | Carve a god module into stable and volatile pieces along evidence from git history — hotspot ranking via the [hc](https://github.com/will-wright-eng/hc) CLI (raw-git fallback when absent), a three-axis autopsy of the target file, a seam-by-seam interview, and a strangler-fig migration plan with a measurable baseline. |

Vendors copies of `improve-codebase-architecture`'s LANGUAGE.md (architectural vocabulary) and `grill-with-docs`'s ADR-FORMAT.md — see [Skill Self-Containment](#skill-self-containment).

## Replicated Skills

Copied verbatim from their source repos — replicating third-party skills (after reading them) reduces prompt-injection risk versus installing from a remote source that can change underneath you.

### Architecture

From [mattpocock/skills](https://github.com/mattpocock/skills/tree/main/skills/engineering).

| Skill | Purpose |
| --- | --- |
| `improve-codebase-architecture` | Surface deepening opportunities — refactors that turn shallow modules into deep ones, using a fixed architectural vocabulary. |
| `grill-with-docs` | Interview-style session that stress-tests a plan against the project's domain language and updates `CONTEXT.md` / ADRs inline as decisions crystallise. |

Upstream, `improve-codebase-architecture` linked to `grill-with-docs` for its `CONTEXT.md` and ADR format docs; this repo vendors copies of those docs into the skill instead (see [Skill Self-Containment](#skill-self-containment)). The two repointed link paths are the only local deviation from the replicated source.

### Productivity

From [mattpocock/skills](https://github.com/mattpocock/skills/blob/main/skills/productivity/grilling/SKILL.md).

| Skill | Purpose |
| --- | --- |
| `grill-me` | Relentless, one-question-at-a-time interview that stress-tests a plan or design before you build, recommending an answer for each decision and exploring the codebase when it can answer a question itself. |

### Communication

From [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman/blob/main/skills/caveman/SKILL.md).

| Skill | Purpose |
| --- | --- |
| `caveman` | Ultra-compressed response mode — cuts token usage ~75% by stripping articles, filler, and hedging while keeping full technical accuracy. Supports `lite` / `full` / `ultra` and 文言文 (`wenyan-*`) intensity levels. |

## Other Repos

- [Learning Opportunities: A Claude Code and Codex Skill for Deliberate Skill Development](https://github.com/DrCatHicks/learning-opportunities)
