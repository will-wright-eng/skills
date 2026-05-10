# Agent Instructions

This directory is the Autoverify Kit: a minimal methodology for adding a verifiable autonomous experiment loop to a git repository.

The loop:

```text
agent edits bounded scope -> verifier runs -> result is scored -> commit is kept or reverted
```

## `.autoverify/` Is Reference Only

After this directory is copied into a target repo, **it is read-only**. No agent — adoption or loop — ever writes to `.autoverify/`. The working harness lives elsewhere (see below). If you find yourself about to edit a file inside `.autoverify/`, stop: you are in the wrong place.

If you are an agent reading this file, your task depends on which **phase** the human is in. Identify the phase first, then follow only that phase's instructions.

## Phases

- **Adoption phase** — the kit has been copied into a target repo and there is no harness directory yet. Your job is to create the harness directory at the target repo root and populate it. See [Adoption Phase](#adoption-phase).
- **Loop phase** — a harness directory exists with a filled-in `adapter.md` and an implemented `run_candidate.py`. Your job is to run experiments. See [Loop Phase](#loop-phase). Your operating directive is `<harness>/program.md`, followed without deviation.

## Directory Contents (`.autoverify/`, reference only)

| File | Purpose |
|---|---|
| `agent-instructions.md` | This file. Orientation for any agent that opens `.autoverify/`. |
| `program.md` | Template operating directive. The adoption agent copies this verbatim into the harness directory; the loop agent follows the copy literally. |
| `result.schema.json` | Normalized JSON contract every candidate result must satisfy. The adoption agent copies this verbatim into the harness directory. |
| `adapter.md` | Template with `TODO`s. The adoption agent copies this into the harness directory and fills it in. |
| `run_candidate.py` | Stub. The adoption agent copies this into the harness directory and implements it. |
| `program.karpathy.md` | Reference example only — the original `program.md` from Karpathy's `autoresearch` repo, kept verbatim so adopters can see a concrete instantiation. **Not** part of the methodology. Do not follow it. Do not copy it. |

## Harness Directory (created at the target repo root)

The adoption agent creates a working directory at the root of the target repository (default name: `autoresearch/`, or another name appropriate to the project). Everything the loop agent reads and writes lives inside it.

| File | Origin | Purpose |
|---|---|---|
| `<harness>/program.md` | copied verbatim from `.autoverify/program.md` | Operating directive followed by the loop agent. |
| `<harness>/result.schema.json` | copied verbatim from `.autoverify/result.schema.json` | Result contract. |
| `<harness>/adapter.md` | copied from `.autoverify/adapter.md`, then filled in | Project-specific objective, scopes, budget, runner command, acceptance rule. |
| `<harness>/run_candidate.py` | copied from `.autoverify/run_candidate.py`, then implemented | Verifier wrapper. |
| `<harness>/runs/` | created by the runner | Per-candidate logs and reports. |
| `<harness>/results.jsonl` | appended by the loop agent | Append-only log: one full result JSON per line, augmented with `commit`, `parent`, `kept`, `description`. |

## Gitignore

In the target repo's `.gitignore`, ignore the `.autoverify/` reference directory (it is local methodology, not project source) and the harness's runtime artifacts:

```text
.autoverify/
<harness>/runs/
<harness>/results.jsonl
```

The harness directory itself (containing `program.md`, `result.schema.json`, `adapter.md`, `run_candidate.py`) **may be tracked** so collaborators share the same experimental contract. Track or ignore at the team's discretion.

## Adoption Phase

Read this section only if there is no harness directory yet, or its `adapter.md` still contains `TODO`s and `run_candidate.py` is the unimplemented stub.

Your job is to bootstrap the harness directory at the target repo root. Do not edit anything inside `.autoverify/`.

### 1. Choose the harness directory name

Default: `autoresearch/`. Pick another name only if it would collide with existing project files. Confirm the choice with the human before proceeding. Use the chosen name as `<harness>` below.

### 2. Create the harness directory and copy the immutable files

Create `<harness>/` at the target repo root. Copy these files verbatim:

- `.autoverify/program.md` → `<harness>/program.md`
- `.autoverify/result.schema.json` → `<harness>/result.schema.json`

Do not modify their contents.

### 3. Generate `<harness>/adapter.md`

Copy `.autoverify/adapter.md` to `<harness>/adapter.md`, then fill in every `TODO` by reading the target repo:

- **Harness layout** — set the harness directory name and the canonical paths.
- **Objective** — the single thing the loop optimizes for.
- **Primary metric** — the numeric scalar that ranks candidates, plus its direction (`minimize` or `maximize`) and how it is computed in this repo.
- **Compute budget** — wall clock seconds, training steps, tokens, episodes, or whatever fits the domain. Every candidate runs under the same fixed budget so architecturally different candidates are comparable on the metric. This is *not* a safety timeout.
- **Hard timeout** — a separate cutoff *above* the budget. Runs exceeding it are treated as crashes.
- **Mutable scope** — the smallest set of target-repo files the agent may edit to produce meaningful experiments.
- **Immutable scope** — the entire harness directory, the entire `.autoverify/` directory, and the target repo's verifier, tests, fixtures, datasets, benchmarks, lockfiles, CI files.
- **Candidate runner command** — typically `python3 <harness>/run_candidate.py`.
- **Acceptance rule** — typically `valid AND score strictly better than current best`. Add a noise threshold or repeated-run requirement if the metric is noisy.
- **Anti-cheating rules** — at minimum: no editing immutable scope, no weakening tests/benchmarks/scoring, no training on or hardcoding evaluation answers, no new dependencies unless the adapter explicitly allows it.

### 4. Implement `<harness>/run_candidate.py`

Copy `.autoverify/run_candidate.py` to `<harness>/run_candidate.py`, then implement it. The script must:

- Evaluate the current working tree end-to-end.
- Enforce the compute budget defined in `<harness>/adapter.md`.
- Enforce the hard timeout above the budget; treat exceedances as crashes.
- Persist logs and artifacts under `<harness>/runs/`.
- Print one JSON object on stdout that validates against `<harness>/result.schema.json`.
- Exit nonzero for invalid candidates (crash, timeout, parse failure, correctness failure).

### 5. Update `.gitignore`

Append to the target repo's `.gitignore`:

```text
.autoverify/
<harness>/runs/
<harness>/results.jsonl
```

### 6. Baseline

Run the candidate runner once on the unmodified working tree. Confirm the JSON validates against `<harness>/result.schema.json`. Append it to `<harness>/results.jsonl` with `kept: true` and `description: "baseline"`. Report the baseline result to the human.

Adoption is complete. The loop agent (or the same agent in a fresh session) will operate under `<harness>/program.md`.

## Loop Phase

Read this section only if a harness directory exists with a filled-in `adapter.md` and an implemented `run_candidate.py`.

Your operating directive is `<harness>/program.md`. Follow it literally and without deviation. It defines:

- Setup (branch convention, baseline check).
- The loop (rollback point, edit, commit, run, parse, log, keep-or-reset).
- Autonomy (do not pause to ask the human whether to continue).
- Crash handling.
- Boundaries (immutable scope, verifier integrity, compute budget as comparator, no edits to `.autoverify/` or the harness).

`<harness>/adapter.md` supplies the project-specific values referenced by `program.md` (mutable scope, metric, budget, runner command, acceptance rule, anti-cheating rules). Read both before starting.

If `program.md` and `adapter.md` appear to conflict, stop and ask the human. Do not resolve it by editing either file.

## Core Contract

The target repo must provide one command (defined in `<harness>/adapter.md`):

```bash
python3 <harness>/run_candidate.py
```

That command evaluates the current working tree and emits normalized JSON:

```json
{
  "valid": true,
  "score": 0.0,
  "metric_name": "example_metric",
  "objective": "minimize",
  "status": "valid",
  "metrics": {},
  "artifacts": {}
}
```

If the verifier is weak, the methodology is weak. Keep tests, fixtures, datasets, benchmark harnesses, and scoring code outside the agent's mutable scope.
