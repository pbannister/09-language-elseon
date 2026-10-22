# Task: Record scope-exit mechanism details

## TASK-DESCRIPTION
- Create: `documents/24-scope-exit-mechanisms.md`
- Modify: `scope-exit-mechanisms-report.md`

Create `documents/24-scope-exit-mechanisms.md`.
Place the scope-exit mechanism reference in `documents/`, where
human-consumption documents belong, instead of the repository root.
The content records the finer clause-level detail for the four non-C++
scope-exit mechanisms: ISO C `defer` (ISO/IEC TS 25755, draft N3734),
the `__attribute__((cleanup(fn)))` attribute, Objective-C ARC, and
Cforall.
Record its provenance as a research artifact and its relationship to
`documents/23-constructor-destructor-variants.md`, which summarizes the
same mechanisms and is authoritative where the two disagree.
Preserve the confidence and unverified list.
Do not modify any other file; this task relocates and annotates only
`documents/24-scope-exit-mechanisms.md`.

## TASK-OUTPUT
Provide only the complete content of
`documents/24-scope-exit-mechanisms.md`.
No commentary.

## TASK-CONTEXT
The repository structure permits no root-level files other than
`README.md` (see `prompts/01-contract.md` §7), and research documents
belong in `documents/` (see `prompts/03-conventions.md` §2).
The design context is the admissibility boundary in
`documents/22-fork-or-extend-decision.md` §7 and the per-site rulings in
`documents/23-constructor-destructor-variants.md`.
The `defer` mechanism matters to this project because TS 25755 makes it
a statement bound to the innermost block, with jumps into or out of it
constrained, so it registers only a call the programmer wrote.

## TASK-FILES

| Operation | Path |
|---|---|
| create | `documents/24-scope-exit-mechanisms.md` |
| modify | `scope-exit-mechanisms-report.md` |

## TASK-VERIFY
- Run: `make test` from the repository root.
- Expected: exit status 0.

OUTPUT: the content of `documents/24-scope-exit-mechanisms.md`, as TASK-OUTPUT describes, and nothing else.
