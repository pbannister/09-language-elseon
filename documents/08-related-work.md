# Related Work: Attempts at an Improved C

> PFE in action: before designing Elseon, survey the attempts that came
> before, take the ideas, and leave the rest.

This document surveys existing attempts at an improved modern version of C.
It is a living knowledge document: it records what was tried, what
converged, and what Elseon can borrow.

## Exclusions (why some well-known candidates are not models)

- **Rust.** The ideas within Rust may hold merit (ownership, move
  semantics, bounds safety), but the choice of an entirely different
  surface representation is pure ego, not reason. Elseon's syntax family
  is C and JavaScript; a language whose surface rejects C's form fails the
  minimal-cognitive-friction principle. Rust is an idea source, not a
  model (see below).
- **D.** The work of that author is valued, but garbage collection makes
  sense for application programming and little or no sense for kernel
  programming. D fails the Kernel Test (no GC). D is an idea source, not a
  model (see below).
- **Go** falls under the same standard as D: GC'd and application-oriented,
  so it is not a kernel candidate. It is at most an idea source (tooling
  and simplicity).

## Camp 1: Fresh C-like designs

Clean-slate languages that keep C's shape but fix its pain points. These
are the closest to Elseon's design space: no GC, manual memory, LLVM
backend.

| Language | Take on "improved C" | Notes |
|---|---|---|
| C3 | Builds on C's syntax, evolving it into a better language; zero-cost abstractions, C-compatible FFI, LLVM backend | Probably the closest philosophical sibling to Elseon |
| C2 | "Cleaner C": removes the preprocessor in favor of modules and imports; LLVM-based | Smaller community |
| Zig | Modern low-level alternative to C: no GC, explicit allocators, usable as a drop-in C compiler (`zig cc`), LLVM backend | The most successful "better C" positioning to date |
| Jai | C-like, no GC, compile-time metaprogramming, LLVM backend; designed for game engines | Long-awaited, still not publicly released |
| Odin | Data-oriented, C-like, no GC, explicit allocators, LLVM backend | Active |
| Hare | Simple, C-like, no memory management required; minimal and static; for UNIX-like OSes | Used to build a real OS |
| Val | C-like syntax with mutable value semantics, to kill aliasing bugs | Newer |

Honorable mentions with caveats: **Nim** compiles to C (GC optional, so
kernel candidacy depends on the configuration chosen).

## Camp 2: Supersets and safe dialects of C

These stay compatible with C and patch its wounds in place:

- **C++** — the original attempt (1985), but it became a second language
  bolted onto C's semantics rather than a repair.
- **Cake** — "C23 and beyond": a superset of C with modern features that
  can desugar back to C.
- **Cyclone** (Cornell, 2002) — a safe dialect of C: region-based memory,
  checked pointers, no GC. The classic academic answer to "safe C."
- **Checked C** (Microsoft, 2016) — bounds-checked pointer types layered
  onto C.
- **CHERI / Morello** — not a new language but a hardware repair:
  capability-based pointers make C memory errors architecturally
  impossible.

## Idea sources (PFE: take the idea, leave the surface or runtime)

- **From Rust:** ownership and move semantics as a *concept* — the insight
  that a value has exactly one owner and transfers ownership explicitly.
  Also bounds safety as a goal. Rejected: the surface representation.
- **From D:** contracts (`in`/`out`/`invariant`), slices with length,
  `immutable` and `pure` attributes. Rejected: the GC runtime. (Each idea
  is admitted only if it passes the Kernel Test — e.g. bounds checks are
  explicit safety, not hidden control flow.)
- **From Go:** simplicity of tooling and formatting. Rejected: the GC
  runtime.

## What this means for Elseon

1. **Two failure modes.** Supersets (C++, Cake, Checked C) stay compatible
   but inherit C's baggage; clean-slate designs (C2, C3, Zig, Jai) are
   clean but must rebuild the ecosystem. Elseon's PFE position — ingest C
   headers as first-class semantic modules — is a third position:
   compatibility without superset baggage, and no need to re-declare the
   world.
2. **The Kernel Test is the differentiator.** Every serious candidate
   converges on the same constraints Elseon chose: no GC, no hidden
   allocations, no hidden control flow, deterministic layout, LLVM
   backend, C-compatible ABI.
3. **Concrete borrowable features:**
   - C3/C2: preprocessing replaced by modules — the same instinct as
     Elseon's semantic header import.
   - Zig: explicit allocators as a first-class concept (Elseon's "no
     hidden allocations").
   - Jai/Odin: compile-time metaprogramming without a macro preprocessor.
   - Cyclone/Checked C/CHERI: the menu of C-safety mechanisms (checked
     pointers, regions, bounds annotations) — Elseon picks from the menu
     rather than reinventing it.
   - Rust (ideas): ownership/move semantics; bounds safety as a goal.
   - D (ideas): contracts, slices, `immutable`/`pure` attributes.

## Status

- Surveyed and recorded in the Elseon project (phase 1 — research).
- The borrowable-features list feeds the open questions in `TODO.md` and
  the design document `documents/07-elseon-language.md`.
