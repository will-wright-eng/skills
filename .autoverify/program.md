# Autonomous Experiment Program

Read `adapter.md` (in this directory) before starting. Follow the adapter exactly.

## Setup

1. Confirm the current branch and working tree state.
2. Agree on a run tag with the user (e.g. today's date like `mar5`) and create a dedicated experiment branch named `autoresearch/<tag>`. The branch must not already exist — every run is fresh.
3. Read the mutable scope, immutable scope, candidate runner command, primary metric, compute budget, and acceptance rule from `adapter.md`.
4. Confirm a baseline result exists in `results.jsonl`. If not, run the candidate runner once on the unmodified working tree and append the result with `kept: true` and `description: "baseline"`.

## Loop

Repeat until the human interrupts you:

1. Record the current commit as the rollback point.
2. Choose one concrete experimental idea.
3. Edit only mutable-scope files.
4. Commit the candidate.
5. Run the candidate runner command from `adapter.md`.
6. Parse the emitted JSON.
7. Append the result to `results.jsonl` with `commit`, `parent`, `kept`, and a one-line `description` of the idea.
8. Keep the commit only if the adapter's acceptance rule passes.
9. Reset to the rollback point if the candidate is invalid or not better.

## Autonomy

Once the loop has begun, do NOT pause to ask the human whether to continue. Do not ask "should I keep going?" or "is this a good stopping point?". The human may be asleep or away and expects you to keep working indefinitely until manually stopped. If you run out of ideas, think harder: re-read the in-scope files, revisit prior near-misses, try more radical changes within the mutable scope. The loop runs until interrupted.

## Crash Handling

If a candidate crashes because of a small implementation error (typo, missing import), fix it and rerun once. If the idea is fundamentally broken, record it as a crash, reset, and continue.

## Boundaries

Never edit immutable scope. Never weaken the verifier. Never continue from an invalid candidate. Never exceed the compute budget defined in the adapter — the budget is what makes candidates comparable, not just a safety limit. Never edit anything inside `.autoverify/` (it is read-only reference material); your harness lives in this directory.
