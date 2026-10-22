# Cake versus C

This note compares Cake to C as the baseline, per the criteria in
`prompts/11-c-comparison-criteria.md`, and feeds the synthesis task
`prompts/tasks/07-c-comparison-synthesis.md`.
All documentation quotes come from the Cake GitHub repository
(https://github.com/thradams/cake), because the official site
(https://thradams.com/cake/) was unreachable from the study environment on
2026-09-03 (HTTP connection timeout); the site content is published in the
repository.
Live facts carry the verification date 2026-09-03.

## 1. Positioning

Baseline (C): a general-purpose systems language standardized by WG14, compiled
by many competing compilers (GCC, Clang, MSVC), with no runtime and a
preprocessor-based ecosystem of headers and macros.

Cake positions itself as "C23 and beyond", not as a rival to C.
The project describes Cake as "a compiler front end written from scratch in C
by a human, implementing the C23 language specification and beyond", and as "a
platform for experimenting with new features, including C2Y language proposals,
safety enhancements, and extensions such as literal functions and defer
statements" (README: https://github.com/thradams/cake).
Cake is a source-to-source compiler: "a source-to-source C compiler that
translates modern C (C99 through C2Y) into C89-compatible output, suitable for
compilation by existing toolchains such as GCC and MSVC" (Manual section 1:
https://github.com/thradams/cake/blob/master/manual.md).
The C89 backend output is "pipelined with existing or old compilers to produce
executables" (README).
The intended audience is C programmers who want newer or experimental C on
older toolchains, and C maintainers who want checked ownership and nullability
without leaving C.
The safety claim is additive: "Cake aims to enhance C's safety by providing
high-quality warning messages and advanced flow analysis, including object
lifetime checks" (README).
Stated use cases are: a static analyzer alongside other compilers (SARIF
output for Visual Studio and Visual Studio Code), a C23-to-C89 preprocessor, a
cross-compiler that uses the target platform's headers, and an AST library
(README).
The project keeps "alignment with the standard specifications and ongoing
development of C, ensuring full compatibility" and compares itself to CFront,
the first C++ compiler that translated C++ to C (README, "Cake x CFront"
section).

Classification check against `documents/08-related-work.md` (Camp 2, "C23 and
beyond: a superset of C with modern features that can desugar back to C").
The classification is verified in essence and refined in three points.
First, Cake is a front end and transpiler, not a full compiler: native code
generation is delegated to GCC, MSVC, or Clang, so "desugar back to C" is
literal — C input becomes C89 source that a second compiler turns into object
code (Manual section 5.1).
Second, most of the "modern features" are later-standard C (C23 and C2Y
proposals) rather than Cake-proprietary; the proprietary layer is thin
(ownership qualifiers, defer, try/catch, checked expressions, built-in
assert/offsetof/countof/type traits) (Manual sections 10 and 11).
Third, the project's stance is standards tracking plus diagnostics — the most
conservative member of Camp 2, closer to a supercompiler or static analyzer
than to a competing language.
It avoids the C++ failure mode ("a second language bolted onto C") by adding no
new core semantics, but it pays the Camp 2 price: it cannot change C's
semantics either, only warn about them.

## 2. Kernel-test adherence

Baseline (C): no GC and no runtime by language definition; allocation only
through explicit library calls; control flow only where written; struct layout
deterministic per target ABI.
For each of the four guarantees, the section states what Cake does and whether
it works in practice.

No garbage collection / no hidden runtime — passes.
Cake emits C89 source; the final compiler produces the object code; no runtime,
runtime library, or GC exists at any stage (Manual section 1, section 5.1;
README).
The ownership checker is compile-time only: "Only static analysis behavior
changes; the runtime behavior of your program is unaffected" and "Cake also
proves the ownership rules statically, with no runtime overhead"
(ownership.md: https://github.com/thradams/cake/blob/master/ownership.md).
No GC or runtime component appears anywhere in the project documentation;
observed in the documentation, no counter-evidence found.

No hidden allocations — passes for Cake's own semantics, with two allocations
the compiler performs on the source's behalf.
The C89 backend introduces local temporaries (for example, a temporary for the
Elvis operator with side effects) but no dynamic allocation (Manual section
10.12).
The C23 optional VLA is implemented and "allocated on the stack using alloca",
with the note that "the use of VLA is discouraged" (Manual section 9.1) — an
allocation, but requested by an explicit VLA declaration in the source.
Ownership contracts generate no cleanup code: unlike RAII, "no code is
generated to call them automatically"; the analyzer verifies that the source's
own free calls fulfill the contract (ownership.md, "Comparison with C++ RAII").
Works in practice for the documented design; the compiler never inserts a
hidden heap operation.

No hidden control flow — passes for the C core, fails the strictest reading
for parts of the extension layer.
Compiling standard C adds nothing: the C89 output is a faithful lowering of the
input semantics.
The opt-in extension constructs that execute at points other than where they
are written are the following.
`_Defer` executes its statement or block when the enclosing scope exits, in
reverse order of appearance; it cannot be jumped over with goto and its block
may not break, continue, return, or goto out (Manual section 10.5).
`try`/`throw`/`catch` is "a structured local-jump mechanism"; it "cannot
propagate across function boundaries. This is by design" (Manual section 11.2).
The postfix checked expression `expr!` transfers to the nearest enclosing
catch when the value is zero or null; the manual calls it "a very experimental
feature" (Manual section 11.3).
`assert` is "a built-in statement rather than a macro because flow analysis
need it even in release builds"; its effect is equivalent to
`if (!(expression)) exit(1);` (Manual section 11.1).
For Elseon's kernel test — every branch and call visible in the source — the
scope-exit execution of `_Defer` and the implicit branch of the `!` operator
are the constructs to reject or re-express.
Elseon's design admits destructor-like scopes only when explicit, with "no
hidden control flow at scope exit beyond what the source spells out"
(documents/07-elseon-language.md, section 4).
`try`/`catch` is visible local syntax, and `_Defer` mirrors a C2Y proposal
(N3734) rather than an Elseon invention.
Works in practice: control-flow extensions are opt-in and spelled in the
source, but they do insert execution the writer did not write at that point.

Deterministic memory layout — passes by inheritance, with a delegated-codegen
caveat.
Cake changes no layout semantics: struct layout, padding, and alignment remain
C's, decided by the downstream compiler for the selected target.
The `-target` option "controls integer sizes, alignment, and the style of
generated C89 output" (Manual section 4.4).
The C89 rewrite is textual — no nested struct/union definitions, typedefs
expanded inline, enums replaced by integer constants — and preserves the types
(Manual section 5.1).
Because Cake never emits machine code, layout determinism equals the
determinism of the chosen downstream compiler and ABI.
Cross-target correctness depends on Cake's target model matching the real
compiler's ABI; that is a risk, and no failure was observed in this study
(unverified in practice).
Programmer layout control remains C's own: field order, explicit padding,
`_Alignas` (Manual section 8.9), and bit-fields (which the C89 output currently
requires; Manual section 5.1).

## 3. Syntax family

Baseline (C): type-first declarations, pointer and array semantics, struct
layout control, C statement forms; Elseon's chosen family is C and JavaScript.
Cake's surface IS C (C23): it implements the C standard grammar, so the
C-family question is satisfied by construction.
There is no JavaScript-family influence to compare (not applicable): Cake
designs no new surface, it tracks the standard's own evolution.
Minimal cognitive friction: zero for a C programmer compiling standard C; the
extensions read like C — qualifiers after `*` (`char * _Owner _Opt`), `_Defer
{ ... }`, `try`/`catch`, postfix `!`, `_Countof` (Manual sections 9 to 11).
Newer conveniences such as `auto`, `typeof`, `constexpr`, and `nullptr` are
C23's own features, not Cake inventions (Manual sections 9.8 to 9.13).
Surface choices Elseon would reject under the kernel test: the scope-exit
`_Defer` sugar and the postfix checked `!` (both insert execution at points not
written in the source), and arguably `assert` as a compiler-built runtime check
(which mirrors the C macro's semantics but makes the check implicit in the
language rather than spelled out at the call site).
Cake removes nothing from C: the C23 preprocessor remains central, including
macros, `#embed`, and the experimental C2Y `#def`/`#enddef` macro blocks
(Manual sections 9.16 to 9.21, 10.3).
That is evidence that staying inside the textual-macro world remains workable,
while keeping the macro tax: textual includes and headers that carry no safety
annotations (see section 4).

## 4. C interoperability

Baseline (C): the interoperability reference is C itself — headers, ABI, and
mixed C/C++ linkage are the ecosystem's universal interface.
FFI and C-compatible ABI: inherited trivially, because Cake's output is C.
There is no boundary to cross and no runtime shim; function prototypes are
generated automatically in the C89 output (Manual section 5.1).
The command line mirrors GCC and MSVC (`-I`, `-D`, `-E`, `-H`, `-o`), GCC
built-ins and attributes are recognized (`__builtin_offsetof`,
`__attribute__`, `__typeof__`, varargs built-ins), and MSVC extensions are
recognized (`__declspec`, `__cdecl`, `__fastcall`, `__stdcall`) (Manual
sections 4.1, 12, 13).
Drop-in C compilation: partial.
Cake is not a `zig cc`-style drop-in to an executable; it is a mandatory
pre-stage — `cake source.c` emits C89 that GCC, MSVC, or Clang then compiles
(README; Manual section 3).
It can compile standard C input and claims cross-compilation by using the
target platform's headers: "on Windows it can use Linux headers and generate
GCC-compatible code for Linux, and vice versa" (README).
Where drop-in fails, features that cannot lower to C89 are unimplemented
(section 5 and section 8).
C-header reuse: textual and preprocessor-based, exactly C's model.
Include directories are enumerated per platform in a `cakeconf.h` file using
`#pragma dir` (Manual section 2.2), and Cake preprocesses headers like any C
compiler.
There is no equivalent of Elseon's PFE: headers are not ingested as first-class
semantic modules with checked boundaries; they remain text.
The friction this causes is documented by the author: "currently cake uses
existing msvc and gcc headers. These headers do not have any owner qualifiers.
The temporary solution, is the re-declare the malloc etc when compiling with
cake and not complain withe the function signature difference only by owner
qualifiers" (Hacker News, 2024-02-20:
https://news.ycombinator.com/item?id=39436623).
The compatibility strategy is to define `_Owner` and friends as empty macros in
a header (an "Ownership Feature Strategy (Inspired by stdbool.h)") so the same
source compiles under GCC, Clang, and MSVC and is only analyzed by Cake
(author, Hacker News, 2024-02-20).
This is precisely the boundary that Elseon's semantic header import would make
typed and checked once, instead of re-declared per toolchain.

## 5. Toolchain

Baseline (C): mature compilers (GCC, Clang, MSVC) with machine-code backends,
standard build tools, debuggers, and continuous integration everywhere.
Backend: Cake has no machine-code backend; it emits C89 source that GCC, MSVC,
or Clang compiles (README; Manual section 5.1).
The backend is not LLVM, and optimization is whatever the downstream compiler
achieves on the emitted C89.
Build story: bootstrap is trivial — from the `src` directory, `gcc build.c -o
build && ./build` (Clang and MSVC variants exist), and the build "will build
cake.exe, then run cake on its own source code" (README), so the front end is
self-hosting in C.
A web build compiles an amalgamated `lib.c` with Emscripten (README), and a web
playground runs at http://cakecc.org/playground.html (reachable, verified
2026-09-03).
Debugging and IDE integration: `-line-directives` emits `#line` directives in
the generated C89 to preserve source locations; diagnostic formats are gcc,
msvc, and ide; `-sarif` produces SARIF output compatible with the Microsoft
SARIF Viewer; Cake runs as a Visual Studio custom build tool or external tool
so the developer can "run/debug normally" (Manual sections 4.2, 4.7).
A Cake IDE exists and "was developed with the help of AI tools... will be
reviewed, refined, and gradually humanized" (README).
Debugging always happens on the second compiler's binary through the generated
C89; the practical quality of that mapping was not independently assessed
(unverified).
Maturity: stated as pre-1.0 — "Cake is still in development and has not yet
reached a stable version" (README).
Documented gaps: complex types, universal character names, `_Atomic`, `_BitInt`,
decimal floating types, and improved tag compatibility are "Not implemented"
(Manual sections 7.15, 7.16, 8.4, 9.21, 9.22, 9.23).
`inline` functions are "equivalent to static, since Cake does not currently
perform function inlining" (Manual section 7.9).
The roadmap lists "function literal and local functions implementation",
"Making it usable as C89 backend and fixes", and "Flow3 is landing!" (README).
Release tags are sparse and informal: v0.7.21 (2024-04-19), 0.9.36_edit_mode
(2024-12-01), and tests_ok (2025-11-07) (GitHub releases API, verified
2026-09-03).
CI-verifiability: yes — the GitHub Actions workflow ci.yaml builds and runs the
test suite (`./build test`) on Linux GCC, macOS Clang, and Windows MSVC (x86
and x64) on push and pull request (https://github.com/thradams/cake/blob/master/.github/workflows/ci.yaml,
verified 2026-09-03).
A large test suite ships with the project and runs as `./build test` on any
platform (README).
Kernel-adjacent constraint: Cake is a host tool with no runtime to deploy, but
it inserts a transpilation stage into a build and requires a C89-accepting
downstream compiler.
Strict C89 output conflicts with kernel-style GNU C usage beyond the recognized
GCC built-ins (Manual section 12), and the target list — x86_x64_gcc, x86_msvc,
x64_msvc, macos_arm64, catalina, ccu8 — contains no freestanding or kernel
target; ccu8 is described as "Embedded / custom target" (Manual section 4.4).
Kernel use of Cake: none claimed and none observed (no evidence found).
License: GPLv3 with an addendum restricting AI-model-training use (LICENSE:
https://github.com/thradams/cake/blob/master/LICENSE; the README states "Cake
uses the same license of GCC. GPLv3").
The GitHub API reports the license as Other/NOASSERTION because of the
addendum (verified 2026-09-03).
Embedding Cake code into a non-GPL toolchain is problematic under GPLv3.

## 6. Ecosystem and adoption

Baseline (C): the most widely used systems language, with every toolchain,
every OS, and fifty years of code.
Maintainer: Thiago Adams (GitHub: thradams; Porto Alegre, Brazil; profile:
"Software engineer interested in C/C++ compilers, IOT, SCADA").
The commit history is single-maintainer: 1,114 commits by thradams; the largest
external contributor has 20 commits (GitHub contributors API, verified
2026-09-03).
Activity and interest (GitHub API, verified 2026-09-03): repository created
2022-08-16; about 701 stars, 42 forks, 16 open issues; default branch main;
last push 2026-09-03 — very active.
Real-world use observed:
- Dogfooding: Cake's own source is checked with Cake's ownership analysis and
  still compiles with GCC, MSVC, and Clang via the empty-macro header strategy;
  the author reports "the real experience so far is the cake source itself" and
  that the Cake code "has been successfully converted" to ownership annotations
  (Hacker News, 2024-02-20).
- Catalina toolchain for the Parallax Propeller: a community announcement
  titled "Catalina: Now you can have your Cake and eat it too! - C89, C99, C11
  or C23!" (https://forums.parallax.com/discussion/comment/1568244/), consistent
  with Cake's `catalina` and `ccu8` targets (Manual section 4.4).
  This is title-level evidence: the forum page body was not retrievable from
  the study environment on 2026-09-03.
- Hacker News reception: "Cake – C23 and Beyond (2023)" (2024-02-20, about 172
  points) and "Static Ownership Checks for C" (2023-09-05).
  Reception is split: interest in diagnostics and static analysis is real;
  skeptics question annotation-based and optional safety (see section 8).
Not observed: any kernel project, any major C project, or any benchmark using
Cake.
The author states that only Cake itself uses the ownership checks: "just cake
is using. And there is a lot of work to do" (Hacker News, 2024-02-20).
Maintenance status: active but pre-1.0, no stable release, informal release
process, small external contributor base.
License: GPLv3 plus the AI-training-restriction addendum (LICENSE, verified
2026-09-03).

## 7. What worked

Ideas proven in practice, with the place of observation.
1. Transpiling to C89 and reusing mature compilers worked as an architecture:
   one front end serves MSVC, GCC, and Clang and can cross-target using foreign
   headers; the CI matrix builds and tests on three host compilers (ci.yaml,
   verified 2026-09-03).
   Observed in project documentation and CI practice.
   The lesson for Elseon is "never write your own backend"; Cake chose "emit
   C", Elseon chooses LLVM.
2. Implementing the C standard ahead of mainstream compilers worked as a
   laboratory: the manual documents feature status per standard with WG14
   N-document references (C99, C11, C23, C2Y sections), and the project
   experiments with C2Y proposals (defer N3734, if-declarations N3388, function
   literals N3679, statement expressions N3643, Elvis N3804, and more).
   Observed in the manual; a working front end is the best vehicle for language
   evolution (PFE applied to the C standard itself).
3. High-quality, configurable diagnostics worked as the project's core
   differentiator: warnings are numbered, individually enable/disable-able,
   promotable to errors, and style checking covers gnu, llvm, google, chromium,
   mozilla, webkit, microsoft, and cake conventions; SARIF output plugs into
   Visual Studio and Visual Studio Code (diagnostics.md:
   https://github.com/thradams/cake/blob/master/diagnostics.md; Manual section
   4).
   Observed in project documentation; Elseon should match this tooling quality
   from day one.
4. Compile-time ownership and nullability contracts with zero runtime cost,
   checked on ordinary C pointers, worked on the project's own codebase:
   `_Owner`, `_Opt`, `_View`, `_Dtor`/`_Clear` parameter contracts, and
   `_Uninitialized`/`_Clear` pointee contracts on malloc/calloc — "no runtime
   overhead" (ownership.md).
   First-party report: the Cake source was converted and only a few linked-list
   functions needed disabled checks (pop_front, pop_back) (author, Hacker News,
   2024-02-20).
5. Pragma-gated opt-in plus empty-macro headers worked as an incremental
   migration story: the same annotated source compiles under GCC, Clang, and
   MSVC and is analyzed only by Cake; rules enable file-by-file or
   region-by-region (ownership.md; author, Hacker News, 2024-02-20).
   This answers the "forked C dialect" objection that kills most C dialects.
6. Making tooling-critical constructs built-ins instead of macros worked:
   assert, offsetof, `_Countof`, and type traits are compiler-built so the flow
   analysis can reason about them (Manual section 11).
   Observed in project documentation; this matches Elseon's instinct to give
   the compiler real semantics instead of textual macros.
7. Static analysis over runtime checks for leaks in cold code paths is a
   compelling argument the author makes from production experience: leaks in
   rarely executed code escape tests and surface in production, while a
   compiler check finds them at build time (author, Hacker News, 2024-02-20).
   Idea source for Elseon's own safety guarantees.

## 8. What did not work

Failures, dead ends, and pitfalls, with the place of observation.
1. C89 as an emission floor limits the language: features without a C89
   lowering are simply "Not implemented" — complex types, universal character
   names, `_Atomic`, `_BitInt`, decimal floats, improved tag compatibility
   (Manual sections 7.15, 7.16, 8.4, 9.21, 9.22, 9.23).
   Hex-float emission is lossless only up to 64-bit doubles: "Do not rely on
   the exact value of a long double constant beyond double precision" (Manual
   section 7.5).
   The C89 output still requires bit-fields (Manual section 5.1), and VLA
   lowering relies on alloca, which is not C89 (Manual section 9.1).
   Observed in project documentation: a transpiler target must be the least
   expressive dialect, and every C standard generation widens the gap.
2. The front end performs no optimization: "inline functions in Cake are
   equivalent to static, since Cake does not currently perform function
   inlining" (Manual section 7.9).
   Lowered C89 — no switch statements, no const, statics hoisted to file scope
   (Manual section 5.1) — must be re-optimized by the second compiler, whose
   optimizer may not recover the original structure.
   Observed in project documentation.
3. The analysis is not inter-procedural: "Because Cake's analysis is not
   inter-procedural, it cannot infer postconditions from called functions",
   which forces `//lint N` suppressions (ownership.md).
   The author admits checks were disabled in a few linked-list functions
   (author, Hacker News, 2024-02-20).
   Observed in project documentation and first-party reports: local-only
   reasoning pushes contracts into annotations and suppressions.
4. The retrofit burden on third-party code is the central obstacle: unannotated
   system headers force re-declarations ("the temporary solution, is the
   re-declare the malloc etc."), and commenters argue annotation-first schemes
   cannot retrofit real libraries such as OpenSSL, whose ownership semantics
   change between releases (woodruffw, Hacker News, 2024-02-20).
   Skeptics add that optional checks can be bypassed by extracting raw pointers
   from controlled ones — "C safety addons like this (there have been many)...
   Optional memory safety isn't" (Animats, Hacker News, 2024-02-20) — and that
   a half-measure next to Rust's guarantees is unconvincing (pizlonator, Hacker
   News, 2024-02-20).
   The author concedes "converting code can be challenging" and that only Cake
   itself uses the checks so far (Hacker News, 2024-02-20).
   Observed in community discussion.
5. The single-maintainer, pre-1.0 lifecycle constrains the ecosystem: sparse
   informal tags, one dominant contributor, README disclaimers that the
   project "has not yet reached a stable version", and a GPLv3 license with an
   AI-training addendum (README; LICENSE; GitHub API, verified 2026-09-03).
   Observed in repository state: adoption beyond self-use and one embedded
   toolchain is negligible.
6. The superset tradeoff — the Camp 2 price — is structural: Cake cannot fix
   C's semantics (undefined behavior, bounds, implicit conversions); it can
   only warn about them.
   Community observation: warnings do not remove the C bug classes unless a
   whole project opts in and stays opted in, and no tool enforces that here
   (Hacker News, 2024-02-20).
   `documents/08-related-work.md` classifies supersets as "compatible but
   inherit C's baggage"; Cake is the cleanest case of that tradeoff because it
   changes the least.

## 9. Verdict for Elseon

Classification: idea source.
Cake is not a model for Elseon: it is not a language design to emulate — no
LLVM codegen, no new surface, it stays textually inside C with the
preprocessor intact, and it is GPLv3.
Cake is not on the avoid list either: most of its lessons are positive and
cheap to borrow.
What Elseon avoids is the Camp 2 superset strategy itself, not the project's
individual ideas.

Borrow list, each with a one-line rationale:
- Compile-time-only ownership and nullability annotations over ordinary
  pointers (`_Owner`/`_Opt`/`_View`, pragma-gated) — lifetime safety with zero
  runtime cost and incremental adoption, directly usable at Elseon's C-header
  boundaries.
- Pragma enablement plus empty-macro headers so annotated code still compiles
  everywhere — an incremental-compatibility lesson for any Elseon feature that
  wraps existing C code.
- Analyzer-integrated built-ins for constructs C implements with macros
  (assert, offsetof, countof, type traits) — the compiler should understand
  semantics, not text; the same instinct as Elseon's semantic header import.
- Built-in pointee contracts for malloc/calloc (`_Uninitialized`/`_Clear`) —
  the compiler knowing standard allocator semantics catches use-before-init and
  null-passing bugs at compile time.
- Numbered, configurable, IDE-integrated diagnostics (SARIF, gcc/msvc formats)
  and style checking — tooling quality is a differentiator to ship from day
  one.
- The "standards ahead of compilers" strategy as PFE for language evolution —
  track C2Y proposals and their WG14 N-documents as a live design corpus for
  Elseon's feature justifications.
- Intra-procedural flow analysis that narrows nullability through branches —
  cheap, high-value static checks before any cross-function machinery (Cake's
  Flow3 samples).
- A web playground for language evaluation — a zero-install harness for the
  conformance corpus.

Avoid list, each with a one-line rationale:
- C89 (or any lowered old-C) as the codegen target — it becomes the language's
  ceiling, with unimplementable features and lossy rewrites (Manual sections
  7.5, 7.15 to 9.23); Elseon emits through LLVM instead.
- Scope-exit `_Defer` and postfix checked `!` as surface syntax — their
  implicit execution points violate Elseon's zero-hidden-control-flow standard
  unless re-expressed as explicit statements (Manual sections 10.5, 11.3).
- Optional, annotation-only safety without mandatory boundaries — if checks can
  be silenced per function or bypassed by raw-pointer extraction, the guarantee
  is advisory; Elseon should make safety part of the type and boundary system
  (Hacker News skeptics, 2024-02-20).
- Inter-procedurally blind analysis with `//lint` suppression escapes — plan
  cross-function inference or document the local granularity, because
  suppressions accumulate exactly where bugs live (ownership.md; Hacker News,
  2024-02-20).
- Superset-of-C as the Elseon strategy — extending C in place keeps C's
  semantic baggage and cannot give checked boundaries at the header edge;
  Elseon's PFE header import is the third position that avoids both Camp 2
  failure modes (`documents/08-related-work.md`; this study, section 8.6).
- GPLv3-style compiler licensing with extra restrictions (the AI-training
  addendum) — take ideas, not code; binding Elseon's toolchain to Cake's
  license would be self-defeating (LICENSE).

## 10. Evidence

Primary sources (project documentation and repository, all fetched from the
GitHub repository on 2026-09-03):
- Cake repository (README: About, Features, Use cases, Build, Running cake,
  IDE, Road map, Cake x CFront, License):
  https://github.com/thradams/cake
- Reference Manual ("Cake C Compiler — Reference Manual"; C89 backend, targets,
  options, standard-by-standard feature status, extensions):
  https://github.com/thradams/cake/blob/master/manual.md
- Ownership and Nullable Contracts ("Last Updated: August 2026"; compile-time
  claims, RAII comparison):
  https://github.com/thradams/cake/blob/master/ownership.md
- Warnings reference (numbered warnings, configurability):
  https://github.com/thradams/cake/blob/master/diagnostics.md
- Flow3 analyzer samples (intra-procedural flow analysis):
  https://github.com/thradams/cake/blob/master/flow3.md
- CI workflow (Linux GCC, macOS Clang, Windows MSVC x86/x64; `./build test`):
  https://github.com/thradams/cake/blob/master/.github/workflows/ci.yaml
  (verified 2026-09-03)
- License file (GPLv3 with an AI-model-training-restriction addendum):
  https://github.com/thradams/cake/blob/master/LICENSE (verified 2026-09-03)
- Official documentation site — https://thradams.com/cake/readme.html and
  https://thradams.com/cake/index.html — unreachable from the study environment
  on 2026-09-03 (HTTP connection timeout); the same content is published in the
  repository.
- Web playground: http://cakecc.org/playground.html (reachable, verified
  2026-09-03).
- GitHub API repository metadata (created 2022-08-16, 701 stars, 42 forks, 16
  open issues, last push 2026-09-03, license Other/NOASSERTION) and
  contributors (thradams 1,114 commits):
  https://api.github.com/repos/thradams/cake and
  https://api.github.com/repos/thradams/cake/contributors (verified 2026-09-03)
- GitHub API author profile (Thiago Adams):
  https://api.github.com/users/thradams (verified 2026-09-03)

Community sources (observed reception and first-party statements):
- Hacker News, "Cake – C23 and Beyond (2023)", posted 2024-02-20, about 172
  points, with author participation:
  https://news.ycombinator.com/item?id=39436623
- Hacker News, "Static Ownership Checks for C", posted 2023-09-05:
  https://news.ycombinator.com/item?id=37394922
- Parallax forums, "Catalina: Now you can have your Cake and eat it too! -
  C89, C99, C11 or C23!" (Cake in the Catalina Propeller toolchain;
  title-level evidence — page body not retrievable from the study environment
  on 2026-09-03):
  https://forums.parallax.com/discussion/comment/1568244/

Repository context (inspected, not modified):
- `documents/08-related-work.md` — Camp 2 classification verified and refined
  in section 1 of this note.
- `documents/07-elseon-language.md` — the kernel test and Elseon's principles.
- `prompts/11-c-comparison-criteria.md` — the authoritative criteria.
