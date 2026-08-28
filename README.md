# Elseon: Son of Elsewhere

> "We do not reinvent the wheel; we honor the wheel by giving it a new engine."

Elseon is a systems programming language for environments where precision is
non-negotiable and resources are finite: the Linux kernel and embedded
systems.

The name reads like a Scandinavian designer's surname — literally "son of
elsewhere" — and quietly encodes the project's philosophy: ideas from
elsewhere brought on board. It is playful, minimalist, and carries a subtle
narrative weight.

- This repository is structured for collaborative development with a Large Language Model (LLM).
- This file `README.md` is located at the root of the project structure.

The LLM should begin by reading these files in this order (the numeric prefix marks the load order):

1. `prompts/01-contract.md`
2. `prompts/02-workflow.md`
3. `prompts/03-conventions.md`

- These define the interaction rules, workflow, and formatting conventions.
- The LLM must follow the workflow defined in `prompts/02-workflow.md` for every task.

Human contributors should begin by reading:

- `prompts/README.md`
- `documents/README.md`

Note there are rules meant only to constrain Aider behavior:

- `tools/aider-rules.md` (Aider users only)

All project features are defined in `prompts/features/` and implemented in `sources/`.

## The Language

The Elseon language design and its rationale live in
`documents/07-elseon-language.md`; the requirements are captured as features:

- `prompts/features/03-language-core.md` — core language: philosophy, kernel-ready guarantees, syntax family, and the OOP lessons adopted.
- `prompts/features/04-c-header-ingestion.md` — PFE: C headers as first-class semantic modules.
- `prompts/features/05-llvm-backend.md` — LLVM code generation with deterministic layout.

### Core Principles

1. **PFE (Proudly Found Elsewhere):** we do not waste time re-implementing
   what C has already perfected. C headers are treated as first-class
   semantic modules.
2. **NIH (Not Invented Here) — the inversion:** we do not believe in
   "Not Invented Here." We believe in "Found Elsewhere and Made Better."
   Existing logic is ingested and wrapped in Elseon's safety guarantees.
3. **Kernel-Ready:**
   - No Garbage Collection.
   - No hidden allocations.
   - No hidden control flow.
   - Deterministic memory layout.

The language is similar in form to C and JavaScript to offer minimal
cognitive friction. The compiler uses the LLVM backend for code generation.
The language stays as simple as possible while incorporating the lessons
learned in object-oriented languages since the 1980s: composition over
inheritance, nominal typing, and explicit resource management.

## Top-Level Map

- `README.md` is the project overview.
- `TODO.md` tracks pending and completed project tasks.
- `prompts/` contains LLM interaction rules, common requirements, feature requirements, task definitions, and episode work orders.
- `documents/` contains human-consumption documents: the interaction pattern, worked examples, tool notes, and the language design.
- `records/` contains version-controlled outcome, incident, and handoff records.
- `tools/` contains tool-specific rules.
- `tools/aider-rules.md` is used only with Aider.
- `sources/` contains implementations (the compiler and its libraries).
- `scripts/` contains project scripts.
- `tests/` contains tests and validation code.
- `dataflow.in/` contains input data.
- `dataflow.out/` contains generated data output (not version-controlled).
- `logs/` contains generated logs (not version-controlled).
- `site.in/` contains static-site input.
- `site.out/` contains generated static-site output (not version-controlled).
- `Makefile` drives the build (`make build`), the tests (`make test`), and cleanup (`make clean`).

## Worked Example

The repository includes one worked example that exercises the whole workflow:

- Feature: `prompts/features/01-site-build.md`
- Task: `prompts/tasks/01-site-build-implement.md`
- Script: `scripts/site-build.sh` generates `site.out/` from `site.in/`.
- Tests: `tests/00-skeleton.sh` and `tests/01-site-build.sh`
- Input: `site.in/index.txt` (status page) and `site.in/dashboard.txt`
- Template: `site.in/template.html` provides the HTML page structure.

- Run `make build` to generate the site and `make test` to run the tests.
- The bundled feature is a worked example, not a requirement.
- A new project keeps, trims, or repurposes it; real sites have used a static-site generator instead.

## Project Pages (publishing conventions)

- A project derived from this skeleton publishes the standard page set
  (status, dashboard, condensed todo/prompts/documents) per
  `prompts/features/02-project-pages.md` and
  `documents/06-project-pages.md`.
- `make site` builds the full set (`scripts/site-build.sh` +
  `scripts/site-condense.sh`).
- Publishing goes through the homelab project (homelab-publish): the project
  registers once via `pages_source` and does not push to the web server
  itself — `make deploy` is retired.

## Privacy Boundaries

- This project has no declared privacy boundaries yet.
- The LLM treats any future boundary declared here as an authoritative scope exclusion.

## Canonical Files

The following filenames are canonical and must not be renamed or duplicated without an explicit task:

- `README.md`
- `TODO.md`
- `Makefile`
