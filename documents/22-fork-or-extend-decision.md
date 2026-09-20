# Fork or Extend: Choosing the Base for Elseon

Decision record, 2026-09-16.
It records a change of direction under consideration: instead of building a new language from a fresh front end, extend an existing C compiler.
It is an input to the language design (`documents/07-elseon-language.md`), not a replacement for it.
Evidence comes from `documents/21-c-compiler-extensions-inventory.md` and the sources cited there.

## 1. Why the base question reopened

The C-comparison series (`documents/13-c3-vs-c.md` through `documents/18-c-comparison-synthesis.md`) reached a consistent verdict: every candidate that built a fresh front end spent years rebuilding what C already has — the ABI, the preprocessor story, the standard library, the module machinery — and none of them reached C compatibility.
The C2 study added the sharpest single data point (`documents/19-c2-vs-c3.md`): C2's author abandoned LLVM after using it and replaced a 6.9 MB Clang-and-LLVM-based compiler with a 200 KB self-hosted one, a multi-year project that is still only 20 percent complete on its own backend.

Two proposals follow from that, and they are not opposites:

- Start from a C compiler, so C compatibility is inherited by construction rather than re-implemented.
- Start from LLVM, so code generation for every supported CPU is inherited.

Clang satisfies both at once, because Clang is the C front end that targets LLVM.

## 2. The correction that matters: a Clang dialect is a new language

It is tempting to treat "modify an existing C compiler" as a cheap option and "create a new language" as the expensive one.
The distinction does not survive contact with the codebase.
Clang already implements C, C++, Objective-C, OpenCL, CUDA, HLSL, and SYCL as language modes sharing one AST, one semantic analyzer, and one LLVM backend.
Adding a further dialect is the ordinary architecture of that project, not a hack.

What changes is the size of the work, not its kind:

- Inherited for free: C parsing and semantics, C ABI compatibility, every LLVM target, C23 features, sanitizers, debug information, and the Clang module machinery.
- Still built by hand: the new syntax, the new type rules, and the semantics that differ from C.

The project principle now in tension is `prompts/features/05-llvm-backend.md`: "the front end (lexer, parser, semantic analysis) is owned by Elseon."
Extending Clang means the front end is owned by upstream, and Elseon owns a delta against it.
That principle was written when the answer was a fresh front end; it needs an explicit revision rather than a quiet exception.

## 3. The real cost is rebasing, not writing the feature

The dominant cost of extending Clang is not implementing classes or destructors. It is keeping the delta alive against an upstream that changes constantly.

The evidence is Clang's own position on its interfaces: LibClang is the only interface the project calls stable, and its tooling guide lists "you don't need to change your code when the AST API changes" as a reason **not** to use LibTooling (`documents/21-c-compiler-extensions-inventory.md` §5).
There is no stable internal C++ API, so any fork that touches the internals rebases against a moving target at every LLVM release.

Two fork precedents bracket the outcome:

- Fil-C: active, based on Clang 20.1.8, and deliberately small — one LLVM pass plus localized CodeGen, driver, and pass-pipeline changes, with a single tracked upstream base.
- Checked C: a much larger language surface, dormant since October 2024, and transferred out of Microsoft.

The pattern is not subtle. Small, localized deltas survive; large language surfaces against a moving upstream do not.

## 4. What is already available without forking

This is the finding that most changes the plan, and it is newer than the Elseon design document.

**Scope-exit cleanup is now a standard-track C feature, shipping in Clang.**
The ISO `defer` Technical Specification (TS 25755) is complete and in ISO publication, and Clang's own command-line reference documents `-fdefer-ts` — "Enable support for the C `_Defer` Technical Specification" — in the released 22.1.0 and 23.1.0 documentation.
GCC's implementation is an active patch series whose merge status is unverified, and a `cleanup`-based shim covers GCC 9 and later.

The semantics are the important part for this project. The specification makes `defer` **lexically scoped to the innermost block** (explicitly rejecting Go's function-scoped behaviour), runs defers in reverse order, and makes `goto` into or over a `defer`, and `return`, `break`, or `continue` out of one, **compile errors**. A defer exits before the function returns but after the return expression is evaluated.

That is deterministic, translation-time control flow whose every exit point is known to the compiler and whose cleanup code is visible in the source.

**The existing attribute covers the same ground today.** `__attribute__((cleanup(fn)))` has shipped in GCC and Clang for years, and it is already used at scale in exactly the environment Elseon targets: the Linux kernel defines `DEFINE_FREE`/`__free()`, `DEFINE_GUARD`/`guard()`, `no_free_ptr()`, and `DEFINE_CLASS` in `include/linux/cleanup.h`; systemd uses cleanup roughly 5,852 times against 2,633 `goto`s; glibc's `pthread_cleanup_push`/`pop` is built on it.

**Classes and methods already have a proven C-shaped design.** Objective-C layers `@interface`, methods, properties, protocols, and message sends onto the C parser as a language mode, with dispatch and reference counting supplied by a runtime library rather than by the compiler.
This is the existence proof that C-with-classes splits cleanly into frontend parsing and type checking on one side, and runtime dispatch on the other.

**Modules are the weakest of the three, and the earlier claim that they are "80 percent built" was too generous.**
Clang's `-fmodules` is a build-level header-module system: module maps describe how headers form modules, `#include` is transparently translated into a module import, and the AST is serialized into a cache.
It is genuinely valuable — constant-time imports, no include-order fragility, no name-mangling change, no namespaces — but it is **not a C language module system**. There is still no C syntax for an import declaration, and no `export`.
The semantic machinery and the caching are reusable; the `module` and `export` keywords are new frontend work.

## 5. The decision ladder

Cheapest first. Each rung is a real commitment point, and the recommendation is to exhaust the lower rungs before paying the rebase cost of the highest one.

| Rung | Mechanism | Fork? | What it buys |
|---|---|---|---|
| 1 | Attributes and pragmas (`cleanup`, `constructor`, `destructor`), macros | No | Deterministic RAII today, in kernels and systemd already |
| 2 | `defer` under `-fdefer-ts` | No | Standard-track scoped cleanup with compile-time-verified exits |
| 3 | Clang Blocks (`-fblocks` plus runtime) | No | Closures, as an existing C extension |
| 4 | Objective-C's frontend-plus-runtime pattern | No, for Objective-C itself | A proven design for classes and methods |
| 5 | A small standalone front end (chibicc, slimcc, tcc) | Not applicable | Comprehension, if the language diverges far from C |
| 6 | A localized Clang fork, Fil-C style | Yes | New syntax or new types, at unbounded rebase cost |

Rungs 1 through 4 deliver destructors, closures, and a validated design for classes with no fork maintenance at all.
That matters because rebase cost, not feature cost, is what killed Checked C.

## 6. What the requested features cost under the kernel test

The requested additions are class methods, constructors, destructors, and modules with exports.
Assessed against the Kernel Test in `documents/07-elseon-language.md` §2:

- **Destructors**: available now, at rung 1 or 2, and both forms are deterministic and source-visible.
  The specification's strict scoping and jump barriers are stricter than the raw attribute, which makes the standard-track version the better fit.
- **Class methods**: coherent if they are compile-time bound — methods on structs, in the style of C2's `Point.add` type functions or C3's value methods — with no dynamic dispatch and no inheritance, which the design document already rejects.
  Dispatch through a vtable on every call is hidden control flow and fails the test.
- **Constructors**: this is where the request is genuinely underspecified and where the current design document is contradicted.
  A deterministic, explicitly called initializer is fine.
  A C++-style constructor that runs implicitly, participates in overload resolution, and is invoked on paths the caller does not see is exactly the "implicit constructors/destructors with hidden effects" the document currently rejects.
- **Modules and exports**: the largest new-syntax item, and the one with the clearest reusable machinery underneath (module maps, serialized ASTs, `#include`-to-import translation).
  It is the strongest candidate for the fork, and it can be deferred without blocking the rest.

Two of the four requests are therefore satisfiable without a fork, one is a design constraint rather than a feature, and only modules and any bespoke class syntax actually require touching Clang.

## 7. Contradiction to resolve before any implementation

`documents/07-elseon-language.md` currently states both of the following:

- Adopted: "Explicit resource management. Destructor-like scopes exist, but they are explicit: no hidden control flow at scope exit beyond what the source spells out."
- Rejected: "Implicit constructors/destructors with hidden effects (hidden control flow)."

The request to add constructors and destructors is a direct change to that position.
It is defensible — `defer` is deterministic and the kernel already uses its equivalent — but it must be an explicit revision, because the Kernel Test forbids exactly what was requested and the rest of the design document leans on that prohibition.

## 8. Open decisions

These are the maintainer's to make, and the record is not complete until they are answered.

1. **What kind of destructor?** Lexically scoped and compile-time determinable (`defer` semantics, admitted under a revised Kernel Test), or C++-style RAII with implicit invocation on paths the caller cannot see (not admissible without changing the Kernel Test's meaning)?
2. **What kind of constructor?** An explicitly called initializer, or implicit initialization with overload resolution?
3. **What kind of dispatch?** Compile-time-bound methods only, or runtime dispatch through vtables for at least some calls?
4. **Which rung?** Are rungs 1 through 4 sufficient for the first usable version, deferring rungs 5 and 6 until new syntax or new types are genuinely required?
5. **Is the front-end principle revised?** `prompts/features/05-llvm-backend.md` asserts Elseon owns the front end; an extension strategy replaces that with ownership of a delta.

## 9. Recommendation

Stay on rungs 1 through 4 for as long as the language can be expressed through attributes, `defer`, existing blocks, and existing dialects.
Adopt `defer` semantics for resource management rather than designing a new destructor mechanism, because it is standard-track, already implemented in Clang, and its scoping rules are stricter than the attribute it generalizes.
Defer any decision to fork Clang until a concrete construct cannot be expressed on a lower rung; when that happens, follow the Fil-C pattern — a small, localized delta against a single pinned upstream base — rather than the Checked C pattern of a large language surface.
Treat module syntax as the first construct likely to force that decision, and the constructor question as the first that must be answered on design grounds rather than implementation grounds.
