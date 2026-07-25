---
name: anneal
description: Decompose a god module into stable and volatile pieces whose boundaries match how the code actually changes. Locates hotspots with the hc CLI (decay-weighted churn × complexity quadrants), autopsies the chosen file along three evidence axes (symbol co-change, consumer slices, internal references), interviews through each proposed seam one at a time, and delivers a strangler-fig migration plan with a measurable hc baseline. Use when a file is a "god module" or "god file", one file soaks up every change, a module needs splitting, or the user wants to isolate hot code or reduce churn concentration.
---

<what-to-do>

Help me carve a god module into pieces whose boundaries match how the code actually changes. Locate the target with hot/cold analysis (or start from the file I name), autopsy it along three independent evidence axes, then interview me through each proposed seam — one question at a time, with your recommended answer — before writing anything. The deliverable is a strangler-fig migration plan with a baseline measurement, written only when I confirm it.

The goal is not "smaller files." It is: dependencies point from volatile to stable, so future churn lands in one quarantined place instead of radiating through the codebase.

</what-to-do>

<supporting-info>

## The heat rule

Decompose along heat, not ugliness. Quadrants come from `hc` (churn × complexity, median-split):

- **hot-critical** — decompose now. Churn keeps landing there, so the payoff is immediate.
- **cold-complex** — leave it alone. It is ugly but costing nothing; refactoring it is risk without payoff. Note it as dormant and revisit only if it warms up.
- **hot-simple** — usually benign (config-like churn). Flag only when consumers are tangled with it.

Never propose work on a cold file just because it looks bad.

## Tooling: hc

[hc](https://github.com/will-wright-eng/hc) computes decay-weighted churn × complexity quadrants with rename tracking, a 14-day file age floor, and a versioned JSON envelope.

- Check `command -v hc`. If missing, offer `go install github.com/will-wright-eng/hc/cmd/hc@latest`.
- If declined or unavailable, use the raw-git fallbacks below and say so — results are coarser (no decay weighting, no rename tracking).
- If the repo has generated/vendored noise, offer to bootstrap `.hcignore` first: run `hc md ignore`, fulfill the emitted prompt yourself, and confirm the content with me before writing the file.

## Phase 1: locate

If I named a file, still run the analysis — it supplies the baseline and shows where the file sits in the repo's distribution. If I didn't, rank candidates:

```sh
hc analyze --json > /tmp/hotspots.json
jq -r '.files[] | select(.quadrant == "hot-critical")
  | [.path, .weighted_commits, .complexity, .lines, .authors] | @tsv' /tmp/hotspots.json
```

Present the shortlist with **absolute numbers alongside the quadrant label**. Quadrants are relative to the repo's own median — in a repo where everything churns, half the files are "cold" by construction, so the label alone can mislead. A hot-critical file with a single author is also a knowledge silo; say so.

Ask which file to autopsy (one question), unless I already named it.

## Phase 2: history hygiene

Co-change evidence is only as good as the commit history. Measure before trusting it:

```sh
git log --pretty=format:'@%H' --name-only | awk '/^@/{if(n)print n;n=0;next}/./{n++}END{print n}' | sort -n
```

If the median files-per-commit is large or the history is dominated by giant "checkpoint" commits (common in vibe-coded repos), down-weight the co-change axis, lean on consumer slices and the internal graph instead, and tell me you did.

## Phase 3: autopsy

Three independent evidence axes over the target file. **Propose a cut only where at least two axes agree**; disagreements become interview questions, not proposals.

1. **Symbol co-change** — cluster the file's functions/classes by which commits touch them:

    ```sh
    git log --format=%H -L ':symbolName:path/to/file' | grep -E '^[0-9a-f]{40}$'
    ```

    Run per symbol (fall back to `-L start,end:file` line ranges where funcname detection fails), then cluster symbols by commit-set overlap. Skip commits touching more than ~50 files — mass renames and format-everything commits couple everything to everything. The cluster appearing in the most recent commits is the hot core; symbols untouched for months are the stable core.

2. **Consumer slices** — for each exported symbol, grep which files use it (excluding the module itself). God modules almost always serve several disjoint consumer sets; each disjoint set is a free seam.

3. **Internal reference graph** — which symbols inside the file call each other. Weakly-connected components are cheap cuts; the tangled center is where interview effort goes.

If hc ships `--coupling` ([proposal 012](https://github.com/will-wright-eng/hc/blob/main/docs/proposals/012-change-coupling.md)), use it for the file-level co-change partners. Until then, the pair-count fallback below.

## Phase 4: interview

Work through proposed seams one question at a time, waiting for my answer, recommendation stated first:

- For each seam: the evidence (which axes agree), the symbols on each side, and the question — **is this coupling essential or incidental?** Co-change data lies (formatting sweeps, shotgun refactors), so my confirmation is the filter.
- Name proposed pieces with the domain vocabulary in `CONTEXT.md` if present; describe the architecture with the vocabulary in [LANGUAGE.md](../improve-codebase-architecture/LANGUAGE.md) — deep/shallow, seam, locality, leverage. The stable core should come out **deep**: a lot of behavior behind a small interface.
- If a question can be answered by exploring the codebase, explore instead of asking.
- If I reject a seam with a load-bearing reason, offer to record it as an ADR (see [ADR-FORMAT.md](../grill-with-docs/ADR-FORMAT.md)) so a future session doesn't re-propose it. Skip ephemeral reasons.

Collect resolutions as we go; write nothing yet.

## Phase 5: plan

When every seam is resolved, propose the plan document — default path `docs/plans/anneal-<module>.md`, confirm path and content before writing. It contains:

- **Baseline** — the target's row from the hc envelope (weighted commits, complexity, lines, authors, quadrant) plus the repo thresholds, dated.
- **Target decomposition** — each piece: name, the symbols it takes, its interface, and its expected temperature (which piece stays hot by design).
- **Migration order** — strangler-fig: introduce the interface at the seam → redirect consumers one slice at a time → move symbols → delete from the god module. Each step sized to a reviewable PR; dependencies point from volatile to stable at every intermediate state.
- **Done definition** — see below.

## Measuring success

After slices land, re-measure:

```sh
hc analyze --json --no-min-age --files-from new-files.txt
```

`--files-from` shrinks the rows but thresholds stay computed on the full corpus — exactly right here. `--no-min-age` is required: freshly split files are otherwise excluded by the 14-day age floor, and are mechanically "cold" under the median split regardless — treat early post-split numbers as provisional and say so.

The refactor worked when: the volatile extract stays hot but its churn no longer co-changes with the stable core; the stable core drifts cold; and if the repo runs hc's PR annotations, the hot-critical warnings stop firing on PRs that used to trip them.

## Raw-git fallbacks (no hc)

- **Churn ranking** (no decay, no rename tracking):

    ```sh
    git log --since="12 months ago" --name-only --pretty=format: | grep . | sort | uniq -c | sort -rn | head -30
    ```

    Cross with `wc -l` as the complexity proxy and note the method downgrade.

- **File-level co-change partners** — group `git log --name-only --pretty=format:'@%H'` output per commit, skip commits with >50 files, count pairs involving the target. Mirror hc proposal 012's floors: keep pairs with support ≥ 5 and confidence ≥ 0.5 (co-changes ÷ target's total changes).

## References

- Adam Tornhill, *Your Code as a Crime Scene* — hotspots, temporal coupling, the heat rule.
- John Ousterhout, *A Philosophy of Software Design* — deep modules; basis of LANGUAGE.md.
- Robert Martin, component principles — Common Closure (things that change together stay together), Stable Dependencies (depend toward stability).
- [will-wright-eng/hc](https://github.com/will-wright-eng/hc) — hot/cold analysis CLI; JSON envelope schema in `internal/schema`.

</supporting-info>
