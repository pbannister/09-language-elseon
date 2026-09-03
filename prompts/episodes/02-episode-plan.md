# Suggested Episode Plan

This document breaks the phases of `PHASES.md` into a series of suggested
episodes. It is a plan, not a queue: episodes are dispatched by copying the
template (`01-episode-template.md`) into the next free number and filling in
`[SUB-TASKS]` and `[OUTPUT FORMAT]` at dispatch time (see
`prompts/how-to-write-episodes.md` §7 — sub-tasks are drafted by the model
and ratified by the human).

Rules followed:

- One episode, one goal, one acceptance, reviewable in one sitting.
- Every acceptance criterion is a question.
- Riskiest assumption first in `[RISK]`.
- Episode numbering is assigned at dispatch (branches `llm/episode-<n>`).
  Here episodes are named by phase and letter so the plan survives renumbering.

Phase order is a dependency: each phase's episodes are dispatched only after
the previous phase's milestone is met. Within a phase, episodes may be
reordered by the human.

## Phase 1 — Research

### Episode 1-A — Compare candidates to C and synthesize

[EPISODE]
Run the C-comparison study series: five concurrent studies — C3, Odin,
Hare, Val, Cake, each compared to C against the common criteria — then a
synthesis task that selects the ideas to use and the ideas to avoid, to
inform the language specification.

[ACCEPTANCE]
- Does each of the five studies exist (`documents/13-c3-vs-c.md` through
  `documents/17-cake-vs-c.md`) and follow the study-note structure in
  `prompts/common/04-c-comparison-criteria.md`?
- Does the synthesis (`documents/18-c-comparison-synthesis.md`) state what
  has been tried before, what worked, and what did not work, with a
  use/avoid list, candidate-drop recommendations, and proposed criteria
  revisions?
- Are the criteria and the candidate list explicitly reviewed — and
  revised or trimmed if warranted — before the studies are treated as
  final?

[RISK]
- Do the candidates' documentations differ enough that the common criteria
  cannot be answered uniformly, forcing criteria revision mid-series?
- Is the synthesis complete enough to inform phase 2 without re-opening
  the same research?

[SUB-TASKS]
- Establish the common criteria (`prompts/common/04-c-comparison-criteria.md`).
- Dispatch the five studies concurrently (`prompts/tasks/02-c3-compare-to-c.md`
  through `06-cake-compare-to-c.md`).
- Dispatch the synthesis (`prompts/tasks/07-c-comparison-synthesis.md`).
- Review the synthesis and record the outcome in `records/`.

[FILES]
- `prompts/common/04-c-comparison-criteria.md` — new
- `prompts/tasks/02-c3-compare-to-c.md` … `06-cake-compare-to-c.md` — new
- `prompts/tasks/07-c-comparison-synthesis.md` — new
- `documents/13-c3-vs-c.md` … `17-cake-vs-c.md` — new (study notes)
- `documents/18-c-comparison-synthesis.md` — new
- `documents/08-related-work.md` — existing (Status updated by the synthesis)

> The survey work already committed (`documents/08-related-work.md`) is the
> starting evidence; the studies deepen it, and the synthesis folds the
> findings back into it. The candidate list is provisional — the synthesis
> may recommend dropping candidates, and the human decides.

### Episode 1-B — Study the target environment

[EPISODE]
Name the Linux kernel constraints Elseon must honor and the conformance
corpus of C headers that exercise PFE ingestion.

[ACCEPTANCE]
- Is the conformance corpus named (specific `include/linux/*` header
  families) with a rationale tied to each kernel-test guarantee?
- Is every corpus constraint mapped to a kernel-test guarantee (no GC, no
  hidden allocation, no hidden control flow, deterministic layout)?
- Are the findings recorded in a document the specification phase can cite?

[RISK]
- Does the corpus choice presuppose the header-ingestion mechanism that is
  not yet decided, forcing rework in phase 4?

[FILES]
- `documents/10-kernel-conformance-corpus.md` — new

### Episode 1-C — Study the LLVM toolchain

[EPISODE]
Pin the LLVM toolchain approach: C API vs. C++ API, static vs. shared
linking, version, and a CI-verifiable build.

[ACCEPTANCE]
- Is a specific LLVM version named and verified buildable in CI?
- Is the API choice (C vs. C++) decided and justified against the
  kernel-adjacent constraint (no runtime dependency beyond what a kernel
  build accepts)?
- Is the decision recorded where the toolchain-scaffold phase can consume
  it?

[RISK]
- Does the LLVM C API suffice for the planned IR needs, or is the C++ API
  required — a choice that shapes the whole toolchain?

[FILES]
- `documents/11-llvm-toolchain-notes.md` — new

### Episode 1-D — Research the OOP lessons

[EPISODE]
Classify the OOP lessons (interfaces, facets/mixins as extension objects,
nominal typing, RAII-like explicit scopes) as adopt or reject under the
kernel test.

[ACCEPTANCE]
- Is each candidate lesson classified adopt/reject with the kernel-test
  reasoning, including the error-handling tension with "no hidden control
  flow"?
- Is the classification recorded so the specification phase can write from
  it?

[RISK]
- Is any RAII-like scope mechanism compatible with "no hidden control flow"
  at all — the riskiest tension in the language design?

[FILES]
- `documents/12-oop-lessons-notes.md` — new

## Phase 2 — Language specification

### Episode 2-A — Write the language design document

[EPISODE]
Turn the scaffolded `documents/07-elseon-language.md` into the complete
design: philosophy, kernel test, syntax family, memory model, error
handling, and the adopted OOP lessons.

[ACCEPTANCE]
- Does every open question in `TODO.md` have a decided answer in the
  document?
- Is every kernel-test guarantee backed by a concrete mechanism, with the
  syntax family blend (C vs. JavaScript) shown in examples?
- Does the document cite the phase-1 research documents (corpus, LLVM,
  OOP lessons)?

[RISK]
- Does the spec depend on unresolved phase-1 questions (i.e., is phase 2
  starting before the research milestone is complete)?

[FILES]
- `documents/07-elseon-language.md` — existing

### Episode 2-B — Write the feature files

[EPISODE]
Complete the three feature files — `03-language-core.md`,
`04-c-header-ingestion.md`, `05-llvm-backend.md` — as stable requirements
derived from the design document.

[ACCEPTANCE]
- Does each feature state requirements rather than design notes, and cite
  the design document and its research inputs?
- Do the three features together cover every kernel-test guarantee?

[FILES]
- `prompts/features/03-language-core.md` — existing
- `prompts/features/04-c-header-ingestion.md` — existing
- `prompts/features/05-llvm-backend.md` — existing

### Episode 2-C — Write the worked examples

[EPISODE]
Write the worked example programs — a driver stub, a ring buffer, an
allocator — to drive out the syntax and semantics of the specification.

[ACCEPTANCE]
- Do the examples exercise the guarantees (explicit allocation, no hidden
  control flow, deterministic layout) using only the specified syntax?
- Does reviewing them surface any gap in the spec, recorded as a `TODO.md`
  item rather than silently fixed in the examples?

[RISK]
- Without a running toolchain the examples are hand-verified, so the
  examples may drift from what the lexer/parser later accept.

[FILES]
- `sources/examples/driver-stub.esn` — new
- `sources/examples/ring-buffer.esn` — new
- `sources/examples/allocator.esn` — new

### Episode 2-D — Write the conformance-test plan and adopt the tiers

[EPISODE]
Write the conformance-test plan mapping every kernel-test guarantee to
tests, and adopt the test tiers (portable, tool-gated, live-state) in the
workflow.

[ACCEPTANCE]
- Is every kernel-test guarantee mapped to at least one test, and every
  test assigned a tier?
- Do the workflow (`prompts/02-workflow.md`) and the plan declare the
  live-state prerequisites (kernel-tree location, toolchain)?

[FILES]
- `tests/CONFORMANCE.md` — new
- `prompts/02-workflow.md` — existing

## Phase 3 — Toolchain scaffold

### Episode 3-A — Create the `elseon` driver

[EPISODE]
Create the `elseon` driver in `sources/driver/`: argument handling, file
orchestration, and the compile-pipeline skeleton.

[ACCEPTANCE]
- Does `elseon <file>.esn` accept the worked-example files and route them
  to a placeholder backend?
- Do tests cover argument handling and error paths (portable tier)?

[FILES]
- `sources/driver/` — new

### Episode 3-B — Implement the lexer

[EPISODE]
Implement the lexer for the C/JavaScript-shaped syntax family with
conformance tests.

[ACCEPTANCE]
- Does the lexer tokenize every construct appearing in the worked examples?
- Do conformance tests cover the token set and error reporting (portable
  tier)?

[RISK]
- Is the syntax-family blend specified precisely enough to tokenize without
  guessing (dependency on phase 2)?

[FILES]
- `sources/lexer/` — new
- `tests/` — new conformance tests

### Episode 3-C — Implement the parser

[EPISODE]
Implement the parser to an AST with syntax error reporting and conformance
tests.

[ACCEPTANCE]
- Do all worked examples parse to the AST, and are syntax errors reported
  with source location?
- Do the conformance tests pass (portable tier)?

[FILES]
- `sources/parser/` — new
- `tests/` — new conformance tests

### Episode 3-D — Pin the LLVM toolchain in CI

[EPISODE]
Bring the phase-1 LLVM decision to life: pin the version and make the
project CI-verifiable.

[ACCEPTANCE]
- Does the pinned LLVM version build in CI, and is the pin recorded per
  the research notes?
- Is the toolchain's kernel-adjacent constraint (no runtime dependency
  beyond what a kernel build accepts) verified?

[RISK]
- Is the chosen LLVM version available in the CI images?

[FILES]
- CI configuration — new
- `documents/11-llvm-toolchain-notes.md` — existing

## Phase 4 — C-header ingestion (PFE)

### Episode 4-A — Choose and prove the ingestion mechanism

[EPISODE]
Decide and implement the header-ingestion mechanism (libclang, clang AST
dumps, or a dedicated C header parser) and ingest one minimal kernel
header as a semantic module.

[ACCEPTANCE]
- Is the mechanism choice recorded with the rationale from the phase-1
  corpus study?
- Does the chosen mechanism ingest a minimal `include/linux/*` header
  without silent misrepresentation?

[RISK]
- Do kernel headers use constructs the mechanism cannot represent (asm,
  attributes, macros), making the first header uningestible?

[FILES]
- `sources/ingest/` — new
- `tests/` — new tests

### Episode 4-B — First-class semantic modules

[EPISODE]
Represent ingested C headers as first-class semantic modules (types, enums,
structs, functions) consumable by the rest of the compiler.

[ACCEPTANCE]
- Can an Elseon program reference a type or function from an ingested
  header without re-declaring it?
- Are module semantics (namespacing, duplicate/conflict handling)
  specified and tested?

[FILES]
- `sources/sema/` (module representation) — new
- `tests/` — new tests

### Episode 4-C — Ingest the conformance corpus

[EPISODE]
Ingest the phase-1 conformance corpus and verify the guarantees hold across
it.

[ACCEPTANCE]
- Does the corpus subset chosen for this episode ingest without silent
  misrepresentation, each header mapping to a module?
- Are failures triaged into `TODO.md` (carry/defer/drop) rather than
  silently worked around?

[RISK]
- Corpus size: is the subset small enough to review in one sitting?

[FILES]
- `sources/ingest/` — existing
- `tests/` — new tests
- `TODO.md` — existing

## Phase 5 — Semantic analysis and LLVM code generation

### Episode 5-A — Semantic analysis

[EPISODE]
Implement name resolution, nominal typing, facets, explicit scopes, and
the spec's error-handling model.

[ACCEPTANCE]
- Do conformance tests cover type checking and error diagnostics for the
  worked examples and the corpus modules?
- Does the implementation match the spec (nominal types, facets, explicit
  resource management)?

[RISK]
- Does the error-handling model chosen in the spec survive implementation,
  or does it need a spec revision?

[FILES]
- `sources/sema/` — new
- `tests/` — new tests

### Episode 5-B — LLVM IR lowering with deterministic layout

[EPISODE]
Lower core constructs to LLVM IR honoring the spec's deterministic memory
layout.

[ACCEPTANCE]
- Do struct layouts in the generated IR match the spec's layout rules
  (padding, alignment)?
- Does the generated IR contain no hidden allocations or control flow
  beyond what the source spells out (tool-gated tests)?

[FILES]
- `sources/codegen/` — new
- `tests/` — new tool-gated tests

### Episode 5-C — End-to-end conformance

[EPISODE]
Compile the worked examples end-to-end to object files and link against C.

[ACCEPTANCE]
- Do the driver stub, ring buffer, and allocator compile, link against C
  objects, and behave as specified?
- Do the kernel-test audits (no hidden allocation, no hidden control flow)
  pass on the generated IR?

[FILES]
- `sources/codegen/` — existing
- `tests/` — new tests

## Phase 6 — Kernel bring-up

### Episode 6-A — Kernel-adjacent subsystem in Elseon

[EPISODE]
Compile a kernel-adjacent subsystem (the ring buffer or allocator from the
worked examples) as real Elseon code against kernel headers via PFE.

[ACCEPTANCE]
- Does the subsystem compile with the toolchain and ingest its kernel
  headers through the PFE path?
- Do the live-state tests pass against a real kernel tree?

[FILES]
- `sources/` — existing
- `tests/` — new live-state tests

### Episode 6-B — Kernel-test audit

[EPISODE]
Audit the compiled subsystem for no-GC, no-hidden-allocation, and
no-hidden-control-flow, and record the result.

[ACCEPTANCE]
- Does the audit find no violations, or is every violation triaged into
  `TODO.md` as a spec or compiler defect?
- Is the audit outcome recorded in `records/` with a reference to the
  commit?

[FILES]
- `records/` — new record
- `TODO.md` — existing
