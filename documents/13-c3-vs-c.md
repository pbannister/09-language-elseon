# C3 vs C

Study note for the episode 1-A series, per `prompts/11-c-comparison-criteria.md`.
Baseline is C.
Scope: what C3 tried, what worked, what did not work, and what Elseon should borrow or avoid.
Primary sources are the official site ([c3-lang.org](https://c3-lang.org)), its documentation, the C3 blog, and the compiler repository ([c3lang/c3c](https://github.com/c3lang/c3c)).
Live-state observations (repository metrics, latest release, file layout) were recorded on 2026-09-03.
The official docs carry the warning "Docs may not reflect current language state", so claims were cross-checked against the repository and release notes where possible.
"Stated by the project" marks project claims; "observed" marks what was checked against primary material or public data.

## 1. Positioning

- C3 presents itself as "an evolution of C", a general-purpose systems language: "C3 is the ergonomic, safe evolution of C. Familiar syntax, full ABI compatibility, optionals, slices, contracts and zero-cost abstractions" ([c3-lang.org](https://c3-lang.org/)).
- The introduction page says: "C3 is a general-purpose systems programming language for building native software" ([Introduction](https://c3-lang.org/getting-started/introduction/)).
- Design goals (stated by the project): procedural with a pragmatic ethos, minimalistic, "stay close to C - only change where there is a significant need", "learning C3 should be easy for a C programmer", seamless C integration, ergonomic common patterns, "data is inert", zero-is-initialization, and "avoid 'big ideas'" ([Design Goals](https://c3-lang.org/getting-started/design-goals/)).
- The repository README states: "C3 is a general-purpose programming language for building fast native software: applications, games, tools, servers, libraries, and systems. It's an evolution, not a revolution: familiar C syntax and semantics, modernized for everyday development" ([c3c README](https://github.com/c3lang/c3c/blob/master/README.md)).
- The README lists the design principles: procedural "get things done", close to C, "C ABI compatibility and excellent C integration", "learning C3 should be easy for a C programmer", "data is inert", avoid "big ideas" and the "more is better" fallacy, and "evolve C into an ergonomic language for modern application development" ([c3c README](https://github.com/c3lang/c3c/blob/master/README.md)).
- The positioning is therefore "improved C for application development", not primarily "safer C" and not primarily a kernel or embedded language.
- C3 is not a memory-safe language: the README advertises "less undefined behaviour and added runtime checks in 'safe' mode", not full safety ([c3c README](https://github.com/c3lang/c3c/blob/master/README.md)).
- The author (Christoffer Lernö) wrote that marketing C3 as "a C alternative" or "C replacement" was a mistake, because "C alternative" today means a language for what C is used for today (OS development, embedded, high-performance niche libraries), while C3 targets general-purpose applications: "refreshing C to make it a pleasant general-purpose application language again" ([I thought I was building a C replacement. I was wrong](https://c3-lang.org/blog/i_thought_i_was_building_a_c_replacement/), 2026-08-16).
- C3's lineage: "C3 started as an experimental fork of the C2 language by Bas van den Berg" and "has evolved significantly, not just in syntax but also in regard to error handling, macros, generics and strings" ([Design Goals](https://c3-lang.org/getting-started/design-goals/)).
- The README repeats the lineage: "C3 owes its inspiration to the C2 language: to iterate on top of C without inventing an entirely new language" ([c3c README](https://github.com/c3lang/c3c/blob/master/README.md)).
- This refines `documents/08-related-work.md`: C3 and C2 are not two independent rows in Camp 1 — C3 is documented as a fork of C2 that outgrew it.
- Compared to C's own positioning (the baseline), C3 keeps C's low-level model and ABI but adds a module system, slices, optionals, generics, macros, and a batteries-included standard library — the "application ergonomics" C lacks ([Design Goals](https://c3-lang.org/getting-started/design-goals/), [Compare Languages](https://c3-lang.org/faq/compare-languages/)).

## 2. Kernel-test adherence

- C3 was designed for application development, not to pass a kernel admission test, so each Elseon guarantee is assessed separately below with evidence.

**No garbage collection / no hidden runtime.**

- C3 has no garbage collector: memory management is manual (malloc/free, allocator passing) plus scope-based arenas; the project's own framing is "without leaks, GC, or borrow checkers" ([How C3 Manages Memory Without Leaks, GC, or Borrow Checkers](https://c3-lang.org/blog/how-c3-manages-memory-without-leaks%2C-gc%2C-or-borrow-checkers/), 2025-07-11).
- The FAQ describes malloc, calloc, free, a replaceable heap allocator, and a temporary (arena) allocator ([FAQ: Memory management](https://c3-lang.org/faq/)).
- "GC: none" is stated implicitly by its absence and by the arena framing; it is consistent with observed behavior (plain native executables, no collector code or runtime services in the generated program).
- Whether C3 has "no hidden runtime" is less clear: no mandatory runtime is documented, but the FAQ references a `runtime::wasm_initialize()` startup function for WASM globals, and normal builds link against the platform C runtime by default ([FAQ: Platform support](https://c3-lang.org/faq/)).
- The repository support matrix lists "ELF freestanding" targets (x86, x64, Aarch64, Riscv) but marks them "Untested", with no native compiler for them; wasm32 has a target but no stack traces; MCU x86 is untested ([c3c README support matrix](https://github.com/c3lang/c3c/blob/master/README.md)).
- Assessment: no GC is real and documented; "no runtime beyond what a kernel build accepts" is not demonstrated — freestanding support is aspirational and unverified in practice.

**No hidden allocations.**

- C3's language core avoids implicit allocation: the designers rejected string-interpolation syntax partly because "the general runtime case needs implicit allocation, which isn't compatible with C3 memory management" ([FAQ: Rejected ideas](https://c3-lang.org/faq/rejected-ideas/)).
- Standard library functions that allocate "generally require you to pass an allocator" (mem for heap, tmem for temporary), and container methods follow a `new`/`temp`/`free` naming convention that signals allocation ([Memory Management](https://c3-lang.org/language-common/memory/), [FAQ: Patterns](https://c3-lang.org/faq/)).
- However, defaults hide the allocation: "Some types, such as List, HashMap and DString will use the temp allocator by default if they are not initialized", so `list.push(1)` on an uninitialized `List` allocates without an allocator visible at the call site ([Memory Management](https://c3-lang.org/language-common/memory/)).
- The compiler additionally injects behavior: "The compiler automatically adds a @pool() scope to the main() function ... once it finds a temp allocation function like mem::tnew()" ([How C3 Manages Memory](https://c3-lang.org/blog/how-c3-manages-memory-without-leaks%2C-gc%2C-or-borrow-checkers/)).
- Assessment: allocation *mechanisms* are explicit and allocator-aware, but *sites* can be implicit (container defaults, compiler-injected pool), which does not satisfy Elseon's "every allocation is visible in the source" standard.

**No hidden control flow.**

- C3 has no exceptions and no hidden unwinding: errors are returned values (optionals with a pointer-sized fault) unwrapped with explicit syntax (`!`, `catch`, `try`, `defer`, `rethrow !`) ([Optionals](https://c3-lang.org/language-common/optionals-essential/), [README feature list](https://github.com/c3lang/c3c/blob/master/README.md)).
- C3 rejects constructors and destructors: "A fundamental concept in C3 is that data is not 'active'", and "constructors and destructors will not be considered for C3" — no RAII-style implicit cleanup ([FAQ: Rejected ideas](https://c3-lang.org/faq/rejected-ideas/)).
- `defer` runs at scope exit and is source-visible; scope exit order is documented (reverse declaration order) ([Defer](https://c3-lang.org/language-common/defer/)).
- `goto` was removed because it interacts badly with defer and optional unwrapping ([FAQ: Changes from C](https://c3-lang.org/faq/)).
- However, C3's "safe mode" (default at -O0/-O1) inserts implicit bounds checks, null checks, contract evaluation, and backtraces; "unchecked mode" (-O2+) removes them ([Debugging](https://c3-lang.org/misc-advanced/debugging/)).
- `assert` and `unreachable` change meaning by mode: in unchecked mode an `assert` becomes an LLVM unreachable optimization hint, and a contract violation no longer panics ([Debugging](https://c3-lang.org/misc-advanced/debugging/)).
- The author himself noted the tension: "Any C alternative will be expected to be on par with C in performance ... This leads to a strategy of only having checks in 'safe' mode. Where the 'fast' mode is just as 'unsafe' as C" ([The case against a C alternative](https://c3-lang.org/blog/the-case-against-a-c-alternative/), 2022-08-07).
- Assessment: control flow for errors is explicit and aligned with Elseon, but mode-dependent implicit checks insert branches the source does not show, which conflicts with Elseon's "every branch ... visible in the source".

**Deterministic memory layout.**

- C3 fixes integer widths: "char is an unsigned 8-bit integer", short 16, int 32, long 64, int128 128, with iptr/uptr and sz/usz pointer-sized types ([All features](https://c3-lang.org/faq/allfeatures/)).
- Structs follow C layout rules by default ("Structs are always named"; unions are "fully compatible with C"), and layout is adjusted only through explicit attributes such as `@packed`, `@align`, `@bigendian`/`@littleendian` ([Structs and unions](https://c3-lang.org/language-common/structs-and-unions/), [All features](https://c3-lang.org/faq/allfeatures/)).
- Bit fields are replaced by `bitstruct`, "a struct with a container type allowing precise control over bit-layout" ([All features](https://c3-lang.org/faq/allfeatures/)).
- No automatic struct-field reordering is documented or observed; default layout is the C ABI's, which keeps C compatibility. Whether "never reordered" is an explicit language guarantee is unverified.
- Semantics supporting determinism: signed overflow always wraps (2s complement, never UB), implicit narrowing is not permitted, and evaluation order is defined left-to-right ([C to C3 guide](https://c3-lang.org/c-to-c3/a-guide-for-c-programmers/)).
- Locals and globals are zero-initialized by default, with `@noinit` to opt out ([C to C3 guide](https://c3-lang.org/c-to-c3/a-guide-for-c-programmers/)).
- Assessment: this dimension is C3's strongest: fixed widths, C-rules layout with explicit control attributes, and defined arithmetic semantics give deterministic, C-compatible representation.

**C-compatibility (Elseon's fourth kernel-test element).**

- "C3 is C ABI compatible. That means you can call C from C3, and call C3 from C without having to do anything special" ([C Interop](https://c3-lang.org/language-common/cinterop/)).
- C3 advertises "full C ABI compatibility" as a headline feature and demonstrates it by compiling a mixed C/C3 build (vkQuake with a portion converted to C3) ([c3c README](https://github.com/c3lang/c3c/blob/master/README.md)).

## 3. Syntax family

- C3 keeps the C statement shape: braces, semicolons, if/while/for/switch with C-like bodies, and C operator precedence with documented, mostly-minor changes ([C to C3 guide](https://c3-lang.org/c-to-c3/a-guide-for-c-programmers/)).
- Functions keep C's return-type-first declarations with a mandatory `fn` prefix: `fn int foo(int x) { ... }` ([C to C3 guide](https://c3-lang.org/c-to-c3/a-guide-for-c-programmers/)).
- This is the same family as Elseon's C and JavaScript choice at the level of statement shape and control flow; C3 shows no JavaScript-specific surface.
- Deliberate grammar simplifications reshape the surface: type names must be PascalCase and variable/function names lower-case because the grammar needs only one token of lookahead ("it is a lexer rule, to be able to distinguish between types and other identifiers") ([FAQ: Syntax and language design](https://c3-lang.org/faq/)).
- Array declarations move the type left: `int[4]*[2] a;` replaces C's spiral rule `int (*a[2])[4];` ([All features](https://c3-lang.org/faq/allfeatures/)).
- The preprocessor and mandatory headers are gone: `module` and `import` replace `#include`, and user macros are replaced by a typed semantic macro system with `$` compile-time constructs and `@` attributes ([Modules](https://c3-lang.org/language-fundamentals/modules/), [C to C3 guide](https://c3-lang.org/c-to-c3/a-guide-for-c-programmers/)).
- Removed from C's surface: `const`, `volatile`, and `restrict` qualifiers; 0-prefix octal; `goto`; multiple declarations with initialization; C's implicit narrowing; and implicit signed/unsigned mixing, which C3 dropped entirely in 0.8.0 ([Unsigned sizes: a five year mistake](https://c3-lang.org/blog/unsigned-sizes-a-five-year-mistake/)); the `#` preprocessor ([C to C3 guide](https://c3-lang.org/c-to-c3/a-guide-for-c-programmers/), [All features](https://c3-lang.org/faq/allfeatures/)).
- Added: slices `int[]`, optionals `int?`, `defer`, `foreach`, methods on any type, interfaces/`any`, generics over generic modules, compile-time reflection, operator overloading, bitstructs ([All features](https://c3-lang.org/faq/allfeatures/)).
- Cognitive friction for a C programmer is a stated design goal ("learning C3 should be easy for a C programmer"), supported by an official "C to C3: a guide for C programmers" ([Design Goals](https://c3-lang.org/getting-started/design-goals/), [C to C3 guide](https://c3-lang.org/c-to-c3/a-guide-for-c-programmers/)).
- Surface choices Elseon would likely reject under the kernel test: mode-dependent semantics (assert/contracts/bounds checks silently change with optimization level), implicit allocator selection by uninitialized containers, and removal of `const`/`volatile` qualifiers, which matters for C-header ingestion fidelity.
- Elseon design notes to weigh: the "one token lookahead" naming rule works but diverges from C's identifier freedom; and removing `const` trades away the C ecosystem's dominant annotation for C3's own ergonomics.

## 4. C interoperability

- Full C ABI compatibility is a headline claim and is exercised in practice: "it's possible to mix C and C3 in the same project with no effort", demonstrated by the vkQuake fork compiled with c3c ([c3c README](https://github.com/c3lang/c3c/blob/master/README.md)).
- Calling C from C3 is by hand-written declaration: "Just copy the C function declaration and prefix it with extern (and don't forget the fn as well)" ([FAQ: Interfacing with C](https://c3-lang.org/faq/)).
- `@cname` maps C3 identifiers to external C names; `@export` (optionally with an explicit name) exposes C3 functions to C, since exported names are module-namespaced by default ([C Interop](https://c3-lang.org/language-common/cinterop/)).
- Linking C libraries uses `-l`/`linked-libraries` and `-L`/`linker-search-paths` ([C Interop](https://c3-lang.org/language-common/cinterop/)).
- A project can compile C sources together with C3 sources: project.json supports `c-sources` ("List of C sources to compile") and `c-compiler` ("C compiler to use for compiling C sources (if C sources are compiled together with C3 files)") ([Project config](https://c3-lang.org/build-your-project/project-config/)).
- There is no automatic reuse of C headers: interop is re-declaration by hand, and the FAQ's gotcha list shows the friction — C bit fields must be converted manually to bitstructs per platform, C enums are assumed to be CInt-sized, atomics are not keywords (generic Atomic types instead), and there are no `const`/`volatile` qualifiers (`@volatile_load`/`@volatile_store` macros replace volatile) ([C Interop](https://c3-lang.org/language-common/cinterop/)).
- C3 arrays do not decay like C arrays, so C function signatures taking arrays must be re-declared with explicit pointers ([C Interop](https://c3-lang.org/language-common/cinterop/)).
- `std::core::cinterop` provides types matching platform C types (e.g. CInt), acknowledging residual size differences between C and C3 fixed-width types (mainly `long`) ([FAQ: Standard library](https://c3-lang.org/faq/)).
- A C-to-C3 converter is only a future, help-wanted item: "Start work on the C -> C3 converter which takes C code and does a 'best effort' to translate it to C3. The first version only needs to work on C headers" ([c3c README](https://github.com/c3lang/c3c/blob/master/README.md)).
- An interchange header format exists but "is only used in special cases"; there are no mandatory header files ([C to C3 guide](https://c3-lang.org/c-to-c3/a-guide-for-c-programmers/)).
- There is no `zig cc`-style drop-in compilation of arbitrary existing C codebases: c3c compiles C files only inside a C3 project context.
- Assessment against Elseon's PFE: C3 has C ABI compatibility but not C-header ingestion as a semantic operation — it is the closest philosophical sibling in ABI terms, yet it stops short of Elseon's PFE, which is a documented gap (the converter is future work).

## 5. Toolchain

- Backend: LLVM. CMake declares LLVM 19–24 support with default 23 and an automatic download option (`C3_FETCH_LLVM`) ([CMakeLists.txt](https://github.com/c3lang/c3c/blob/master/CMakeLists.txt), [Building C3 from source](https://c3-lang.org/getting-started/compile/)).
- Compiler implementation (observed from the repository layout, 2026): driver and compiler sources under `src/` are C (`src/main.c`, `src/compiler/*.c`, `src/build/*.c`) with a small C++ LLVM wrapper (`wrapper/`); the standard library (`lib/std/*.c3`) and tests are C3 ([c3c src tree](https://github.com/c3lang/c3c/tree/master/src)).
- GitHub labels the repository's dominant language "C3" because of the large C3 standard library and test corpus, not because the compiler is self-hosting (observed via repository metadata and file tree).
- The compiler is single-maintainer-led with contributors; it has compiled, per the README, on Windows, macOS, Linux, OpenBSD, and NetBSD, with a published support matrix including cross-compilation targets and freestanding ELF targets ([c3c README](https://github.com/c3lang/c3c/blob/master/README.md)).
- Build story: integrated build system via `project.json` (JSON, moved from TOML so tools can manipulate it), `c3c init/build/run/test/benchmark/clean/dist`, debug and release targets, unit tests via the `@test` attribute, and `@benchmark` for benchmarks ([Build commands](https://c3-lang.org/build-your-project/build-commands/), [FAQ: tooling](https://c3-lang.org/faq/)).
- Some documented commands are still stubs: "c3c dist has not been properly added yet!" and "c3c docs ... Not added yet!" ([Build commands](https://c3-lang.org/build-your-project/build-commands/)).
- A docgen tool was added in 0.8.0 ("docgen command for html documentation generation"), which also finally kept the official site's docs up to date ([C3 0.8.0 blog](https://c3-lang.org/blog/0_8_0_the_core_language_is_settling/), 2026-05-14).
- Maturity: latest stable at observation time is 0.8.3 (released 2026-08-12); the roadmap states "The C3 0.8.x series can be run in production with the same general caveats for using any pre-1.0 software", with 0.9 targeted 2027-06 and 1.0 targeted 2028-06; "The standard library is less mature than the compiler" ([Roadmap](https://c3-lang.org/getting-started/roadmap/), [releases](https://github.com/c3lang/c3c/releases)).
- Release discipline: "0.6.0 was tagged in June 2024, and since then there's been monthly releases up until the last one, 0.6.8"; breaking changes are collected into each new 0.x.0 release ("The release format of C3 allows for breaking changes in every new 0.x release") ([C3 0.7.0 blog](https://c3-lang.org/blog/c3-0-7-0-one-step-closer-to-1-0/), 2025-03-30).
- Debugging: official documentation covers safe-mode panic backtraces, ASAN/TSAN sanitizer integration, a VMEM_TEMP page-protection mode for use-after-scope detection, tracking allocators, and leak-assert macros ([Debugging](https://c3-lang.org/misc-advanced/debugging/)).
- Interactive debugger support is thinner: debug-info generation has a long issue trail from 2021 ("Full Debug Info", issue #324) through 2026 (issue #3358, a compiler crash when debug info is enabled), so classic gdb/lldb stepping is less mature than the sanitizer story ([issue #324](https://github.com/c3lang/c3c/issues/324), [issue #3358](https://github.com/c3lang/c3c/issues/3358)).
- CI verifiability: a GitHub Actions workflow exists, and the compiler ships a large `@test`-based unit-test corpus under `test/` ([workflows](https://github.com/c3lang/c3c/tree/master/.github/workflows)); the FAQ admits "there is no CI running on the WASM code and no one is really using it yet, so the quality is low" ([FAQ: Platform support](https://c3-lang.org/faq/)).
- Kernel-adjacent constraint: freestanding ELF and MCU targets exist in the support matrix but are untested, and no kernel build flow is documented; the default toolchain links libc and implicitly imports the C3 standard library, which a kernel build could not accept ([c3c README support matrix](https://github.com/c3lang/c3c/blob/master/README.md)).
- LLVM experience (stated by the project, measured on the C3 compiler itself): "LLVM codegen and linking takes over 98% of the total compilation time for the C3 compiler when codegen is single threaded with no optimizations"; LLVM is "very much a backend for C/C++", and codegen paths not used by Clang are "notoriously unreliable"; still, "LLVM ... is probably the best backend you can pick for your compiler when you start out" ([How bad is LLVM really?](https://c3-lang.org/blog/how-bad-is-llvm-really/), 2024-01-18).
- These LLVM findings corroborate Elseon's own LLVM-backend choice while warning that front-end speed will be dwarfed by LLVM codegen cost.

## 6. Ecosystem and adoption

- Repository: c3lang/c3c, created 2019-07-31, at observation ~5,800 stars and ~400 forks, actively pushed (last push 2026-09-03); the latest release is v0.8.3 (2026-08-12) with nightly prereleases ([c3lang/c3c](https://github.com/c3lang/c3c), [releases](https://github.com/c3lang/c3c/releases)).
- License: dual — "the code in this repository is MIT licensed. The exception is the compiler source code (the source code under src), which is licensed under LGPL 3.0", so the standard library, tests, and examples are MIT ([c3c README: Licensing](https://github.com/c3lang/c3c/blob/master/README.md)).
- Community: Discord is the main venue; the author credits streamer Tsoding's C3 streams with "a lot of extremely valuable feedback on both the language and the standard library" and a surge of new users ([C3 0.7.0 blog](https://c3-lang.org/blog/c3-0-7-0-one-step-closer-to-1-0/)).
- External attention: a 2025 "Show HN: The C3 programming language (C alternative language)" by the author drew ~175 points ([HN item 43569724](https://news.ycombinator.com/item?id=43569724), 2025-04-03).
- Adoption breadth (observed via the official showcase, which warns projects are "in various levels of completion, from actively supported to just started or abandoned"): emulators, games, bindings to many C libraries (Vulkan, sokol, imgui, libmpv, wgpu), an ECS, a UEFI definitions library, and a minimalist x86-64 microkernel written in C3 (muon-kernel) ([c3-showcase](https://github.com/c3lang/c3-showcase)).
- Bindings and tooling are community-organized: a bindings repository (`c3lang/vendor`), editor plugins (`c3lang/editor-plugins`), a browser playground (learn-c3.org), a version manager, and a formatter ([c3-showcase](https://github.com/c3lang/c3-showcase)).
- There is no full package manager: "There will be some standard API for uploading and downloading C3 libraries. However, it will not be a full dependency manager" — dependencies are downloaded separately on purpose ([FAQ: tooling](https://c3-lang.org/faq/)).
- Kernel-adjacent usage is minimal and hobby-scale: one showcase microkernel and a UEFI library; nothing in the official materials documents kernel or production-embedded deployments (any larger deployments are unverified).
- Maintenance status: active and regular (monthly releases observed through the 0.6, 0.7, and 0.8 series, 2024–2026), but pre-1.0, with the standard library explicitly less mature than the compiler ([Roadmap](https://c3-lang.org/getting-started/roadmap/)).

## 7. What worked

- Staying close to C where it matters: the C-shaped statement syntax, ABI compatibility, and manual-memory model let C programmers onboard quickly, which is both a design goal and the basis of the "C to C3" primer ([Design Goals](https://c3-lang.org/getting-started/design-goals/), [C to C3 guide](https://c3-lang.org/c-to-c3/a-guide-for-c-programmers/)).
- Modules and imports replacing user-code headers and the preprocessor: C3 demonstrates at scale (its whole standard library) that a C-like language works without `#include` ([Modules](https://c3-lang.org/language-fundamentals/modules/)); this is the "same instinct" Elseon's semantic header import extends ([08-related-work](documents/08-related-work.md)).
- C ABI compatibility plus mixed C/C3 builds: the vkQuake demo and `c-sources` project support show C code and C3 code compiling and linking in one project ([c3c README](https://github.com/c3lang/c3c/blob/master/README.md), [Project config](https://c3-lang.org/build-your-project/project-config/)).
- Slices (`pointer + length`), `foreach`, optionals with pointer-sized faults, `defer`, and value methods: zero-overhead, source-visible error handling that avoids hidden exceptions; the standard library is written in them, i.e. dogfooded (observed across docs and stdlib) ([All features](https://c3-lang.org/faq/allfeatures/), [README feature list](https://github.com/c3lang/c3c/blob/master/README.md)).
- Scope-based arenas as the default memory idiom: the temporary allocator with `@pool` gives GC-like ease with manual-memory predictability; the project reports a clean Valgrind run on the canonical example (project-reported, 2025-07-11) ([How C3 Manages Memory](https://c3-lang.org/blog/how-c3-manages-memory-without-leaks%2C-gc%2C-or-borrow-checkers/)).
- "Data is inert" — no constructors/destructors, no RAII: this design constraint (identical in spirit to Elseon's rejection of implicit constructors) kept the language simpler and survived years of use ([FAQ: Rejected ideas](https://c3-lang.org/faq/rejected-ideas/)).
- Determinism fixes that C lacks: fixed-width integers, well-defined signed overflow, no implicit narrowing, defined evaluation order, zero-initialization by default ([C to C3 guide](https://c3-lang.org/c-to-c3/a-guide-for-c-programmers/)).
- Feature-removal discipline: the author repeatedly removed features that did not carry their weight — untyped literals (2021), `$checks` (2023), inline enums and half the builtins (0.8.0) — freeing compiler complexity ([Removing features, gaining freedom](https://c3-lang.org/blog/removing-features-gaining-freedom/), 2021-10-17; [Too much power, too poor accuracy](https://c3-lang.org/blog/too-much-power-too-poor-accuracy---the-story-of-checks-in-c3/), 2023-10-25; [0.8.0 blog](https://c3-lang.org/blog/0_8_0_the_core_language_is_settling/)).
- Iterating in public with honest accounting: monthly releases, deprecation-first breaking changes, design post-mortems on the blog, and community feedback loops (e.g. Tsoding's streams) are observable working practices ([C3 0.7.0 blog](https://c3-lang.org/blog/c3-0-7-0-one-step-closer-to-1-0/)).
- Starting on LLVM: the author's measured verdict is that LLVM's compile-time cost and C/C++ bias are real but it is still the best backend to begin with — matching Elseon's backend plan ([How bad is LLVM really?](https://c3-lang.org/blog/how-bad-is-llvm-really/)).

## 8. What did not work

- Positioning as "C alternative"/"C replacement": the author concluded this framing was a years-long marketing mistake, because today's C programmers associate C with OS/embedded/niche work while C3 targets general application development; the mismatch was observed in the community discussions he cites ([I thought I was building a C replacement](https://c3-lang.org/blog/i_thought_i_was_building_a_c_replacement/), 2026-08-16).
- His own adoption analysis concedes C alternatives generally fail without a killer product or unique feature: "no matter how exciting that C alternative may look, it probably will fail" ([The case against a C alternative](https://c3-lang.org/blog/the-case-against-a-c-alternative/), 2022-08-07; [Do you know why your language will fail?](https://c3-lang.org/blog/do-you-know-why-your-language-will-fail/), 2022-02-10).
- Unsigned sizes by default: "Unsigned sizes: a five year mistake" — C3 defaulted sizes/lengths to unsigned from its early days and reversed the decision in 0.8.0 (the "szmageddon" change to signed `sz`), also dropping implicit signed/unsigned conversions; observed in the language's own codebase as the author describes removing `uint` usages and finding bugs ([Unsigned sizes: a five year mistake](https://c3-lang.org/blog/unsigned-sizes-a-five-year-mistake/), 2026-05-02).
- Overly powerful compile-time checks: `$checks()` was removed in 2023 because "its power comes from being inexact", making failures un-diagnosable; the lesson is that meta-programming power without precision is a liability ([Too much power, too poor accuracy](https://c3-lang.org/blog/too-much-power-too-poor-accuracy---the-story-of-checks-in-c3/)).
- Compile-time and reflection churn across 0.7–0.8: reflection was reworked, half the builtins removed (0.8.0), top-level `@if` replaced by `@feat` (0.8.3) — each breaking change costs the young user base ([0.8.0 blog](https://c3-lang.org/blog/0_8_0_the_core_language_is_settling/), [0.8.3 blog](https://c3-lang.org/blog/c3_0_8_3_feature_flags/)).
- Breaking changes every 0.x.0 release even in the "stable" 0.x series: 0.7.0 is explicitly incompatible with 0.6.8 code ([C3 0.7.0 blog](https://c3-lang.org/blog/c3-0-7-0-one-step-closer-to-1-0/)); docs admit drift ("Docs may not reflect current language state") ([Introduction](https://c3-lang.org/getting-started/introduction/)).
- LLVM backend costs: >98% of unoptimized compile time is LLVM codegen and linking, and LLVM "very much a backend for C/C++" leaves non-Clang codegen paths unreliable (observed by the author on c3c itself) ([How bad is LLVM really?](https://c3-lang.org/blog/how-bad-is-llvm-really/)).
- Safe-mode-only safety: implicit bounds/null checks and contracts exist only in safe mode and vanish at -O2, and `assert` silently degrades to an optimization hint; the author concedes the fast mode is "just as unsafe as C" ([Debugging](https://c3-lang.org/misc-advanced/debugging/), [The case against a C alternative](https://c3-lang.org/blog/the-case-against-a-c-alternative/)).
- No first-class C-header reuse: interop stayed manual (`extern` re-declaration with a long gotcha list for bit fields, qualifiers, atomics, and arrays), and the C-to-C3/C-header converter remains a help-wanted item rather than a shipped feature ([C Interop](https://c3-lang.org/language-common/cinterop/), [c3c README](https://github.com/c3lang/c3c/blob/master/README.md)).
- Platform overreach versus testing: WASM is "really incomplete" with no CI and "no one is really using it yet"; freestanding and MCU targets are untested; `c3c dist` and `c3c docs` were documented but unimplemented for years ([FAQ: Platform support](https://c3-lang.org/faq/), [c3c README support matrix](https://github.com/c3lang/c3c/blob/master/README.md), [Build commands](https://c3-lang.org/build-your-project/build-commands/)).
- Interactive debugging maturity: debug-info generation has a multi-year issue trail (2021–2026), indicating gdb/lldb-style stepping is not a strength compared with the sanitizer-based tooling ([issue #324](https://github.com/c3lang/c3c/issues/324), [issue #3358](https://github.com/c3lang/c3c/issues/3358)).
- Ecosystem reach is still small relative to the ambition: the showcase is dominated by bindings, games, and small tools; no official package manager exists yet, and no company or product-scale adoption is documented (unverified if any exists).

## 9. Verdict for Elseon

- Classification: idea source — the strongest one among Camp 1 candidates — not a model.
- `documents/08-related-work.md` classifies C3 as "probably the closest philosophical sibling to Elseon"; that is verified on constraints (no GC, manual memory, LLVM backend, C ABI, C-shaped syntax, modules over headers) and refined on three points: (1) C3 is genealogically a fork of C2, not an independent sibling ([Design Goals](https://c3-lang.org/getting-started/design-goals/)); (2) C3's memory strategy converged on arenas with implicit allocator defaults and compiler-injected pools, which Elseon's no-hidden-allocations rule excludes; (3) C3 targets general application development with a batteries-included standard library, while Elseon targets the kernel — C3's freestanding story is untested.
- Not a model because C3 admits behavior Elseon's kernel test forbids (mode-dependent implicit checks and asserts, implicit container allocation), lacks PFE header ingestion, and has drifted from C's surface more than Elseon intends to (removal of `const`/`volatile`, `fn`, mandatory case-based naming).
- C3 remains the best single source of proven design decisions in Elseon's design space, precisely because it is the longest-running, most complete attempt with the same constraints.

Borrow list:

- Module system replacing user-code headers and the preprocessor — proven viable at standard-library scale; matches Elseon's semantic-import instinct.
- Optionals with pointer-sized faults, explicit `!`/`catch`/`try`/`defer`, no exceptions — zero-overhead error handling with no hidden control flow.
- Slices as pointer + length with `foreach` — deterministic, ABI-friendly iteration and bounds-passing idiom.
- Scope-based arena ("temporary allocator") with an explicit `@pool` block — efficient, leak-resistant manual memory; Elseon would require the allocator to be explicit rather than defaulted.
- Fixed-width integer types, defined wrapping overflow, no implicit narrowing, defined evaluation order — deterministic semantics C never standardized.
- "Data is inert": no constructors/destructors and no RAII — independent validation of Elseon's zero-hidden-control-flow rule.
- `@packed`/`@align`/endianness attributes and `bitstruct` for explicit bit layout — vocabulary for deterministic layout control.
- Zero-initialization by default with an opt-out — removes an entire class of C bugs at no hidden-control-flow cost.
- Feature-removal discipline and honest doc drift warnings — governance pattern for a pre-1.0 language.
- Integrated `@test`-based test, benchmark, and docgen story in the compiler driver — keeps CI-verifiability cheap.

Avoid list:

- Implicit allocator selection by uninitialized standard containers (`List.push` without an allocator) — a hidden allocation by Elseon's standard.
- Compiler-injected `@pool` around `main` and safe-mode-only bounds/null checks/contracts that vanish at -O2 — hidden control flow whose meaning changes with optimization level.
- `assert` and `unreachable` whose semantics change between safe and unchecked mode — silent semantic drift.
- Removing `const`/`volatile` qualifiers and atomics keywords — harms C-header ingestion fidelity and const-correctness, which Elseon's PFE needs.
- Hand-written `extern` re-declaration as the primary C-interop path — Elseon's differentiator is ingesting the headers instead; keep hand externs only as an escape hatch.
- Marketing the language by what it replaces ("C alternative") instead of what it is for — the author's own documented mistake.
- Breaking changes collected per 0.x.0 for a decade before 1.0 — Elseon should freeze its core earlier than C3 (1.0 targeted 2028).
- Mandatory case-based identifier grammar for parseability — works, but sacrifices C identifier freedom for no kernel-test benefit.
- Promising targets without CI (WASM, freestanding) — C3's untested-platform rows are a lesson in scope discipline.

## 10. Evidence

- [C3 Programming Language — home](https://c3-lang.org/) — official landing; tagline "ergonomic, safe evolution of C"; observed 2026-09-03.
- [C3 docs: Introduction / What is C3](https://c3-lang.org/getting-started/introduction/) — positioning, feature claims, docs-drift warning.
- [C3 docs: Design goals and C3 background](https://c3-lang.org/getting-started/design-goals/) — goals; C3 as evolution of C; fork of C2 by Bas van den Berg.
- [C3 docs: Hello World](https://c3-lang.org/getting-started/hello-world/) — sample surface: `import std::io;`, `fn void main()`.
- [C3 docs: Building C3 from source](https://c3-lang.org/getting-started/compile/) — CMake/LLVM build, platforms.
- [C3 docs: C to C3, a guide for C programmers](https://c3-lang.org/c-to-c3/a-guide-for-c-programmers/) — syntax deltas, zero-init, qualifier removal, modules vs `#include`, defined semantics.
- [C3 docs: Memory management](https://c3-lang.org/language-common/memory/) — malloc/free, allocators, temp allocator, implicit container defaults, `@pool`.
- [C3 docs: Optionals (essential)](https://c3-lang.org/language-common/optionals-essential/) — optional/fault error handling.
- [C3 docs: Structs and unions](https://c3-lang.org/language-common/structs-and-unions/) — named structs, `@packed`, C-compatible unions, subtyping.
- [C3 docs: C interoperability](https://c3-lang.org/language-common/cinterop/) — ABI claim, `extern`, `@cname`, `@export`, gotchas list.
- [C3 docs: Modules](https://c3-lang.org/language-fundamentals/modules/) — module/import system.
- [C3 docs: Defer](https://c3-lang.org/language-common/defer/) — defer semantics and order.
- [C3 docs: Debugging](https://c3-lang.org/misc-advanced/debugging/) — safe vs unchecked mode table, sanitizers, VMEM_TEMP, tracking allocators.
- [C3 docs: Build commands](https://c3-lang.org/build-your-project/build-commands/) — c3c commands; `dist`/`docs` not yet added.
- [C3 docs: Project configuration](https://c3-lang.org/build-your-project/project-config/) — `c-sources`, `c-compiler`, targets, JSON project file.
- [C3 docs: FAQ](https://c3-lang.org/faq/) — memory management, C interop, naming grammar, closures, JSON/TOML, package-manager stance, WASM status, changes from C.
- [C3 docs: FAQ — all features](https://c3-lang.org/faq/allfeatures/) — exhaustive feature delta vs C, fixed widths, attributes, bitstruct.
- [C3 docs: FAQ — comparison](https://c3-lang.org/faq/compare-languages/) — C3 vs C, C++, Rust, Zig, Jai, Odin, D.
- [C3 docs: FAQ — rejected ideas](https://c3-lang.org/faq/rejected-ideas/) — no constructors/destructors; no string interpolation (implicit allocation); C type naming kept.
- [C3 docs: Roadmap](https://c3-lang.org/getting-started/roadmap/) — 0.8.x production caveats; 0.9 (2027-06), 1.0 (2028-06); stdlib maturity.
- [C3 blog: Removing features, gaining freedom](https://c3-lang.org/blog/removing-features-gaining-freedom/) (2021-10-17) — removal of untyped literals.
- [C3 blog: Do you know why your language will fail?](https://c3-lang.org/blog/do-you-know-why-your-language-will-fail/) (2022-02-10) — adoption failure modes.
- [C3 blog: The case against a C alternative](https://c3-lang.org/blog/the-case-against-a-c-alternative/) (2022-08-07) — why C alternatives fail; safe-mode strategy critique.
- [C3 blog: Some language design lessons learned](https://c3-lang.org/blog/some-language-design-lessons-learned/) (2023-04-03) — parseability, remixes, macro readability.
- [C3 blog: Too much power, too poor accuracy — the story of $checks in C3](https://c3-lang.org/blog/too-much-power-too-poor-accuracy---the-story-of-checks-in-c3/) (2023-10-25) — `$checks` removal.
- [C3 blog: How bad is LLVM really?](https://c3-lang.org/blog/how-bad-is-llvm-really/) (2024-01-18) — LLVM codegen >98% of compile time; backend assessment.
- [C3 blog: C3 0.7.0 — one step closer to 1.0](https://c3-lang.org/blog/c3-0-7-0-one-step-closer-to-1-0/) (2025-03-30) — monthly releases, breaking 0.x policy, Tsoding effect.
- [C3 blog: How C3 Manages Memory Without Leaks, GC, or Borrow Checkers](https://c3-lang.org/blog/how-c3-manages-memory-without-leaks%2C-gc%2C-or-borrow-checkers/) (2025-07-11) — temp allocator as new default; compiler-injected `@pool`.
- [C3 blog: Unsigned sizes: a five year mistake](https://c3-lang.org/blog/unsigned-sizes-a-five-year-mistake/) (2026-05-02) — signed `sz` default in 0.8.0.
- [C3 blog: C3 0.8.0 — the core language is settling](https://c3-lang.org/blog/0_8_0_the_core_language_is_settling/) (2026-05-14) — 0.8.0 changes, toolchain, stdlib.
- [C3 blog: C3 0.8.3 — feature flags](https://c3-lang.org/blog/c3_0_8_3_feature_flags/) (2026-08-13) — `@feat` replaces top-level `@if`.
- [C3 blog: I thought I was building a C replacement. I was wrong](https://c3-lang.org/blog/i_thought_i_was_building_a_c_replacement/) (2026-08-16) — positioning post-mortem.
- [c3lang/c3c repository](https://github.com/c3lang/c3c) — README, support matrix, licensing, help-wanted C-to-C3 converter; observed 2026-09-03.
- [c3lang/c3c releases](https://github.com/c3lang/c3c/releases) — v0.8.3 (2026-08-12), nightly prereleases; release history from 2021.
- [c3lang/c3c src tree](https://github.com/c3lang/c3c/tree/master/src) — compiler sources in C (`src/main.c`, `src/compiler/*.c`); observed 2026-09-03.
- [c3lang/c3c CMakeLists.txt](https://github.com/c3lang/c3c/blob/master/CMakeLists.txt) — LLVM 19–24, default 23, `C3_FETCH_LLVM`.
- [c3lang/c3c issue #324 — Full Debug Info](https://github.com/c3lang/c3c/issues/324) (2021) — debug-info work history.
- [c3lang/c3c issue #3358](https://github.com/c3lang/c3c/issues/3358) (2026) — debug-info-related compiler crash.
- [c3lang/c3c issue #1456 — The big 1.0](https://github.com/c3lang/c3c/issues/1456) — feature list referenced by the roadmap for 1.0.
- [c3lang/c3-showcase](https://github.com/c3lang/c3-showcase) — community projects: emulators, bindings, UEFI tools, muon-kernel microkernel.
- [c3lang/vkQuake](https://github.com/c3lang/vkQuake) — mixed C/C3 build demonstration.
- [c3lang/c3c GitHub Actions workflows](https://github.com/c3lang/c3c/tree/master/.github/workflows) — CI presence; observed 2026-09-03.
- [Hacker News: Show HN — The C3 programming language (C alternative language)](https://news.ycombinator.com/item?id=43569724) (2025-04-03) — external attention data.
- [documents/08-related-work.md](documents/08-related-work.md) — the classification this study verifies and refines (inspect only).
- [documents/07-elseon-language.md](documents/07-elseon-language.md) — Elseon's kernel test and principles used as the comparison standard.
