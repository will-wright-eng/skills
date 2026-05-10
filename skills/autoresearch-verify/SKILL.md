---
name: autoresearch-verify
description: Build a repo-specific verifier script for an autoresearch loop. The script has two modes — `light` (fast per-candidate metric evaluation, emits the JSON the loop consumes) and `heavy` (matrix-of-conditions integrity check). Run after autoresearch-method confirms the repo fits and before autoresearch-program. Use when a user wants to build the verifier script for an autoresearch loop.
---

# Autoresearch Verify

Build a single repo-specific verifier script with two modes. The script is what every candidate change is scored against. This skill produces **only the script** — git handling, branching, baselines, acceptance rules, and the gating relationship between `light` and `heavy` all live in `program.md` (created by `autoresearch-program`).

## Prerequisites

- `autoresearch-method` has been read and the repo passes the fit checklist (single metric, lockable verifier, bounded mutable scope, cheap evaluation).
- The repo is a git repo. Clean working tree is preferred; if dirty, confirm with the human before writing files.

## What this skill produces

One artifact at the target repo root (or another location the human chooses):

- `verify.py` — a Python script with two modes:
  - `python verify.py --mode light` (default mode if `--mode` is omitted)
  - `python verify.py --mode heavy`

This skill does **not** create `program.md`, configure git, run baselines, or define when `heavy` is invoked. Those are `autoresearch-program`'s job.

The script is written from scratch following the spec below. No stub or schema file is shipped — generic stubs encourage generic verifiers, and the verifier is the most repo-specific part of the methodology.

## Information to gather before writing the script

Read the repo and ask the human as needed. Confirm every value before writing code.

- **Objective.** One sentence. What is this loop trying to improve?
- **Primary metric.** The numeric scalar that ranks candidates in `light` mode. Examples: validation loss, p95 latency ms, accuracy, throughput tokens/sec.
- **Objective direction.** `minimize` or `maximize`.
- **Compute budget for `light`.** A fixed budget every candidate gets (wall clock, training steps, tokens, evaluation episodes). The same budget applies to every candidate so architecturally different candidates are directly comparable on the primary metric. This is the *comparator*, not a safety timeout.
- **Hard timeout for `light`.** A separate cutoff *above* the budget. Runs exceeding it are treated as crashes.
- **Matrix of integrity conditions for `heavy`.** Each condition is a check the candidate must pass. Examples: full test suite, multi-seed stability (run light N times with different seeds, variance below threshold), hold-out evaluation set, dependency / type checks, performance regression vs baseline on auxiliary metrics. Each condition has a name and a pass criterion.
- **Hard timeout for `heavy`.** A cutoff for the entire heavy run.
- **Persistence path.** Where per-run logs go. Default: `verify_runs/` at the repo root.

## Light mode spec

`light` is called for every candidate in the loop. It must be fast and deterministic enough that score differences reflect the candidate, not noise.

- **Input.** The current working tree.
- **Action.** Run the primary metric evaluation under the compute budget. Enforce the hard timeout strictly — exceedances are crashes.
- **Output.** Exactly one JSON object on stdout. The recommended shape is below; adapt field names or add fields to fit the repo, but every field in the **required** list must be present with the documented type so `program.md` can consume the output without per-repo branching.

  **Required fields:**
  - `valid` (boolean) — true if the run completed and the result reflects a genuine evaluation. False on crash, timeout, or any failure that means the score should not be trusted.
  - `score` (number or null) — the primary metric value. Null when `valid` is false.
  - `metric_name` (string) — the name of the primary metric. Should match what was elicited above.
  - `objective` (string, either `"minimize"` or `"maximize"`) — direction for ranking candidates.
  - `status` (string) — short machine-readable status. Suggested values: `"valid"`, `"crash"`, `"timeout"`, `"parse_failure"`, `"correctness_failure"`. Add others as needed.

  **Optional fields (use when useful):**
  - `metrics` (object) — auxiliary numeric/string metrics for diagnostics. Not used for ranking.
  - `artifacts` (object) — paths to logs, plots, checkpoints produced by the run.

  Example:

  ```json
  {
    "valid": true,
    "score": 0.0,
    "metric_name": "<your metric>",
    "objective": "minimize",
    "status": "valid",
    "metrics": {},
    "artifacts": {}
  }
  ```

- **Exit code.** `0` if the run completed and the result is valid. Nonzero for any invalid result (crash, timeout, parse failure, correctness failure). The `valid` field must reflect the same judgment as the exit code.
- **Side effects.** Write logs and intermediate artifacts under `<persistence_path>/<timestamp>/`. Never write outside the persistence path or the script's own scope. Never mutate the working tree.

## Heavy mode spec

`heavy` is invoked by `program.md` as a gate above `light` — accepted candidates must also pass `heavy`. (How and when is `autoresearch-program`'s concern, not this skill's.)

- **Input.** The current working tree (same as `light`).
- **Action.** Run every integrity condition from the matrix. Conditions may run sequentially or in parallel; pick what's natural for the repo. Enforce the heavy hard timeout for the run as a whole.
- **Output.** Exactly one JSON object on stdout. Recommended shape below; adapt as needed, but the **required** fields must be present with the documented type.

  **Required fields:**
  - `mode` (string) — must be `"heavy"`. Distinguishes the payload from light output when both are piped through the same channel.
  - `pass` (boolean) — true only if every condition passed.
  - `conditions` (object) — keyed by condition name. Each value is an object with at minimum a `pass` (boolean) field. Per-condition detail strings and metrics are recommended.

  **Optional fields:**
  - `timings` (object) — keyed by condition name, value is seconds elapsed.
  - `artifacts` (object) — paths to logs or reports produced by heavy.

  Example:

  ```json
  {
    "mode": "heavy",
    "pass": true,
    "conditions": {
      "<condition_name>": {
        "pass": true,
        "detail": "short human-readable summary",
        "metrics": {}
      }
    },
    "timings": {
      "<condition_name>": 12.3
    }
  }
  ```

- **Exit code.** `0` if all conditions pass. Nonzero otherwise. The `pass` field must reflect the same judgment as the exit code.
- **Side effects.** Same persistence rules as `light`.

## Script interface

A single Python script. Suggested skeleton (the agent fills in the bodies):

```python
#!/usr/bin/env python3
import argparse, json, sys

def run_light() -> dict: ...
def run_heavy() -> dict: ...

def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--mode", choices=["light", "heavy"], default="light")
    args = p.parse_args()
    payload = run_light() if args.mode == "light" else run_heavy()
    print(json.dumps(payload, sort_keys=True))
    return 0 if (payload.get("valid") if args.mode == "light" else payload.get("pass")) else 1

if __name__ == "__main__":
    raise SystemExit(main())
```

If Python is not the right language for this repo, use whatever language fits — same interface, same JSON contracts, same exit-code semantics.

## Boundaries

- Do not introduce git operations, branching, commits, or reverts. The verifier reads the working tree and emits JSON. Nothing else.
- Do not implement an acceptance rule. "Is this candidate better than the current best?" is `program.md`'s judgment, made from the JSON.
- Do not define mutable/immutable scope here. That is `program.md`'s concern.
- Do not weaken or skip integrity conditions to make them pass. A failing condition is information.
- Do not write outside the script's persistence path.

## Verification before declaring complete

Before finishing, run both modes once and confirm:

- `python verify.py --mode light` emits a JSON object with the required light fields and exits with code matching the `valid` field.
- `python verify.py --mode heavy` emits a JSON object with the required heavy fields and exits with code matching the `pass` field.

If either mode crashes on the unmodified working tree, fix it before declaring this skill complete. A broken verifier blocks the loop.

## Next step

Run `autoresearch-program` to generate `program.md` at the repo root. That skill defines how `light` and `heavy` are invoked across the loop, the git workflow (branch, commit, revert), the acceptance rule, and the mutable/immutable scope. After `autoresearch-program` runs, the autoresearch skills are no longer in the picture.
