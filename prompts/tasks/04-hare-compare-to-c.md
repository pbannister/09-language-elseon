# Task: Compare Hare to C

## TASK-DESCRIPTION
Create `documents/15-hare-vs-c.md`.
Study the Hare language and compare it to C using the criteria in
`prompts/common/04-c-comparison-criteria.md`.
Follow the study-note structure defined there exactly, with heading 10
(Evidence) listing the cited sources.
Base the study on primary sources where possible: official documentation,
the language reference, the specification, the repository.
Inspect `documents/08-related-work.md` for the current classification of
Hare (Camp 1: simple, C-like, no memory management required; minimal and
static; for UNIX-like OSes; used to build a real OS) and verify or refine
that classification in the study.
Do not modify `documents/08-related-work.md`; this task creates only
`documents/15-hare-vs-c.md`.

## TASK-OUTPUT
Provide only the complete content of `documents/15-hare-vs-c.md`.
No commentary.

## TASK-CONTEXT
This task is one of five concurrent C-comparison studies (C3, Odin, Hare,
Val, Cake) that feed the synthesis task `prompts/tasks/07-c-comparison-synthesis.md`.
The comparison baseline is C; the aim is to identify what has been tried
before, what worked, and what did not work.
Criteria (authoritative): `prompts/common/04-c-comparison-criteria.md`.
Project principles: the kernel test in `documents/07-elseon-language.md`
(no GC, no hidden allocation, no hidden control flow, deterministic memory
layout; C-compatible ABI).
Existing survey (inspect only): `documents/08-related-work.md`.

## TASK-FILES
- `documents/15-hare-vs-c.md` — new
- `documents/08-related-work.md` — existing (inspect only)
