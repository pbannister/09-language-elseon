# Elseon: Son of Elsewhere — Language Design

> "We do not reinvent the wheel; we honor the wheel by giving it a new engine."

## 1. The Name

Elseon reads like a Scandinavian designer's surname — literally "son of
elsewhere." It works because it feels like a real name with mythic
undertones, while quietly encoding the project's philosophy: ideas from
elsewhere brought on board. It is playful, minimalist, and carries a subtle
narrative weight.

## 2. The Philosophy

Elseon is a language designed for environments where precision is
non-negotiable and resources are finite: the Linux kernel and embedded
systems.

### Core Principles

1. **PFE (Proudly Found Elsewhere):** we do not waste time re-implementing
   what C has already perfected. C headers are treated as first-class
   semantic modules.
2. **NIH (Not Invented Here) — the inversion:** we do not believe in "Not
   Invented Here." We believe in "Found Elsewhere and Made Better." We
   ingest existing logic and wrap it in Elseon's safety guarantees.
3. **Kernel-Ready:**
   - No garbage collection.
   - No hidden allocations.
   - No hidden control flow.
   - Deterministic memory layout.

### The Kernel Test

Every language feature is admitted only if it passes the Kernel Test:

- **Zero hidden control flow:** no implicit constructors, no hidden
  exceptions, no "magic" behavior. Every branch, every call, every
  allocation is visible in the source.
- **Zero runtime / garbage collection:** no background processes, no
  non-deterministic memory management, no allocator the programmer cannot
  see.
- **Predictable memory layout:** the programmer has absolute control over
  the physical layout of data in memory. Struct layout, padding, alignment,
  and representation are specified by the language and honored by the
  backend.
- **C-compatibility:** Elseon is a "C-cousin" — it interoperates with
  existing C and C++ codebases and is acceptable for kernel-level
  development.

## 3. The Syntax Family

Elseon is similar in form to C and JavaScript, to offer minimal cognitive
friction:

- **From C:** type-first declarations, pointer and array semantics, struct
  layout control, the statement forms, and the mental model of what the
  machine does.
- **From JavaScript:** the brace-and-semicolon statement shape, familiar
  operator precedence, and the readability habits of a generation of
  programmers.

The language must be *as simple as possible* — every feature added beyond
the core has to justify itself against the Kernel Test and against the
simplicity goal. The syntax exists to be boring; the semantics exist to be
safe.

## 4. Lessons from Object-Oriented Languages (1980s onward)

Elseon does not ship classes and inheritance hierarchies. It adopts the
lessons that survived, and rejects the mechanisms that failed:

### Adopted

- **Composition over inheritance.** Deep "is-a" taxonomies are rejected:
  the fragile-base-class problem and the "is-a" fallacy are design bugs,
  not user errors. Capabilities are *composed*, not inherited.
- **Facets (mixins / extension objects).** Functionality is composed from
  small, modular, specialized facets added to a core entity. A facet is a
  named bundle of behavior with no base-class coupling.
- **Nominal typing.** Complexity is managed by naming: type aliases give a
  structural description a semantic, nominal identity. The programmer
  navigates by names, not by nested structural shapes.
- **Interfaces.** Behavior contracts separate *what* an entity offers from
  *how* it is built — but only as compile-time, zero-cost contracts.
- **Explicit resource management.** Destructor-like scopes exist, but they
  are explicit: no hidden control flow at scope exit beyond what the source
  spells out.

### Rejected

- **Inheritance hierarchies** (fragile base classes, hidden dispatch).
- **Implicit constructors/destructors with hidden effects** (hidden control
  flow).
- **Garbage collection** (non-deterministic memory management).
- **Hidden exceptions** (control flow invisible in the source).

## 5. PFE: C Headers as First-Class Semantic Modules

C has perfected an enormous body of interface definitions — the kernel's
own headers are the canonical example. Elseon does not re-declare them; it
*ingests* them.

- A C header imported into Elseon becomes a first-class semantic module:
  types, constants, and function signatures are available with Elseon's
  safety guarantees applied at the boundary.
- The import is a *semantic* operation, not a textual `#include`:
  - types become nominal Elseon types with deterministic layout;
  - constants become typed values;
  - functions become checked call boundaries (arity, type, and
    nullability where the header or annotations make it knowable).
- Existing logic is not re-implemented; it is wrapped. This is the NIH
  inversion made concrete: "Found Elsewhere and Made Better."

Mechanism options (see `prompts/features/04-c-header-ingestion.md`):
libclang, clang AST dumps, or a dedicated C header parser. The kernel
headers are the conformance corpus.

## 6. The Compiler: LLVM Backend

Code generation goes through LLVM.

- The front end (lexer, parser, semantic analysis) is owned by Elseon.
- The backend is LLVM, which already knows every target the kernel cares
  about and applies decades of optimization work Elseon will never need to
  redo — PFE applied to compilers.
- Deterministic layout is a front-end contract: the semantic analysis
  decides representation; the backend is checked (by conformance tests)
  against the promised layout.
- The toolchain must be kernel-adjacent: buildable with a pinned LLVM, no
  runtime dependency beyond what a kernel build already accepts.

## 7. The Programming Model

Elseon sits between imperative and intent-driven programming:

- The programmer is the *ontological architect*: they define intent — the
  *why* and the *what* — in code that reads like C or JavaScript.
- The compiler is the *semantic translator*: it synthesizes one artifact,
  machine code, from a source that names its semantics explicitly.
- Everything the machine will do is visible in the source. That is the
  contract with the kernel.

## 8. Naming: Semantic-Sort

Identifiers follow the semantic-sort pattern `<domain>_<role>_<purpose>_<variant>`,
ordered from broad meaning to narrow meaning, so the namespace becomes a
searchable, hierarchical index. The rules are defined in
`prompts/flavors/01-semantic-sort-naming.md` and apply to Elseon source,
the compiler's own code, and this repository.

## 9. Status and Next Steps

This document is the seed of phase 1 (language specification). It will grow
worked examples — a driver stub, a ring buffer, an allocator — and the
conformance-test plan that maps every guarantee above to a test.

See `TODO.md` for open questions and the phase plan in `PHASES.md`.
