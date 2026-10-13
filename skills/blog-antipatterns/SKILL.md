---
name: blog-antipatterns
description: Review a markdown software blog post against Michael Lynch's "Anti-Patterns in Software Blogging" — the meandering intro and preamble, assuming the reader knows what you know, overreliance on links, the sequel injection bug, excessive formality, and fumbled HTML basics (mobile overflow, unreadable text). Names the post's reference reader first, then reports each finding with its line, the rule it breaks, and a paste-ready rewrite; rendering issues markdown can't settle become targeted manual checks. Read-only — never edits the post. Use when a blog post or draft article needs reviewing before publishing — "review my blog post", "critique this draft", "check this post for blogging anti-patterns", "is this post ready to publish".
argument-hint: "<path-to-post.md>"
---

<what-to-do>

Review the markdown blog post I point you at against the six anti-patterns in Michael Lynch's "Anti-Patterns in Software Blogging": the meandering intro (preamble included), assuming the reader knows what you know, overreliance on links, the sequel injection bug, excessive formality, and fumbling the basics of rendering HTML. Read the whole post, name the reader it's written for, then check every rule and report each finding with its line, the quoted text, why it breaks the rule for that reader, and a concrete rewrite. Rendering rules that markdown can't settle become specific manual checks, never a pass. Don't edit the post — the report is the deliverable. If I ask for fixes afterwards, apply only the ones I pick.

</what-to-do>

<supporting-info>

## Input

One argument: the path to a markdown post (`.md`, `.mdx`, `.markdown`). If invoked without one, ask for it before doing anything else.

Separate what the reader reads from what they don't:

- **Title** — the frontmatter `title:`, else the first H1
- **Preamble** — a frontmatter `subtitle:` (themes usually render it under the title) and anything in the body before the first sentence of the intro
- **Prose** — rendered body text, excluding frontmatter, code blocks, and text quoted from other people

The prose rules (1–5) judge prose only. The rendering rule (6) judges everything that renders, code blocks included.

## Name the reference reader first

The article's method for catching assumed knowledge is to picture a real person in the target audience. Before checking anything, infer that person from the title, intro, and tags, and write them down as someone specific: "a web developer who writes Python daily and has never used Docker", not "developers". Every judgment below — what needs defining, what a link must summarize, what the intro must signal — is relative to this reader. Put the reader at the top of the report so I can correct it; if I do, re-run rules 1–3.

If the post gives no signal of who it's for, that is itself a rule 1 finding: pick the most plausible reader, say so, and continue.

## The rules

Check them in this order. The article calls the meandering intro the most common mistake by far.

### 1. The meandering intro

Readers decide from the title and the first three sentences whether to keep reading. Those must answer both:

- **Is this for someone like me?** — an explicit or unmistakable audience signal: a language, a role, a problem the reader has
- **How will I benefit?** — a concrete payoff: a technique they'll learn, a concept they'll understand, a new perspective, or an entertaining story or rant

Quote the title and first three sentences in the report and mark each question answered or not. Fail the rule when either answer is missing there, and give the line where it finally appears, if it does. Backstory, history, and "how I got here" ahead of the payoff are the usual culprits. Write a replacement opening that leads with the post's own payoff. The article's model: "There's an excellent Go testing pattern that too few people know. I can teach it to you in 30 seconds."

**Preamble** — list everything between the title and the intro's first sentence: subtitle, author bio, hero image, epigraph or famous quote, disclaimer, series banner. None is forbidden, but each spends the reader's attention before the intro has earned it. Recommend cutting, or moving below the intro, anything that doesn't help the reader decide to keep going.

### 2. Assuming the reader knows what you know

Terms that feel obvious to the writer are often new to the reader. Using the reference reader:

1. Collect every technical term, acronym, tool, and concept name in the prose.
2. Sort them into terms the reference reader would recognize and terms they wouldn't. Put both lists in the report. The article finds that comparing such a list against the draft is where most assumptions show up.
3. At each unfamiliar term's first use, check that the post explains it there or earlier: a short definition, or better, a comparison to something the reader already knows ("Jellyfin is a streaming service like Netflix, except it's open-source and private").

Flag every unfamiliar term left unexplained at first use, and write the sentence to add. A definition built from other unfamiliar terms doesn't count: "Docker is a slick frontend to Linux cgroups" explains nothing to a reader who doesn't know cgroups. A link isn't a definition either; that falls under rule 3. Don't flag terms the reference reader already knows, because defining basics for an expert audience is just padding.

### 3. Overreliance on links

The reader should be able to read the post start to finish without clicking a link or hovering for a tooltip. For every link, ask: if you deleted it, would the reference reader still understand the sentence and everything after it?

- **Fails** — the link does explaining the post needs: "assign [firewall rules](…)" for a reader who doesn't know what a firewall is, or "see this post for how it works" when how it works matters. Write the minimal summary to put in the post. The link can stay as a bonus.
- **Passes** — the link is extra: a source, an attribution, further reading for readers who want depth

Explanations hidden in hover text, such as link titles (`[term](url "explanation")`) and `<abbr title="…">`, fail the same test. Don't open the links. The question is whether the post stands on its own without them.

### 4. The sequel injection bug

Most readers haven't read the previous post. Flag:

- an opening (title, preamble, or first paragraph) that presents the post as a follow-up: "Part 2", "In part one, we…", "Last time I…", "As promised in my previous post…"
- anywhere in the post: a term, setup, or result that the post depends on but only an earlier post explains

Referring to earlier posts later on is fine when the post summarizes what's relevant. The fix is that summary: write the one or two sentences that make the post standalone, and move the back-reference out of the opening. Only a genuinely multi-part project (say, a hobby OS built from scratch) earns a series framing, and even then each part needs its own recap.

### 5. Excessive formality

Software readers want you to write the way you talk, not like a legal document. Flag stiff prose:

- passive voice that hides who did it ("tools were utilized by my teammates and myself")
- inflated words where plain ones work: utilize, leverage, facilitate, in order to, prior to, throughout the duration of
- nominalizations that bury the verb ("perform an analysis of" instead of "analyze")
- dodging "I" or "we": "the author", "myself" as a subject
- bland, generic prose with no voice. The article singles out writing delegated to AI as what makes blogs sound alike.

Quote each instance and rewrite it the way you'd say it to a colleague. The article's model: "Several static analysis tools were utilized by my teammates and myself throughout the duration of this project's lifetime." becomes "We tried a few static analyzers on this project." When a pattern repeats, report the worst few instances and give a count instead of listing every one. Casual doesn't mean vague: keep precision, and don't treat technical terms as formality.

### 6. Fumbling the basics of rendering HTML

The theme's CSS decides how the post renders, and markdown can't show that. So this rule yields flags and manual checks, never a pass.

**Page overflow on mobile.** Forcing mobile readers to scroll sideways is the worst rendering failure. Flag its causes in the source:

- code blocks with lines over 80 characters. Report each block's line and longest line length. A phone fits roughly 40 monospace characters, so depending on the theme these either overflow the page or scroll sideways inside the block. Suggest rewrapping.
- wide tables: many columns or long cell content
- raw HTML with fixed widths: `width="…"` on `<img>`, `<iframe>`, `<video>`, or `<table>`, or an inline `style` with a pixel width
- long strings in prose that can't wrap: bare URLs, long paths or identifiers in inline code

**Unreadable text.** Flag inline HTML that sets text color, background, or font family. Body font and contrast live in the theme. If the post sits in a site repo whose theme CSS you can read, compute body text color against its background (WCAG AA requires 4.5:1) and flag dark gray on light gray. Otherwise, contrast is a manual check.

**Manual checks.** Always end this rule with these, pointing at the specific elements flagged above:

- Preview the post at phone width (Firefox Responsive Design Mode or Chrome's device toolbar) and scroll the whole thing. Nothing should need horizontal scrolling.
- Run the browser's contrast checker (Firefox's Accessibility Inspector, or Chrome DevTools / Lighthouse) on body text, links, code, and captions.
- If the font itself is hard to read, the article suggests Atkinson Hyperlegible, a free font from the Braille Institute.

## Calibration

The failure mode is a wall of nitpicks that buries the one fix that matters. Report a finding only when the reference reader would stop reading over it, misunderstand because of it, or leave the page because of it. Advice beyond these six rules is out of scope: no grammar, no spelling, and no structure suggestions the article doesn't make.

## Report

Start with a scorecard, then give findings in rule order:

```markdown
# Blog review: <title>

**Reference reader:** <specific person>, inferred from <evidence in the post>
**Verdict:** <ready to publish | N findings to fix>; <M manual checks>

| # | Anti-pattern | Result | Findings |
| --- | --- | --- | --- |
| 1 | Meandering intro | Fail | 2 |
| 2 | Assumed knowledge | Pass | 0 |
| 3 | Overreliance on links | Fail | 1 |
| 4 | Sequel injection | Pass | 0 |
| 5 | Excessive formality | Fail | 3 (11 instances) |
| 6 | HTML basics | Check manually | 2 flags |
```

Each finding gives:

- **`path:line`**: the quoted excerpt
- **Why**: the rule it breaks, in one sentence, for the reference reader
- **Fix**: the concrete rewrite, ready to paste, not "consider clarifying"

Rule 1 always shows the quoted title and first three sentences with both answers marked. Rule 2 always shows the two term lists. "Ready to publish" means no rule fails, although the manual checks still apply. End with the three fixes that would most improve the post, ranked by impact.

## References

- Michael Lynch, ["Anti-Patterns in Software Blogging"](https://refactoringenglish.com/blog/anti-patterns-software-blogging/), Refactoring English, October 7, 2026
- W3C, [Understanding SC 1.4.3: Contrast (Minimum)](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)
- Braille Institute, [Atkinson Hyperlegible](https://www.brailleinstitute.org/freefont/)

</supporting-info>
