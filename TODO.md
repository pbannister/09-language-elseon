# TODO

## Open Questions

> Several of these are research questions resolved in Phase 1; the rest are
> design decisions for Phase 2. See `PHASES.md`.

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

## Verify before the next dispatch

* [ ] run the six cases in `evals/` by hand and record the result. The rules
      adoption at `2026-10-22.5` is mechanically verified and behaviorally
      unverified: it is `breaking` for this project, and the two cases most
      exposed are `02-scope-discipline` (authorization replaced prohibition) and
      `05-acceptance-remains-human`. See
      `records/2026-10-22-01-rules-adoption.md`.

## Phase 1 — Research

Research precedes the language specification; its findings feed the open
questions above and the design document `documents/07-elseon-language.md`.

* [x] survey prior attempts at an improved C into `documents/08-related-work.md`;
      exclude Rust (surface representation) and D (GC runtime) as models,
      keep both as idea sources; Go excluded by the same GC standard.
* [ ] episode 1-A study series: five concurrent C-comparison studies (C3,
      Odin, Hare, Val, Cake vs C) plus the synthesis task — see
      `prompts/episodes/02-episode-plan.md` and `prompts/tasks/`.
* [ ] study the target environment: kernel constraints (no GC, no hidden
      allocation, no hidden control flow, deterministic layout) and the
      conformance corpus of C headers that exercise PFE ingestion.
* [ ] study the LLVM toolchain: C API vs. C++ API, static vs. shared linking,
      version to pin, and a CI-verifiable build story.
* [ ] research the OOP lessons: interfaces, facets (mixins as extension
      objects), nominal typing, RAII-like explicit scopes — which to adopt and
      which to reject as hidden control flow.

## Phase 2 — Language Specification

* [ ] write the language design document `documents/07-elseon-language.md`
      (philosophy, kernel test, syntax family, OOP lessons) — scaffolded.
* [ ] write the feature files: `03-language-core.md`, `04-c-header-ingestion.md`,
      `05-llvm-backend.md` — scaffolded.
* [ ] write worked example programs (kernel-adjacent: a driver stub, a ring
      buffer, an allocator) to drive out the syntax and semantics.
* [ ] write a conformance-test plan mapped to the kernel test guarantees.
* [ ] adopt the test tiers in `prompts/02-workflow.md`; declare live-state tests
      (kernel-tree compile) and their prerequisites.

## Phase 3 — Toolchain Scaffold

* [ ] create the `elseon` driver (`sources/`), lexer, and parser with
      conformance tests.
* [ ] pin the LLVM toolchain and CI-verifiable version.

## Recently Completed

* [x] scaffold this project from `00-project-skeleton` (2026-08-28):
      philosophy and language-design documents, feature files, site pages,
      phases, and TODO adapted to Elseon.
