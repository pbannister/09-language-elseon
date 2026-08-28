# Feature: Language Core

## Purpose

Elseon is a systems programming language for environments where precision
is non-negotiable and resources are finite: the Linux kernel and embedded
systems. The Language Core feature defines the philosophy, the
kernel-ready guarantees, the syntax family, and the object-oriented lessons
adopted.

The design rationale lives in `documents/07-elseon-language.md`; this
feature states the requirements the language (and every future compiler
stage) must satisfy.

## Requirements

### Philosophy

- The language must follow PFE (Proudly Found Elsewhere): C headers are
  first-class semantic modules, not textual includes to be re-declared.
- The language must follow the NIH inversion: existing logic is ingested
  and wrapped in Elseon's safety guarantees, never silently re-implemented.

### Kernel Test

Every language feature must pass the Kernel Test:

- **No garbage collection:** no runtime collector, no non-deterministic
  memory management.
- **No hidden allocations:** every allocation is visible in the source;
  the allocator is explicit.
- **No hidden control flow:** no implicit constructors, no hidden
  exceptions, no magic behavior; every branch, call, and allocation is
  visible in the source.
- **Deterministic memory layout:** the programmer controls struct layout,
  padding, alignment, and representation; the language specifies the layout
  rules and the backend honors them.
- **C-compatibility:** Elseon must interoperate with existing C and C++
  codebases and be acceptable for kernel-level development.

### Syntax Family

- The language must be similar in form to C and JavaScript to offer minimal
  cognitive friction:
  - from C: type-first declarations, pointer and array semantics, struct
    layout control, the statement forms;
  - from JavaScript: the brace-and-semicolon statement shape and familiar
    operator precedence.
- The language must be as simple as possible: every feature beyond the core
  must justify itself against the Kernel Test and against the simplicity
  goal.

### Object-Oriented Lessons

The language must adopt the lessons learned in object-oriented languages
since the 1980s, without their failures:

- Composition over inheritance: deep "is-a" hierarchies, the fragile-base-
  class problem, and the "is-a" fallacy are rejected.
- Facets (mixins / extension objects): capability is composed from small,
  modular, specialized facets added to a core entity, with no base-class
  coupling.
- Nominal typing: type aliases give structural descriptions semantic,
  nominal identity; programmers navigate by names.
- Interfaces: compile-time, zero-cost behavior contracts.
- Explicit resource management: destructor-like scopes exist but are
  explicit; no hidden control flow at scope exit.

The language must reject: inheritance hierarchies, implicit
constructors/destructors with hidden effects, garbage collection, and
hidden exceptions.

## Behavior

- A conformance-test plan must map every guarantee above to at least one
  test (see the test tiers in `prompts/02-workflow.md`).
- Worked example programs (a driver stub, a ring buffer, an allocator) must
  demonstrate the guarantees in source form.

## Dependencies

- None (foundational feature).
