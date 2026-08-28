# Feature: C-Header Ingestion (PFE)

## Purpose

PFE (Proudly Found Elsewhere): C has perfected an enormous body of
interface definitions — the Linux kernel's own headers are the canonical
corpus. Elseon must not re-declare them; it must *ingest* them. A C header
imported into Elseon becomes a first-class semantic module, with Elseon's
safety guarantees applied at the boundary.

## Requirements

- The language must provide an import form for C headers that is a
  *semantic* operation, not a textual `#include`.
- An imported header must expose, with Elseon semantics:
  - types, as nominal Elseon types with deterministic layout;
  - constants, as typed values;
  - function signatures, as checked call boundaries (arity, types, and
    nullability where the header or annotations make it knowable).
- The import must not require hand-written mirror declarations: Elseon
  uses the header as the single source of truth.
- The import boundary must be checked: mismatches between an Elseon call
  and the C signature must be compile-time errors.
- The mechanism must handle the kernel header corpus (including its
  preprocessor idiom: macros, conditional compilation, `__attribute__`,
  and type re-export chains) with a declared conformance subset.

## Behavior

- The mechanism choice (libclang, clang AST dumps, or a dedicated C header
  parser) is recorded in the design document and TODO; the kernel headers
  are the conformance corpus.
- A conformance test must compile at least one real kernel-adjacent header
  and call one of its functions from Elseon, verifying the checked
  boundary.

## Dependencies

- Feature `03-language-core.md` (Language Core) — the import boundary must
  satisfy the Kernel Test (no hidden allocations, deterministic layout).
