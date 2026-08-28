# Phases

Project work proceeds in numbered phases. A phase is a milestone that
groups one or more episodes (the reviewable work units; see
`prompts/how-to-write-episodes.md` §9 and the homelab project-pages
conventions `documents/09-project-pages-conventions.md` §6).

**Change the current phase only when committing the project** (owner rule
2026-08-26): the phase belongs to this project, not to the homelab
registry. The homelab reads it from the generated `site.out/phase.txt`
(emitted by `scripts/site-condense.sh` from the `Current:` line below) and
shows it next to the activity status (active/planned/deferred/complete),
which the human declares in the homelab registry.

Current: phase 1 — started

- Phase 1 — Language specification: philosophy, kernel-ready guarantees,
  syntax family, and OOP lessons written down in
  `documents/07-elseon-language.md` and the feature files; scaffold
  committed — started
- Phase 2 — Toolchain scaffold: `elseon` driver, lexer and parser with
  conformance tests; LLVM toolchain pinned — not-started
- Phase 3 — C-header ingestion (PFE): C headers imported as first-class
  semantic modules — not-started
- Phase 4 — Semantic analysis and LLVM code generation with deterministic
  memory layout — not-started
- Phase 5 — Kernel bring-up: compile a kernel-adjacent subsystem in Elseon;
  audit for no-GC, no-hidden-allocation, no-hidden-control-flow — not-started

States: `not-started` | `started` | `complete`. Keep this file in sync
with the episodes that advance each phase and with `TODO.md`.
