---
name: distill-adrs
description: Distill existing implementation markdown documents (plans, design docs, RFCs) into ADRs. Extracts candidate decisions, verifies each against the code, and confirms them one at a time before writing. Use when implementation docs have accumulated and the durable decisions inside them should be captured as ADRs.
---

<what-to-do>

Distill the implementation documents I point you at into ADRs. Extract every candidate decision, filter with the four-part test below — including verifying each survivor against the code — then walk me through the survivors one at a time. I approve, edit, or reject each before you write it.

Never write an ADR without my approval of that specific ADR.

</what-to-do>

<supporting-info>

## Input

I provide the source documents: file paths or a directory of implementation markdown (plans, design docs, RFCs, proposals). Only read what I point you at — do not scan the repo for other documents. If I invoked the skill without paths, ask for them before doing anything else.

## Where ADRs live

Most repos have a single set:

```
/
├── docs/
│   └── adr/
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── src/
```

If a `CONTEXT-MAP.md` exists at the root, the repo has multiple contexts, each with its own `docs/adr/`. Place each ADR with the context it belongs to; system-wide decisions go in the root `docs/adr/`.

Read all existing ADRs before extracting so you can detect duplicates and contradictions. Create `docs/adr/` lazily — only when the first approved ADR is written. Use the format in [ADR-FORMAT.md](./ADR-FORMAT.md).

## The pipeline

### 1. Extract candidates

Read every source document fully. A candidate is a statement where a choice was made between genuine alternatives. Skip task lists, how-to steps, status updates, code walkthroughs, and restatements of the obvious.

Record for each candidate: the decision, the stated rationale (if any), and the source document and section.

### 2. Filter with the four-part test

A candidate becomes a proposed ADR only when ALL four are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and one was picked for specific reasons
4. **The code reflects the decision** — the codebase actually implements what the document describes, and the area is stable

The fourth test is what separates distillation from planning: implementation docs record intent, and intent drifts. For every candidate that passes the first three, find the code that implements the decision and confirm it matches. If the code deviates from the document, or the area is clearly mid-refactor or unstable, reject the candidate — an ADR describing a state the code isn't in is worse than no ADR. Don't discard these silently; they go in the close-out summary.

### 3. Confirm one at a time

Present each surviving candidate one at a time, waiting for my verdict before moving to the next. Each proposal includes:

- the drafted ADR text, ready to write as-is
- the source: document and section it was distilled from
- the code evidence: `path:line` references confirming the decision is implemented

I approve, edit, or reject. On approval, write the ADR immediately — don't batch. Number by scanning `docs/adr/` for the highest existing number and incrementing.

If a candidate duplicates an existing ADR, skip it. If it contradicts an existing ADR, don't pick a winner silently — surface the conflict and ask whether the old ADR should be marked superseded.

### 4. Close out

When all candidates are processed, report:

- **Created** — ADRs written this session
- **Rejected by the test** — candidates that failed criteria 1–3, one line each naming the failed criterion
- **Code deviations** — candidates that failed criterion 4, with the specific mismatch; these usually mean either the document or the code needs fixing
- **Duplicates and conflicts** — candidates already covered by, or contradicting, existing ADRs

Then propose archival: list the source documents whose durable content is now fully captured in ADRs and could be archived or deleted, and the ones that still contain undistilled material. Never delete or move anything yourself — I decide.

</supporting-info>
