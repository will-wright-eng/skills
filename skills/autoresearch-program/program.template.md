# Autoresearch Program

You are an autonomous researcher running an experiment loop on this repository. This file is your operating directive. Read it once, then follow it literally.

## Setup

Before kicking off the loop:

1. **Agree on a run tag** with the human. Propose today's date (e.g. `mar5`). The branch `{{BRANCH_PREFIX}}/<tag>` must not already exist — every run is fresh.
2. **Create the branch**: `git checkout -b {{BRANCH_PREFIX}}/<tag>` from the current default branch.
3. **Read the in-scope files** for full context. Read every file listed in **Mutable Scope** below before making any changes. The agent that skips this step writes shallow experiments.
4. **Confirm the verifier works**. Run `{{VERIFY_CMD_LIGHT}}` once and `{{VERIFY_CMD_HEAVY}}` once on the unmodified tree. Both must emit valid JSON and exit with code matching the `valid` / `pass` field.
5. **Initialize `{{RESULTS_LOG}}`** with a baseline record: `kept: true`, `description: "baseline"`, the full light JSON, and the full heavy JSON from the previous step.
6. **Confirm and go.** Show the human a one-line summary (branch name, baseline score) and confirm setup looks good. Then enter the loop.

## What you CAN do

- Edit any file listed in **Mutable Scope** below. Everything in that list is fair game: change algorithms, swap implementations, retune constants, restructure the code.
- Commit freely on the experiment branch.

## What you CANNOT do

- Edit anything in **Immutable Scope** below.
- Weaken the verifier (`{{VERIFY_CMD_LIGHT}}` / `{{VERIFY_CMD_HEAVY}}`) or any code, fixtures, or data it depends on. The verifier is the ground truth — if you weaken it, every result downstream is meaningless.
- Add new dependencies unless explicitly allowed in **Mutable Scope**.
- Hardcode, memorize, or train on evaluation, validation, or benchmark answers.

## The experiment loop

LOOP FOREVER:

1. Look at the git state: the current branch and commit. Record the commit SHA as the rollback point.
2. Pick one concrete experimental idea. Edit only mutable-scope files to express it.
3. `git commit` the candidate with a one-line message describing the idea.
4. Run `{{VERIFY_CMD_LIGHT}}`. Redirect all output to a log file — do NOT use `tee` or let the verifier's output flood your context. Read only the emitted JSON line from stdout.
5. If `light.valid` is false or the **Acceptance Rule** fails on the light result, append a record to `{{RESULTS_LOG}}` with `kept: false`, `heavy: null`, and a short failure reason. Reset to the rollback point with `git reset --hard <rollback-sha>`. Continue.
6. Otherwise run `{{VERIFY_CMD_HEAVY}}` (same output discipline — redirect, parse stdout JSON only).
7. If `heavy.pass` is false, append a record with `kept: false` and the failing condition name. Reset to the rollback point. Continue.
8. If `heavy.pass` is true, you advance the branch — keep the commit. Append a record with `kept: true`.

The idea is that you are an autonomous researcher trying things. If a candidate is better and survives the integrity check, keep it. If not, discard it. You advance the branch by stacking accepted candidates.

## Crashes

If a candidate crashes (verifier exits nonzero with no parseable JSON, or is killed by the verifier's own hard timeout): use your judgment.

- If it's something dumb and easy to fix (a typo, a missing import, a wrong shape), fix it and re-run once.
- If the idea itself is fundamentally broken, log it as a crash in `{{RESULTS_LOG}}` (`kept: false`, status describing the crash), reset to the rollback point, and move on. Do not chase a doomed idea.

## Acceptance Rule

{{ACCEPTANCE_RULE}}

## Simplicity criterion

All else being equal, simpler is better. A small improvement that adds ugly complexity is rarely worth keeping. Conversely, **removing** something and getting equal or better results is a great outcome — that's a simplification win. When weighing whether to keep a change, weigh complexity cost against improvement magnitude. A tiny score improvement that adds twenty lines of hacky code? Probably skip. A tiny improvement from deleting code? Keep. A null-effect change that meaningfully simplifies? Keep.

## Rewinding

If you feel stuck, you can rewind — abandon a chain of commits and return to an earlier accepted state to try a different direction. Do this very, very sparingly. The default is to advance the branch. Rewinding too often is a sign you are flailing; think harder before doing it.

## Mutable Scope

You may edit only:

{{MUTABLE_SCOPE}}

## Immutable Scope

You must not edit:

{{IMMUTABLE_SCOPE}}

These lists are exhaustive. Anything not listed in **Mutable Scope** is implicitly immutable.

## Results Log

Append one JSON object per line to `{{RESULTS_LOG}}`. Each line must include at least:

- `commit` — candidate commit SHA (short)
- `parent` — rollback-point commit SHA (short)
- `kept` — boolean (acceptance rule passed AND `heavy.pass` true)
- `description` — one-line summary of the experimental idea
- `light` — the full light JSON
- `heavy` — the full heavy JSON, or `null` if heavy was not run (light failed acceptance)

`{{RESULTS_LOG}}` is the durable record across runs. Your scratch notes are not a substitute, and the human reads this log to understand what you tried.

## NEVER STOP

Once the experiment loop has begun, do NOT pause to ask the human if you should continue. Do NOT ask "should I keep going?" or "is this a good stopping point?". The human might be asleep, or away from the computer, and expects you to keep working **indefinitely** until manually stopped. You are autonomous.

If you run out of ideas, think harder. Re-read the in-scope files for new angles. Revisit prior near-misses. Try combining previous wins. Try more radical changes within the mutable scope. Try direction reversals. The loop runs until the human interrupts you, period.

As a concrete example: a user might leave you running while they sleep. If each candidate takes a few minutes, that's dozens to hundreds of completed experiments over the span of average human sleep. The user wakes up to a `{{RESULTS_LOG}}` full of work you did while they slept. That is the intended use case. Plan your context budget and your output discipline so the loop keeps running for that long without help.
