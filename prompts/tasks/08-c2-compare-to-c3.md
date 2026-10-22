# Task: Compare C2 to C3

## TASK-DESCRIPTION
- Create: `documents/19-c2-vs-c3.md`
- Inspect: `documents/13-c3-vs-c.md`
- Inspect: `documents/08-related-work.md`
- Inspect: `prompts/11-c-comparison-criteria.md`

Create `documents/19-c2-vs-c3.md`.
Study the C2 language and compare it to C3 using the criteria in
`prompts/11-c-comparison-criteria.md`.
Follow the study-note structure defined there exactly, with heading 10
(Evidence) listing the cited sources.
Use the same ten dimensions as the episode 1-A studies, with C2 and C3
assessed side by side in each dimension; C remains the shared baseline.
Base the study on primary sources where possible: official documentation,
the language reference, the specification, the repository.
Inspect `documents/08-related-work.md` for the current classification of
C2 (Camp 1: fresh C-like design; "Cleaner C") and of C3 (Camp 1;
"probably the closest philosophical sibling to Elseon"), and verify or
refine both classifications in the study.
Inspect `documents/13-c3-vs-c.md` for the completed C3 study, and base
every C3 claim on that note or on its cited primary sources.
Do not modify `documents/08-related-work.md`, `documents/13-c3-vs-c.md`,
or `prompts/11-c-comparison-criteria.md`; this task creates only
`documents/19-c2-vs-c3.md`.

## TASK-OUTPUT
Provide only the complete content of `documents/19-c2-vs-c3.md`.
No commentary.

## TASK-CONTEXT
This task is a follow-on to the episode 1-A C-comparison study series
(C3, Odin, Hare, Val, Cake): C3 is documented as an experimental fork of
C2, so C2 and C3 are one lineage rather than two independent candidates.
The comparison baseline is C; the aim is to identify what has been tried
before, what worked, and what did not work.
Criteria (authoritative): `prompts/11-c-comparison-criteria.md`.
Project principles: the kernel test in `documents/07-elseon-language.md`
(no GC, no hidden allocation, no hidden control flow, deterministic memory
layout; C-compatible ABI).
Existing studies (inspect only): `documents/13-c3-vs-c.md`,
`documents/08-related-work.md`.

## TASK-FILES

| Operation | Path |
|---|---|
| create | `documents/19-c2-vs-c3.md` |
| inspect | `documents/13-c3-vs-c.md` |
| inspect | `documents/08-related-work.md` |
| inspect | `prompts/11-c-comparison-criteria.md` |

## TASK-VERIFY
- Run: `make test` from the repository root.
- Expected: exit status 0.

OUTPUT: the content of `documents/19-c2-vs-c3.md`, as TASK-OUTPUT describes, and nothing else.
