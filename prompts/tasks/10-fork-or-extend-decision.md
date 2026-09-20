# Task: Record the fork-versus-extend decision

## TASK-DESCRIPTION
Create `documents/22-fork-or-extend-decision.md`.
Record the decision analysis for a change of direction: extending an
existing C compiler instead of building a new language from a fresh
front end.
Base the analysis on the inventory in
`documents/21-c-compiler-extensions-inventory.md`.
Cover: why the base question reopened, why a Clang dialect is itself a
new language, the rebase cost as the dominant fork cost, what is
available without forking, a cost-ordered decision ladder, what the
requested features (class methods, constructors, destructors, modules
and exports) cost under the Kernel Test, the contradiction with
`documents/07-elseon-language.md`, the open decisions for the human,
and a recommendation.
Do not modify `documents/07-elseon-language.md` or any other existing
file; this task creates only
`documents/22-fork-or-extend-decision.md`.

## TASK-OUTPUT
Provide only the complete content of
`documents/22-fork-or-extend-decision.md`.
No commentary.

## TASK-CONTEXT
The Kernel Test (no GC, no hidden allocation, no hidden control flow,
deterministic layout) is defined in `documents/07-elseon-language.md` §2.
That document also lists explicit resource management as adopted and
implicit constructors and destructors as rejected, which the requested
feature set contradicts.
`prompts/features/05-llvm-backend.md` asserts that the front end is owned
by Elseon, which an extension strategy replaces with ownership of a
delta.
The recommendation is to prefer fork-free mechanisms until a construct
requires new syntax or new types, and to follow a small localized fork
pattern if a fork becomes necessary.

## TASK-FILES
- `documents/22-fork-or-extend-decision.md` — new
- `documents/21-c-compiler-extensions-inventory.md` — existing (inspect)
- `documents/07-elseon-language.md` — existing (inspect only)
- `documents/19-c2-vs-c3.md` — existing (inspect only)
- `prompts/features/05-llvm-backend.md` — existing (inspect only)
