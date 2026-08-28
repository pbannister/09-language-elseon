# TODO

## Open Questions

* [ ] decide the exact syntax family blend: how far toward JavaScript (braces,
      statement forms, `let`/`const`) and how far toward C (type-first
      declarations, pointer syntax, preprocessor-adjacent idioms) does Elseon go?
* [ ] decide the error-handling model: with "no hidden control flow", errors must
      surface explicitly — error values, tagged returns, or explicit result types?
      (This is the one OOP lesson most in tension with the kernel test.)
* [ ] decide the memory model: arena/linear allocation and explicit lifetimes vs.
      stack-only by default; how ownership moves are spelled.
* [ ] decide the mechanism for C-header ingestion: libclang, clang AST dumps, or a
      dedicated C header parser; which kernel headers are the conformance corpus.
* [ ] decide which OOP lessons to adopt beyond composition-over-inheritance:
      interfaces, facets (mixins as extension objects), nominal typing, RAII-like
      explicit scopes — and which to reject as hidden control flow.
* [ ] pin the LLVM version and the build story (LLVM C API vs. C++ API, static vs.
      shared linking) for a kernel-adjacent toolchain.
* [ ] decide the conformance-test tiering: portable tests, tool-gated tests
      (require LLVM), and live-state tests (compile against a real kernel tree).

## Phase 1 — Language Specification

* [ ] write the language design document `documents/07-elseon-language.md`
      (philosophy, kernel test, syntax family, OOP lessons) — scaffolded.
* [ ] write the feature files: `03-language-core.md`, `04-c-header-ingestion.md`,
      `05-llvm-backend.md` — scaffolded.
* [ ] write worked example programs (kernel-adjacent: a driver stub, a ring
      buffer, an allocator) to drive out the syntax and semantics.
* [ ] write a conformance-test plan mapped to the kernel test guarantees.
* [ ] adopt the test tiers in `prompts/02-workflow.md`; declare live-state tests
      (kernel-tree compile) and their prerequisites.

## Phase 2 — Toolchain Scaffold

* [ ] create the `elseon` driver (`sources/`), lexer, and parser with
      conformance tests.
* [ ] pin the LLVM toolchain and CI-verifiable version.

## Recently Completed

* [x] scaffold this project from `00-project-skeleton` (2026-08-28):
      philosophy and language-design documents, feature files, site pages,
      phases, and TODO adapted to Elseon.
