# sources — the Elseon toolchain

This directory will hold the `elseon` compiler and its libraries.

The language design is in `documents/07-elseon-language.md`; the
requirements are the language features in `prompts/features/`
(`03-language-core.md`, `04-c-header-ingestion.md`, `05-llvm-backend.md`).

## Pinned LLVM Base

Elseon starts from Clang rather than a fresh front end; see
`documents/22-fork-or-extend-decision.md`.

- Pinned base: `llvmorg-23.1.1`, the newest upstream release at pin time.
- Build automation: `scripts/llvm-build.sh`, with the modes `check`,
  `source`, `configure`, `build`, `all`, and `status`.
- Upstream checkout: `sources/llvm-project/`, not version-controlled.
- Generated build tree: `dataflow.out/llvm-build/`, not version-controlled.
- Rebuild: `sh scripts/llvm-build.sh build`.
- Other ninja targets: `ninja -C dataflow.out/llvm-build` (for example
  `check-clang` or `opt`).

The pin lives in `VERSION_LLVM_PIN` in `scripts/llvm-build.sh`, and the
tool-gated test `tests/03-llvm-build.sh` checks this file against it.

## Planned Layout (phase 3 onward)

- `driver/` — the `elseon` command: argument handling, file orchestration,
  and the compile pipeline driver.
- `lexer/` — tokenization of the C/JavaScript-shaped syntax family.
- `parser/` — parsing to an AST; syntax error reporting.
- `sema/` — semantic analysis: name resolution, nominal types, facets,
  interfaces, and the deterministic-layout contract.
- `cimport/` — the C-header ingestion module (PFE): mechanism TBD
  (libclang, clang AST dumps, or a dedicated parser); see
  `prompts/features/04-c-header-ingestion.md`.
- `codegen/` — the LLVM backend; deterministic layout checks
  (see `prompts/features/05-llvm-backend.md`).
- `tests/` — conformance tests mapped to the Kernel Test guarantees (the
  project's `tests/` directory keeps the repository-level tests).

The layout is a plan, not a commitment: the first implementation episode
may revise it (see the phases in `PHASES.md` and the open questions in
`TODO.md`).
