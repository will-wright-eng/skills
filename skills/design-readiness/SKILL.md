---
name: design-readiness
description: Audit a design/implementation/proposal markdown document for consistency with the codebase and its documented context (ADRs in docs/adr/, CONTEXT.md) and completeness of definition, then interview the user through drift fixes and unresolved design decisions — interview answers are the approval, so the revised document is applied once the findings are resolved. Use when a doc needs verifying before implementation — "is this consistent with the code and defined well enough to build?"
---

<what-to-do>

Audit the markdown document I point you at against the codebase and the repo's documented context — ADRs (typically `docs/adr/`) and `CONTEXT.md` in the repo root — then interview me — one question at a time, with your recommended answer — until every drifted claim and unresolved design decision is settled. Collect resolutions as we go; do not edit the document during the interview. My interview answers are the approval: when the interview is complete, apply one revised draft of the full document and show me what changed.

</what-to-do>

<supporting-info>

## Input

I provide the path to one design/implementation/proposal markdown document. If invoked without a path, ask for it before doing anything else.

## Context sources

Before auditing, gather the repo's documented context alongside the code:

- **ADRs** — read every record in `docs/adr/` (or wherever the repo keeps them). ADRs are authority on decisions the way the code is authority on behavior.
- **CONTEXT.md** — the domain glossary in the repo root, if present. It is authority on terminology.

If either is absent, proceed without it — do not ask me to create one.

## Step 1: map the document

Read it fully and split every substantive claim into:

- **Descriptive** — statements about the codebase as it exists today ("the API validates X", "orders are stored in Postgres")
- **Prescriptive** — the proposed change ("we will add Y", "the new endpoint should…")

Only descriptive claims can drift; prescriptive claims can only be incomplete. Never flag a proposed change as "inconsistent with the code" — not matching the code is the point of a proposal.

## Step 2: consistency audit

Verify every descriptive claim against the code and classify it:

- **Consistent** — the code confirms it (note `path:line`)
- **Drifted** — the code contradicts it (note `path:line` and what the code actually does)
- **Unverifiable** — the claim references something you cannot locate; carry it into the interview as a question

Then check the whole document — descriptive and prescriptive claims alike — against the documented context:

- **ADR conflict** — a claim that contradicts an accepted ADR. This is the one way a prescriptive claim can be inconsistent: proposing what an ADR already decided against means either the document must change or the ADR is being superseded — an interview question either way.
- **Terminology drift** — a term used contrary to its CONTEXT.md definition, or a new synonym coined for a concept the glossary already names.

## Step 3: completeness audit — prescriptive claims

The test: could an engineer implement this tomorrow without making a design decision the document doesn't record? Collect the gaps:

- explicit **Open Questions** sections and TODO/TBD markers
- **implicit gaps** — undefined terms, unspecified interfaces or data shapes, missing error and edge-case behavior, unstated ordering/concurrency assumptions, absent migration or rollout story, success criteria that can't be checked
- **internal contradictions** — places where the document disagrees with itself

Filter honestly: a finding must be a decision whose resolution changes what gets built. Style issues and nice-to-haves are not findings.

## Step 4: interview

Open with the audit summary — counts of drifted claims, unverifiable claims, and open decisions — then work through the findings one question at a time, waiting for my answer before the next:

- **Drifted claim**: show the document's claim, the code's reality (`path:line`), and your recommendation — usually "update the doc", occasionally "the doc is right and the code is what's being changed — confirm?"
- **Open decision**: state the question, the realistic options, and your recommended answer with reasoning.
- **ADR conflict**: cite the ADR and the contradicting passage; recommend either aligning the document or, if superseding is the intent, stating the supersession explicitly in the document. Updating the ADR itself is out of scope — flag it at close-out.
- **Terminology drift** that is plainly mechanical — the glossary names the concept and the document just uses a different word — needs no question; fold the alignment into the draft and report it at close-out. Ask only when the document may be deliberately redefining or extending a term.
- Order questions by dependency — resolve decisions that other decisions hinge on first.
- If a question can be answered by exploring the codebase, explore instead of asking.

Record each resolution; do not modify the document yet.

## Step 5: revised draft

When every finding is resolved (or explicitly deferred by me), produce one revised draft of the full document:

- drifted claims corrected to match the code, or to the confirmed intent
- each resolved decision folded into the body of the relevant section as normal prose — the document should read as if the question never existed
- terminology aligned to CONTEXT.md
- the Open Questions section reduced to what genuinely remains open, removed entirely if empty
- structure, headings, and voice preserved; no new sections invented

My interview answers are the approval — do not ask again before writing. Apply the draft to the file, then present what changed (as a diff for long documents). Every change must trace to an interview resolution, a verified drift fix, or a mechanical terminology alignment; if while drafting you find yourself making a change nothing covers, that is a missed finding — stop and ask before including it.

## Close-out

After the revision is applied, report:

- **Changed** — drift fixes, decisions folded in, and terminology alignments
- **Still open** — deferred items and why each couldn't be resolved
- **Follow-ups** — ADRs the document now supersedes and that need updating (out of scope here)
- **Residual risks** — anything you would still not bet on being implementable as written

The document is ready when no descriptive claim contradicts the code, no claim contradicts an accepted ADR without the supersession being stated, and no unresolved decision blocks implementation. State plainly whether it is.

</supporting-info>
