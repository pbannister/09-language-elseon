# sources — the Elseon toolchain

This directory will hold the `elseon` compiler and its libraries.

The language design is in `documents/07-elseon-language.md`; the
requirements are the language features in `prompts/features/`
(`03-language-core.md`, `04-c-header-ingestion.md`, `05-llvm-backend.md`).

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
