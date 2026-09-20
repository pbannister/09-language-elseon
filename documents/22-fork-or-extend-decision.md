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
- **Constructors and destructors**: admissible, and explicit syntax is wanted, provided invocation is limited to the two overt boundaries — declaration and scope exit.
  The design work is not whether to allow them but which of C++'s other invocation sites to forbid; the per-site rulings are in `documents/23-constructor-destructor-variants.md`.
- **Modules and exports**: the largest new-syntax item, and the one with the clearest reusable machinery underneath (module maps, serialized ASTs, `#include`-to-import translation).
  It requires touching Clang, because C has no import syntax.

With Clang as the established base (§8), the fork question is settled and the remaining work is the delta: rules for classes and methods, rulings on the constructor and destructor invocation sites, and module syntax.

## 7. The admissibility boundary for constructors and destructors

An earlier draft of this record read the design document's rejection of "implicit constructors and destructors with hidden effects" as a blanket prohibition.
That was an over-read, and the maintainer corrected it.
The qualifying phrase carries the rule: hidden effects and hidden invocation are rejected, not automation.
The design document and the language-core feature file have been reworded to say this directly (`documents/07-elseon-language.md` §2 and §4, `prompts/features/03-language-core.md`).
The intended distinction is between **overt** and **hidden**, not between **explicit in a call** and **automatic**.

Overt, and therefore admissible:

- `class C {}; { C v; ... }` — the declaration *is* the constructor, and the closing brace is where the object ceases to exist.
- This is exactly C's model for primitive types, where automatic storage duration begins at the declaration and ends at the scope exit, except that the constructor and destructor bodies are non-trivial.

The concern is not automation. It is invocation the source does not show: the constructor machinery C++ triggers without a declaration or a written call, and the destructor machinery it triggers beyond scope exit.

The boundary is therefore about **invocation sites**, not about whether the compiler emits a call. For Elseon's model the rule is: a constructor runs when the source declares an object, and a destructor runs when that object's scope ends.
Every other invocation site C++ has must be either forbidden or made a written call.
The survey of those sites is in `documents/23-constructor-destructor-variants.md`, which enumerates them and marks each as overt or hidden.

Two boundary cases are worth stating here because they are the ones most likely to be reintroduced by accident:

- **Temporaries.** An invisible temporary invokes a constructor and a destructor at a point the source does not name.
  Whether Elseon admits temporaries, and under what spelling, is an open question, not a settled one.
- **Copy and move.** C++ invokes copy or move constructors at by-value calls, by-value returns, and container insertion.
  If Elseon admits copying, it must be a written call rather than a constructor overload selected by the compiler.

The design is closer to "C automatic storage duration with non-trivial begin and end code" than to C++'s object model.
That is a coherent position, and it is the one the rest of this record now assumes.

It is also a position with an existing normative precedent to borrow.
C++ already guarantees, for automatic variables with side-effecting initialization or destruction, that an implementation "shall not destroy it before the end of its block nor eliminate it as an optimization, even if it appears to be unused," with copy and move elision the only exception ([\[basic.stc.auto\]/2](https://eel.is/c++draft/basic.stc.auto)).
Elseon's scope boundary should carry a guarantee of that strength rather than leave the boundary to the optimizer.
The Objective-C ARC precedent shows the failure mode: ARC makes local `__strong` lifetimes imprecise by default and requires `objc_precise_lifetime` to force release at the end of the formal lifetime ([Clang ARC spec](https://clang.llvm.org/docs/AutomaticReferenceCounting.html)).
A boundary the optimizer may move is not an overt boundary.

The per-site rulings that follow from this are in `documents/23-constructor-destructor-variants.md`.

## 8. Decisions taken and questions remaining

**Decided:**

1. **Base: Clang.** The language starts from Clang rather than a fresh front end.
   This settles rung 6 in the ladder above; the work is a delta against Clang, and the front-end ownership principle in `prompts/features/05-llvm-backend.md` is superseded.
2. **Dispatch: no vtables.** Class methods are not dispatched through a vtable.
   An overt equivalent, such as function pointers held as class members, is the preferred direction.
   This removes the largest source of hidden call targets, and it rules out virtual destructors entirely.
3. **Surface: explicit syntax** for constructors, destructors, and modules, rather than attributes alone.
   The mechanism exists at the lower rungs, but the syntax is the part that must be designed.

**Open:**

1. **Where exactly is the admissibility line for constructors and destructors?** The overt/hidden distinction is settled in principle (§7); the per-invocation-site ruling depends on the survey in `documents/23-constructor-destructor-variants.md`.
2. **Temporaries:** admitted or forbidden? If admitted, how are they spelled, and does their destruction happen at the end of a full expression?
3. **Copy and move:** is there a copy constructor mechanism at all, and is copying a written call rather than a compiler-selected overload?
4. **IR target:** LLVM IR directly, or ClangIR with a lowering step (§9)?
5. **Module syntax:** what do `module` and `export` look like, given that Clang's module maps supply the semantics but no C syntax?

## 9. ClangIR as a possible IR target

ClangIR (CIR) is an MLIR-based, higher-level representation that sits between Clang's AST and LLVM IR.
It captures more C and C++ source semantics than LLVM IR does, which enables source-level diagnostics, static analysis, and optimizations that are awkward once code has been lowered to LLVM IR.
It began at Meta in October 2021, entered the LLVM incubator, and was accepted for upstreaming in January 2024; it now lives in the `llvm-project` repository and is built but not used by default, behind `-fclangir`.

Two properties are relevant to this language:

- **Scopes are explicit.** CIR has a `cir.scope` operation whose region boundaries correspond to source lexical scopes.
  A destructor-at-scope-exit is therefore visible as a region boundary in the IR rather than reconstructed from control-flow graphs, which suits a design whose whole point is that scope exit is where objects end.
- **Cleanup is tied to exception paths.** CIR attaches `cleanup` regions to calls explicitly marked as possibly throwing (`cir.call exception ... cleanup { ... }`).
  A language with no exceptions does not need that machinery, which suggests the destructor lowering would be ordinary code inside the scope region.

Against that, CIR's own status page reports that C is mostly covered but C++ is missing cleanup and exception-handling parts, that ABI calling-convention lowering is still work in progress behind `-fclangir-call-conv-lowering`, and that Objective-C is unsupported.
Its targets are Linux and macOS on x86_64 and AArch64, plus SPIR-V.

Recommendation: target LLVM IR first, because it is stable, mature, and what the kernel test can be verified against, and treat ClangIR as a later option for its diagnostic and analysis value.
Either way, the front end remains Clang, so this choice can be deferred and revisited without changing the base.

## 10. Recommendation

Start from Clang as decided, and design the delta rather than the base.
Adopt `defer` semantics as the reference behaviour for scope-exit code, because it is standard-track, already implemented behind `-fdefer-ts`, and its lexical scoping and jump barriers are stricter than the attribute it generalizes; then give constructors and destructors explicit syntax whose invocation sites are limited to declaration and scope exit.
Keep the admissibility boundary in terms of invocation sites, and rule each site in `documents/23-constructor-destructor-variants.md` explicitly rather than by implication.
Target LLVM IR initially and hold ClangIR in reserve.
Follow the Fil-C pattern for the fork itself: a small, localized delta against a single pinned upstream base, rather than the large-surface pattern that left Checked C dormant.
