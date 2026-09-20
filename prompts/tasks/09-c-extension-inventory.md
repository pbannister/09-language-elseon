# Task: Inventory prior work on extending C compilers

## TASK-DESCRIPTION
Create `documents/21-c-compiler-extensions-inventory.md`.
Place the research inventory produced during the fork-versus-extend
investigation in the `documents/` directory, where human-consumption
documents belong, instead of the repository root.
The content is an inventory of prior work on extending or modifying C
compilers, covering: extensions already in mainstream compilers, real
forked or modified C compilers, Objective-C as a frontend-plus-runtime
precedent, attempts to add classes, methods, constructors, and RAII
directly to C, compiler-fork maintenance burden, and Clang plugin limits.
Record the provenance of the file and mark unverified claims explicitly.
Correct the defer findings against primary sources: Clang documents
`-fdefer-ts` in its released 22.1.0 and 23.1.0 command-line references,
so Clang support is verified rather than unverified; GCC's merge status
remains unverified.
Do not modify any other file; this task relocates and corrects only
`documents/21-c-compiler-extensions-inventory.md`.

## TASK-OUTPUT
Provide only the complete content of
`documents/21-c-compiler-extensions-inventory.md`.
No commentary.

## TASK-CONTEXT
The inventory was produced by a research subagent at the repository root
during the investigation of whether to extend an existing C compiler
rather than build a fresh front end.
The repository structure permits no root-level files other than
`README.md` (see `prompts/01-contract.md` §7), and research documents
belong in `documents/` (see `prompts/03-conventions.md` §2).
The decision this inventory feeds is
`documents/22-fork-or-extend-decision.md`.
Primary sources for the defer correction:
`https://releases.llvm.org/22.1.0/tools/clang/docs/ClangCommandLineReference.html`
and
`https://releases.llvm.org/23.1.0/tools/clang/docs/ClangCommandLineReference.html`.

## TASK-FILES
- `documents/21-c-compiler-extensions-inventory.md` — new (relocated)
- `c-compiler-extensions-inventory.md` — existing (delete from root)
