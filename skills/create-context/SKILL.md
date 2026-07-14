---
name: create-context
description: Build or refine a CONTEXT.md glossary through a question/answer session. Explores the codebase for candidate domain terms, then confirms each term, relationship, and ambiguity with the user one at a time — writing to CONTEXT.md only on confirmation. Use when a project's ubiquitous language needs capturing, or an existing CONTEXT.md needs auditing.
---

<what-to-do>

Build (or refine) this project's `CONTEXT.md` with me. Explore the codebase first to assemble a candidate term list, then interview me through it one item at a time — proposing a canonical name, a one-sentence definition, and aliases to avoid, with your recommendation stated for each.

Modify `CONTEXT.md` only when I confirm an item or we agree the language has been properly decomposed. Never write unconfirmed material into the file.

</what-to-do>

<supporting-info>

## Which file

Follow the single/multi-context conventions in [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md):

- `CONTEXT-MAP.md` at the root → multiple contexts; ask which context the session covers if it isn't obvious
- root `CONTEXT.md` only → single context
- neither → single context; create `CONTEXT.md` lazily when the first term is confirmed

If a `CONTEXT.md` already exists, read it before exploring. The session then covers both gaps (concepts in the code but missing from the glossary) and staleness (entries that no longer match the code or that I contradict when questioned).

## Phase 1: explore

Before asking anything, explore the codebase for raw material:

- entity, model, and type names; database tables; API resources
- module and directory boundaries
- competing synonyms — the same concept under different names (`user` vs `account` vs `customer`)
- overloaded terms — one name carrying two meanings in different places

Build the candidate list from this. General programming concepts (timeouts, retries, error types, utility patterns) are not candidates — only concepts specific to this project's domain qualify, per CONTEXT-FORMAT.md.

## Phase 2: decompose the language

Work through the candidates one at a time, waiting for my verdict before continuing. For each term propose:

- the canonical name — with your recommendation when the code uses several
- a one-sentence definition — what it IS, not what it does
- the aliases to avoid
- the code evidence supporting (or contradicting) your proposal

Challenge me while we work:

- If I use a term loosely, sharpen it: "You're saying 'account' — do you mean the Customer or the User?"
- If my definition conflicts with the code, surface the contradiction with evidence.
- If two candidates might be one concept — or one candidate is hiding two — probe with a concrete scenario until the boundary is crisp.

A term is done when its name, definition, and avoid-list are confirmed. Write it into `CONTEXT.md` at that moment — never earlier, never batched.

## Phase 3: relationships, ambiguities, dialogue

Once the glossary stabilises:

- **Relationships** — propose them one at a time from what the code shows, with cardinality where obvious; confirm each before writing.
- **Flagged ambiguities** — anything from phase 2 that stayed unresolved, or whose resolution is worth recording. Confirm the wording.
- **Example dialogue** — draft last, once terms and relationships are settled. It should demonstrate the boundaries between the trickiest neighbouring concepts. Confirm before writing.

## Rules

- One question at a time. Always state your recommended answer.
- If a question can be answered by exploring the codebase, explore instead of asking.
- `CONTEXT.md` stays a glossary: no implementation details, no specs, no decisions. Decisions belong in ADRs, not here.
- Follow the structure and rules in CONTEXT-FORMAT.md exactly.

</supporting-info>
