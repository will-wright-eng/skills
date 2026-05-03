# Project Adapter

This is the template adapter. The adoption agent copies this file into the target repo's harness directory and fills in every `TODO`. The copy under the harness directory is the live adapter; this file under `.autoverify/` is reference only and stays untouched.

## Harness Layout

- Harness directory: `TODO` (e.g. `autoresearch/` at the target repo root)
- Adapter (this filled-in copy): `<harness>/adapter.md`
- Operating directive (copied verbatim from `.autoverify/program.md`): `<harness>/program.md`
- Result schema (copied verbatim from `.autoverify/result.schema.json`): `<harness>/result.schema.json`
- Candidate runner (implemented from `.autoverify/run_candidate.py` stub): `<harness>/run_candidate.py`
- Per-candidate logs: `<harness>/runs/`
- Results log: `<harness>/results.jsonl`

The harness directory is self-contained: the loop agent operates only on files inside it (plus the target repo's mutable scope). `.autoverify/` is reference and is never read during the loop.

## Objective

- Goal: `TODO`
- Primary metric: `TODO`
- Objective direction: `minimize` or `maximize`

## Compute Budget

The budget is the comparator, not just a safety cutoff. Every candidate gets the same fixed compute (wall clock, step count, token count, sample count, or whatever fits the domain) so that architecturally different candidates are directly comparable on the primary metric.

- Budget: `TODO` (e.g. `300 seconds wall clock training time`, `1000 evaluation episodes`, `N tokens`)
- Hard timeout: `TODO seconds` (safety cutoff above the budget; runs exceeding this are treated as crashes)

## Mutable Scope

The agent may edit only:

- `TODO` (target repo files the agent is allowed to change between candidates)

## Immutable Scope

The agent must not edit:

- The entire harness directory (`<harness>/`) — including `program.md`, `result.schema.json`, `run_candidate.py`, `adapter.md`, `runs/`, `results.jsonl`.
- The entire `.autoverify/` reference directory.
- `TODO tests, fixtures, datasets, benchmarks, lockfiles, CI files`

Immutable scope describes what the agent must not edit at runtime. It is independent of git tracking — a file can be gitignored and still be immutable, or vice versa.

## Candidate Runner

Run every candidate with:

```bash
TODO  # e.g. python3 autoresearch/run_candidate.py
```

The runner must emit normalized JSON on stdout and write any logs under `<harness>/runs/`.

## Result Contract

```json
{
  "valid": true,
  "score": 0.0,
  "metric_name": "TODO",
  "objective": "minimize",
  "status": "valid",
  "metrics": {},
  "artifacts": {}
}
```

## Acceptance Rule

Keep a candidate when:

```text
TODO
```

Discard a candidate when:

```text
TODO
```

## Results Log

Append one line per candidate to `<harness>/results.jsonl`. Each line is the full result JSON emitted by the candidate runner, augmented with at least:

- `commit`: candidate commit SHA (short)
- `parent`: rollback-point commit SHA (short)
- `kept`: boolean — whether the acceptance rule passed
- `description`: one-line summary of the experimental idea

This is the durable record across runs. The agent's own scratch notes are not a substitute.

## Anti-Cheating Rules

- Do not edit immutable scope.
- Do not weaken tests, benchmarks, fixtures, or scoring code.
- Do not train on or hardcode validation, test, or benchmark answers.
- Do not add dependencies unless this adapter explicitly allows it.
