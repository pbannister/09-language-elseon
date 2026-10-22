# Feature: LLVM Backend

## Purpose

Code generation goes through LLVM: the front end (lexer, parser, semantic
analysis) is owned by Elseon; the backend is LLVM, which already knows
every target the kernel cares about and applies decades of optimization
work Elseon will never need to redo — PFE applied to compilers.

## Requirements

- `LLVM-R001` — The compiler must lower Elseon through LLVM for code generation.
- `LLVM-R002` — Deterministic memory layout is a front-end contract: semantic analysis
  decides representation; conformance tests check the backend against the
  promised layout (struct layout, padding, alignment).
- `LLVM-R003` — The generated code must satisfy the Kernel Test: no runtime, no GC, no
  hidden allocations, no hidden control flow beyond what the source spells
  out.
- `LLVM-R004` — The toolchain must be kernel-adjacent: buildable with a pinned LLVM
  version, with no runtime dependency beyond what a kernel build already
  accepts.
- `LLVM-R005` — The LLVM version and the API choice (C API vs. C++ API; static vs.
  shared linking) must be pinned and recorded in the project.
- `LLVM-R006` — The `elseon` driver and toolchain live in `sources/`; `make build` builds
  them from phase 3 onward (site build remains part of `make site`).

## Behavior

- A conformance test must compile an Elseon program to an object file with
  the pinned LLVM and link it against a C program, verifying layout and
  call boundaries.
- A live-state test (per the test tiers in `prompts/02-workflow.md`) must
  compile a kernel-adjacent subsystem and report PASS/WARN/FAIL against the
  declared prerequisites.

## Dependencies

- Feature `03-language-core.md` (Language Core) — the Kernel Test
  guarantees the backend must honor.
- Feature `04-c-header-ingestion.md` (C-Header Ingestion) — the checked
  call boundaries the backend must lower.
