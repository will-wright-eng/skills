---
name: state-machine-audit
description: Find the explicit and implicit state machines in a codebase, classify each as explicit or implicit with evidence, document states/invariants/transition tables, prove which invalid states are reachable (including via retries and concurrency), then fix confirmed bugs with regression tests. Use when asked to audit state handling, find state bugs, map state machines, or "find the implicit state machines in my app".
---

# State Machine Audit

State machines are not the problem. The problem is the gap between the machine the code
*actually* implements and the one its authors *think* it implements. This skill closes that
gap by making every machine explicit on paper, then checking the code against the paper.

The deliverable is **one living document** (`docs/state-machines.md` unless the repo has a
better home) plus **fixes with regression tests**. The document is scaffolding; the confirmed,
evidenced bugs are the product.

## Core rules

1. **Evidence or it isn't a bug.** Every reported invalid state or transition must cite a
   concrete code path (file:line → file:line) that reaches it, or a failing test you wrote.
   "Could theoretically happen" goes in a separate *Unverified* list, never in the bug list.
2. **Classify before you judge.** Every machine gets an explicit/implicit verdict with the
   signals that justify it. Implicit machines get the most scrutiny; explicit ones get checked
   for drift between the declared machine and the surrounding code.
3. **Enumerate, don't pattern-match.** Build the full `states × events` table. Blank cells are
   findings, not omissions.
4. **Retries and concurrency are first-class events.** Treat "same event delivered twice",
   "event arrives out of order", and "two transitions race" as rows in the table.
5. **Keep the document updated** as you fix things. Every fix changes the table or an
   invariant; the doc must reflect the code at the end, not the beginning.

## Phase 0 — Scope

- Ask (or infer from the request) which subsystem to audit. A whole monolith is too much for
  one pass; prefer one bounded context (orders, auth sessions, sync engine, upload pipeline).
- Note the concurrency model up front: single-threaded event loop, worker pool, multiple
  processes, distributed with retries, background jobs, webhooks. This determines which race
  rows matter in Phase 3.
- Locate existing tests and any existing state docs or diagrams. Prior art counts as evidence
  of intent, which you will later compare against behavior.

## Phase 1 — Discover and classify machines

Search for anything whose behavior depends on "what mode is this thing in". Starting signals:

- `status`, `state`, `phase`, `stage`, `mode`, `step` fields; enums or string unions of
  lifecycle words (`pending`, `active`, `closed`, `draft`, `failed`, `retrying`).
- Clusters of booleans on one entity (`isPaid`, `isShipped`, `isCancelled`), nullable
  timestamps that act as flags (`paidAt`, `deletedAt`), or `Optional` fields whose presence
  implies a phase.
- `switch`/`match`/`if` chains on the same field across multiple files.
- Lifecycle hooks and callbacks (`onConnect`, `onClose`, `componentDidMount`, `beforeSave`).
- Queues, jobs, sagas, workflows, retry loops, circuit breakers, connection handlers, UI
  form/wizard flows, auth/session handling, feature flags gating transitions.
- Database constraints or migrations that encode lifecycle (`CHECK status IN (...)`).

For each candidate, decide whether it is a real machine (distinct states with meaningful
transitions and invariants) or just a flag. A single boolean with no ordering is usually not
worth modeling; two or more correlated fields almost always are.

### Classification rubric

Give every machine exactly one verdict. Record the signals you observed.

| Verdict | Definition | Typical signals |
| --- | --- | --- |
| **Explicit** | States are a closed, named set and transitions are defined in one place. | Enum/discriminated union for state; a single reducer, transition function/table, or library (XState, Stateless, Boost.SML, Spring StateMachine, Temporal/saga definitions); invalid transitions rejected centrally. |
| **Partially explicit** | States are named but transitions are not centralized, or vice versa. | A `Status` enum exists but any call site can write `entity.status = X`; or a transition function exists but state is still reconstructed from several fields. |
| **Implicit** | The machine is emergent. Neither states nor transitions are declared anywhere. | State derived from combinations of booleans/nullables/timestamps; lifecycle words compared as raw strings; transitions spread across handlers with no shared guard; the "diagram" exists only in people's heads. |

Also record **where the machine lives**: in-memory object, DB row, client store, message in a
queue, or split across several of these (split storage is itself a common source of invalid
states, because the parts can disagree).

Rough prior for effort allocation: implicit machines produce the most reachable-invalid-state
bugs; partially explicit produce the most bypass bugs (someone writes the field directly);
explicit ones mostly produce drift bugs (code outside the machine assumes transitions the
machine no longer has, or vice versa). Check all three; weight time accordingly.

## Phase 2 — Document each machine

In the document, one section per machine, in this shape:

```markdown
## <Machine name>   (verdict: Implicit | Partially explicit | Explicit)

**Lives in:** <files / tables / stores>
**Classification evidence:** <bullet list of signals from the rubric>
**Concurrency context:** <who can transition it, from where, can two actors overlap>

### States
| State | How the code represents it | Notes |
|---|---|---|
| Pending | `paidAt == null && shippedAt == null && !cancelled` | initial |
| ...

For implicit machines, every state must be defined as a predicate over the real fields.
List the field combinations that map to *no* named state — these are candidate invalid states.

### Invariants
- I1: An order is debited at most once.
- I2: `shippedAt != null` implies `paidAt != null`.
- ...

Write invariants as checkable statements. Prefer ones that a test or assertion could verify.

### Transition table
| From \ Event | pay | ship | cancel | pay (retry/dup) | ship ∥ cancel (race) |
|---|---|---|---|---|---|
| Pending | Paid | ✗ (no handler: ___) | Cancelled | ... | ... |
| Paid | ? | Shipped | Cancelled?? | ... | ... |
| ...

Cell legend:
- `NextState` — handled, lands in a valid state
- `✗` — rejected or unreachable, note *how* (guard at file:line, DB constraint, etc.)
- `?` — no handler found; behavior unknown (crash / silent no-op / corruption) — investigate
- `!!` — reaches an invalid state; link to a finding
```

Always include the retry/duplicate and race columns relevant to the concurrency context from
Phase 0. Common event variants worth columns:

- duplicate delivery of the same event (webhook redelivery, client retry after timeout)
- event arriving after a terminal state
- two different events applied concurrently to the same entity
- partial failure mid-transition (first write succeeds, second throws)
- process restart between the two halves of a transition

## Phase 3 — Reachability analysis

For every `?` and `!!` cell and every unnamed field combination, determine whether the code
can actually get there. Work from the table, not from intuition.

For each candidate:

1. **Trace the path.** Find the entry point (handler, job, endpoint, UI action) and follow it to
   the writes. Record the chain as `file:line → file:line`.
2. **Check guards.** Is there anything that prevents it: a precondition check, a DB constraint,
   optimistic locking, idempotency key, unique index, transaction isolation? Cite it or confirm
   its absence.
3. **Check the concurrency angle.** If a guard is read-then-write without a lock/transaction,
   it is bypassable under a race. Note the window.
4. **Confirm.** Preferred: write a failing test that drives the path (unit test for sequential
   cases; a test with two interleaved operations, a mocked duplicate delivery, or an injected
   failure between writes for the concurrent/partial cases). If a test is impractical, a
   complete static trace with every branch condition spelled out is acceptable but must be
   labeled *statically confirmed* rather than *reproduced*.
5. **Classify the outcome** when reached: crash, silent no-op, data corruption, invariant
   violation, stuck entity (no exit transition), duplicated side effect (double charge, double
   email), security (transition skips an auth check).

Anything you cannot confirm goes in an **Unverified** list with what would be needed to confirm
it. Do not pad the bug list.

## Phase 4 — Prioritize and group

Group findings into issues by *root cause*, not by symptom. Ten cells that are all reachable
because `status` is written directly from six call sites are one issue ("no central transition
guard"), not ten.

Rank by impact, roughly:

1. Money, data loss, or security (double charge, lost order, auth bypass)
2. Stuck entities / user-visible wrong state with no recovery
3. Duplicated side effects that are annoying but recoverable (double notification)
4. Crashes with clean recovery
5. Silent no-ops that happen to be harmless today

For each issue record: severity, affected machine(s), the table cells it covers, root cause,
proposed fix, and whether the fix changes the machine's shape (new state, removed transition,
new guard).

## Phase 5 — Fix with regression tests, keep the doc current

For each issue, in priority order:

1. Write or finalize the regression test that fails on the current code and encodes the
   invariant or transition being protected. Name it after the invariant (`test_order_debited_at_most_once`).
2. Make the fix. Prefer fixes that move the machine toward *explicit*: centralize transitions
   behind one function, replace correlated booleans with a discriminated union, add a DB
   constraint or unique index that makes the invalid state unrepresentable, add idempotency
   keys for retried events, wrap read-modify-write in a transaction or compare-and-swap.
3. Re-run the full suite.
4. Update the document: flip the cell from `!!`/`?` to its new value, add the guard citation,
   bump the verdict if the machine became more explicit, and move the finding to a
   **Resolved** section with the test name.

Do not stop at the first fix. Work the list until the remaining issues are ones the user should
decide on (behavior changes, product questions, large refactors), then stop and present those.

## Report template

The final document should read top-down like this:

```markdown
# State machines in <subsystem>

_Last verified against commit <sha> on <date>._

## Summary
| Machine | Verdict | States | Invalid states reachable | Open issues | Resolved |
|---|---|---|---|---|---|
| Order lifecycle | Implicit | 6 (+3 unnamed) | 4 confirmed | 2 | 3 |
| WebSocket conn | Explicit | 4 | 0 | 0 | 1 (drift) |

## Issues (open), by priority
### ISSUE-1 [P1] Double debit on payment webhook redelivery
- Machines: Order lifecycle
- Cells: Paid × pay(dup)
- Evidence: reproduced — `tests/orders/test_payment_idempotency.py::test_order_debited_at_most_once`
  path: `webhooks/stripe.py:88 → services/orders.py:140 → billing/ledger.py:52`
- Root cause: no idempotency key; guard at orders.py:131 is read-then-write outside txn
- Proposed fix: ...
- Status: open — needs product decision on ...

## Resolved
...

## Unverified
...

## Machines
(one Phase 2 section per machine)
```

## Anti-patterns to avoid

- Reporting a state machine's *existence* as a finding. Explicitness is a property, not a bug.
- Recommending "rewrite with XState" as the fix for everything. The fix is whatever makes the
  specific invalid state unreachable; sometimes that's one unique index.
- Filling blank table cells with guesses. `?` is an honest cell until traced.
- Listing concurrency bugs without naming the window (which two operations, which shared
  read, which missing lock).
- Letting the document drift from the code during the fix phase. If the last commit changed
  a transition, the last commit also touched the doc.
