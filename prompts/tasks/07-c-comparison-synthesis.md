# Task: Synthesize the C-comparison studies

## TASK-DESCRIPTION
- Create: `documents/18-c-comparison-synthesis.md`
- Modify: `documents/08-related-work.md`
- Inspect: `documents/13-c3-vs-c.md`
- Inspect: `documents/14-odin-vs-c.md`
- Inspect: `documents/15-hare-vs-c.md`
- Inspect: `documents/16-val-vs-c.md`
- Inspect: `documents/17-cake-vs-c.md`
- Inspect: `prompts/11-c-comparison-criteria.md`

Create `documents/18-c-comparison-synthesis.md`.
Read the five study notes: `documents/13-c3-vs-c.md`,
`documents/14-odin-vs-c.md`, `documents/15-hare-vs-c.md`,
`documents/16-val-vs-c.md`, and `documents/17-cake-vs-c.md`.
Produce a synthesis that, across the five candidates:

- compares them on the criteria in
  `prompts/11-c-comparison-criteria.md`;
- states what has been tried before, what worked, and what did not work;
- selects the ideas Elseon should use and the ideas Elseon should avoid,
  each with the reasoning and the source study;
- recommends any candidate to drop from the list, with reasons (the human
  decides);
- proposes revisions to criteria that proved weak or missing, without
  modifying `prompts/11-c-comparison-criteria.md`.

Modify the Status section of `documents/08-related-work.md` to fold in the
deepened findings and reference the study notes and the synthesis.
The synthesis is the input that later informs phase 2 (language
specification).

## TASK-OUTPUT
Provide the complete content of `documents/18-c-comparison-synthesis.md`,
then a short change summary of the modifications made to
`documents/08-related-work.md`.

## TASK-CONTEXT
This task runs after the five concurrent studies; it depends on their
notes existing.
Criteria (authoritative): `prompts/11-c-comparison-criteria.md`.
The synthesis is the deliverable of episode 1-A
(`prompts/episodes/02-episode-plan.md`).

## TASK-FILES

| Operation | Path |
|---|---|
| create | `documents/18-c-comparison-synthesis.md` |
| modify | `documents/08-related-work.md` |
| inspect | `documents/13-c3-vs-c.md` |
| inspect | `documents/14-odin-vs-c.md` |
| inspect | `documents/15-hare-vs-c.md` |
| inspect | `documents/16-val-vs-c.md` |
| inspect | `documents/17-cake-vs-c.md` |
| inspect | `prompts/11-c-comparison-criteria.md` |

## TASK-VERIFY
- Run: `make test` from the repository root.
- Expected: exit status 0.

OUTPUT: the content of `documents/18-c-comparison-synthesis.md`, as TASK-OUTPUT describes, and nothing else.
