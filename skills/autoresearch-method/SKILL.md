---
name: autoresearch-method
description: Explain the autoresearch methodology — a verifiable autonomous experiment loop — and evaluate whether the current repo is a good fit before running the autoresearch-verify and autoresearch-program skills. Use when a user wants to add autonomous experimentation to a project, asks about autoresearch/autoresearch, or is about to invoke the other autoresearch skills.
---

# Autoresearch Method

autoresearch adds a verifiable autonomous experiment loop to a git repository:

```text
agent edits bounded scope -> verifier runs -> result is scored -> commit is kept or reverted
```

The loop runs unattended. Every candidate is committed, scored against a fixed compute budget, and kept only if it strictly beats the current best on a single primary metric. Failures and regressions are reset to the parent commit. The methodology generalizes the pattern from `karpathy/autoresearch`.

## When this method fits

A repo is a good candidate when **all** of the following hold:

- **Single, well-defined objective.** One numeric scalar the agent should optimize (loss, latency, throughput, accuracy, score, error rate). If the goal is "make it better" with no metric, the loop has nothing to rank candidates by.
- **Verifier exists or can be written.** Tests, benchmarks, or scoring code that run end-to-end without human judgment in a fixed compute budget. If grading requires a human in the loop, autoresearch will not help.
- **Bounded mutable scope.** A small set of files where experiments make sense (one model file, one algorithm module, one config). Wider scope = noisier loop.
- **Verifier can be locked.** Tests, fixtures, datasets, and scoring code can be marked immutable. If the verifier and the target are entangled, the agent will weaken the verifier instead of solving the problem.
- **Cheap, repeatable evaluation.** Each candidate must finish in a budget you're willing to pay tens or hundreds of times. If a single run takes 12 hours, the loop is impractical.

If any condition is missing, surface that to the user before running the verify or program skills. Do not paper over a missing verifier or a fuzzy metric — the methodology is only as strong as those two pieces.

## How the three skills compose

The skills run **in this order**:

1. **autoresearch-method** *(this skill)* — orient on the methodology and confirm the repo fits.
2. **autoresearch-verify** — implement the verifier: copy templates, fill in the project adapter, implement the candidate runner, lock the immutable scope, establish a baseline. The verifier is the thing the loop optimizes *against* — once it exists, do not change it.
3. **autoresearch-program** — generate `program.md` at the repo root with mutable/immutable scope baked in via light templating. After this skill runs, hand `program.md` to a fresh agent session; the skills are no longer in the picture.

Each skill assumes the previous step is complete. Do not run `autoresearch-program` before `autoresearch-verify` — there is nothing to optimize against yet. Do not skip `autoresearch-method` if you have not first checked the repo fits the method.

## What this skill produces

Nothing on disk. This skill is informational. Its job is to:

1. Explain the loop to the user (above).
2. Walk the fit checklist and report which conditions the repo meets and which it does not.
3. Recommend next step: run `autoresearch-verify`, or surface the gap that blocks the method.

## Reference

- [Karpathy's original autoresearch method for LLM hyperparameter tuning](https://github.com/karpathy/autoresearch)
