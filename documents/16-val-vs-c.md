# Val vs C

This study compares the Val language to C as the baseline, on the ten
dimensions of `prompts/common/04-c-comparison-criteria.md`.
It feeds the synthesis task
`prompts/tasks/07-c-comparison-synthesis.md`, which pools five such studies
(C3, Odin, Hare, Val, Cake).
The aim is to identify what was tried before, what worked, and what did not
work, so Elseon can borrow what worked and avoid what did not.

Identity note: the language studied here as "Val" is today named Hylo.
The GitHub organization was created as hylo-lang on 2021-01-14 and its main
repository on 2021-01-24, but the language was publicly presented under the
name Val during roughly 2022–2023, with the site www.val-lang.dev and the
GitHub path val-lang/val.
A commit by Dimi Racordon titled "Rename 'Val' to 'Hylo'" dated 2023-08-11
reverted the branding, and the project has since presented itself as Hylo,
"formerly Val", with the site hylo-lang.org.
Observed 2026-09-03: github.com/val-lang/val redirects to
github.com/hylo-lang/hylo, and www.val-lang.dev no longer resolves.
This study therefore evaluates the language under both names and treats the
current Hylo primary sources (site, repository, documentation) and the
archived Val-era sources as one continuous project.
Live-state facts carry the verification date 2026-09-03.

## 1. Positioning

What C does: C is the universal low-level systems baseline — minimal
semantics, explicit memory management, stable ABI, and the de facto bridge
between languages.
What Val changes: Val does not present itself as an "improved C" or a "C
replacement"; it positions against C++ and Rust as a "high-level systems
programming language" built on mutable value semantics (MVS) and generic
programming.
The archived Val homepage (2022-08-07 snapshot) states: "Val is a research
programming language to explore the concepts of mutable value semantics and
generic programming for high-level systems programming."
The current Hylo introduction (verified 2026-09-03) states: "Hylo is a
programming language that leverages mutable value semantics and generic
programming for high-level systems programming", and positions its goals as
overlapping "substantially with that of Rust and other commendable efforts,
such as Zig or Vale".
The claimed differentiator is "its focus on mutable value semantics for the
purpose of writing efficient, generic code" — memory safety and freedom from
aliasing bugs without C's manual discipline, without Rust-style lifetime
annotations, and without a garbage collector.
Its advertised aims (both 2022 and 2026 wording) are: "Fast by definition"
(ahead-of-time compilation, in-place mutation, "avoids hidden costs such as
implicit copies", no heavy dependence on the optimizer); "Safe by default"
("ordinary code is memory safe, typesafe, and data-race-free", with
"explicit, auditable opt-in" to unsafe constructs); and "Simple" ("borrows
heavily from Swift").
The Val-era homepage added a fourth headline aim, "Interoperable with C++",
which the current homepage has dropped from the aims list (see sections 4 and
8).
For whom: the project says Val/Hylo targets systems programming and
acknowledges in the introduction that it is a research language "under active
development and not ready to be used yet" — the identical sentence appears on
the 2022 Val homepage and the 2026 Hylo introduction.
Does the change work in practice: not yet demonstrable for real users, since
the project itself declares the language unusable as of 2026-09-03 (see
sections 5 and 6).
Classification check against `documents/08-related-work.md`: Camp 1
(fresh C-like designs) is broadly right, but the row "C-like syntax with
mutable value semantics, to kill aliasing bugs — newer" needs refinement:
the surface is Swift-shaped, not C-shaped (section 3); the alias-killing
value-semantics description is accurate; "newer" is accurate and even
generous, because the project remains pre-1.0 and officially "not ready to be
used yet" five years after the repository was created.

## 2. Kernel-test adherence

C baseline: C itself has no GC and no runtime beyond libc; allocation is
explicit (`malloc`/`free`); control flow is mostly visible, but macros,
`setjmp`/`longjmp`, and undefined behavior hide or corrupt control flow; struct
layout is ABI-defined and can be controlled with `#pragma` and attributes.
Val/Hylo deviates from that baseline toward automatic management, so each
Elseon kernel-test guarantee is assessed separately below.

No garbage collection / no hidden runtime:
- Stated by the project (design): memory management is compile-time directed;
the "Definite (De)Initialization" mandatory IR pass "ensures that all objects
are initialized before use (definite initialization) and deinitialized before
the end of their storage's lifetime (definite deinitialization), inserting
additional instructions if necessary".
- Stated by the project (papers): the 2021 paper "Native Implementation of
Mutable Value Semantics" says compilation "relies on stack allocation for
static garbage collection"; the 2022 JOT paper "Implementation Strategies for
Mutable Value Semantics" says "fixed-size values are allocated on the stack...
while dynamically sized containers use copy-on-write".
- Observed in the repository: the hosted standard library is linked through a
small C shims file, and free-standing mode requires only one externally
provided function, `halt`, which the docs illustrate as an infinite loop — no
runtime service, GC or otherwise, appears in the design.
- Caveat: no explicit official sentence "this language has no garbage
collector" was found in the primary sources consulted; and whether the current
compiler emits any runtime bookkeeping (for example reference counting for
copy-on-write buffers or escaping values) is unverified from these sources.
- Verdict: no tracing GC or managed runtime is described anywhere observed, so
the guarantee holds in spirit, but the mechanism is automatic compile-time
management, not manual management.

No hidden allocations:
- Val/Hylo does not make allocation explicit as a language rule; allocation is
automatic and implicit for dynamic containers and for values whose storage
must escape a scope.
- Stated by the project: the introduction claims Hylo "relies on its type
system to support in-place mutation and avoid unnecessary memory allocations"
and "avoids hidden costs such as implicit copies" — the promised absence is of
unnecessary copies, not of implicit allocation per se.
- Stated by the project (2022 roadmap): a planned guarantee is that "closures
do not require heap allocation unless the type of their environment is
erased".
- Observed in the standard library: low-level explicit allocation exists for
unsafe code (`malloc`/`free`/`aligned_alloc` are bound in LibC.hylo, and
Heap.hylo and Pointers+DynamicAllocation.hylo exist in the standard library),
but ordinary safe code never spells allocation out.
- Verdict: this fails Elseon's strict "no hidden allocations" guarantee; the
language's model is automatic memory management with optimization promises,
not visible allocation.

No hidden control flow:
- There is no textual preprocessor: a program is composed of file-based
modules with an API resilience boundary, and multi-file compilation replaces
header inclusion.
- Value movement is a linear discipline enforced at compile time: consuming
operations (assignment into a `var`, tuple initialization) "force-end the
lifetime" of the consumed binding, and use after consumption is a compile-time
error; the language tour draws the Rust `drop` analogy for explicit
deinitialization.
- The compiler automatically inserts deinitialization instructions at the end
of storage lifetimes, so synthesized scope-exit code exists by design even
though the source does not spell it out.
- Hylo's vocabulary includes deinitializable types (a `Deinitializable` type
appears in the homepage sample code), so user-declared deinitialization
behavior can attach to values; whether user-written deinit bodies run
implicitly at scope exit in the current compiler is unverified in the sources
consulted.
- Concurrency is designed to avoid "function colouring": the tour states
"concurrent code has the same syntax/semantics as non-concurrent code" with
`spawn` and `await` — but the same page warns the approach "is still under
design" and "only presents our current plans".
- No exceptions or `throw` constructs appear anywhere in the language tour
(absence noted; the complete language may differ, unverified).
- Verdict: Val/Hylo is far more explicit than C++ (no inheritance, no implicit
constructors, no exceptions, visible `&` mutation markers), but automatic
deinitialization and any future spawn machinery are compiler-generated
behavior, which Elseon's kernel test would require to be visible in source.

Deterministic memory layout:
- No language-level struct layout control (padding, alignment, field order
directives) was found in the primary documentation consulted.
- The standard library exposes runtime queries — `MemoryLayout<T>` with
`size()`, `stride()`, `alignment()` — which read the layout the compiler chose
rather than letting the programmer fix it.
- The C-interoperability thesis (2025) treats ABI correctness and memory
layout as problems to be solved on the C side through Clang, implying Hylo
does not today guarantee C-compatible layout of arbitrary Hylo types.
- Verdict: deterministic layout in Elseon's sense (language-specified layout
honored by the backend) is not part of the language's stated design; this
guarantee is unmet or at best unverified.

## 3. Syntax family

C baseline: C's surface is braces and semicolons, type-first declarations,
pointer and array syntax, and a small keyword set.
Val/Hylo surface: the syntax is Swift-shaped, not C-shaped: `fun` for
functions, `let`/`var` bindings, `inout` parameters, `subscript` declarations,
`type` and `typealias`, argument labels and `_` for unlabeled arguments,
tuples with labels, `&` prefixes for mutation, and `${...}` string
interpolation.
A typical sample from the current introduction:

```hylo
public fun main() {
  var (x, y) = ("Hi", "World")
  emphasize(&longer_of[&x, &y])
  print("${x} ${y}") // "Hi World!"
}
```

Cognitive friction for a C programmer: moderate to high; loops and braces are
familiar, but the type system vocabulary, parameter syntax, and the
redefinition of `&` are new.
The docs explicitly warn that "`&` in Hylo does not mean 'address of' — it
simply marks a mutation", and that all types are value types with no pointers
or references in ordinary code ("a Rust programmer may think of `longer_of` as
a function that borrows its arguments mutably and returns a mutable reference
bound by the lifetime of those arguments... lifetime annotations... simply do
not exist in Hylo").
Surface choices Elseon would reject: the Swift-family keywords and
parameter/label conventions, because Elseon's syntax family is C and
JavaScript for minimal cognitive friction; the automatic-management semantics
are the deeper rejection (section 2), but the surface alone already puts Val
outside Elseon's chosen family.
Observation: Val/Hylo's own documentation frames the language for readers who
know Swift ("A primer on the design of Val" is written for Swift users), not
for C programmers.

## 4. C interoperability

FFI and C-compatible ABI:
- C baseline: C's ABI is the stable bridge between languages, and C
interoperability is what lets a new systems language reach existing operating
system APIs and libraries.
- Observed in the Hylo standard library: a minimal foreign-function binding
exists today through an `@ffi("...")` attribute, e.g. `@ffi("malloc")`,
`@ffi("free")`, `@ffi("memcpy")`, `@ffi("abort")` in LibC.hylo, and an
`@external("halt")` mechanism for free-standing code.
- No evidence was found that arbitrary Hylo user types get a guaranteed
C-compatible layout or that C structs can be imported with faithful layout
today (unverified beyond the standard library bindings above).

C-header reuse as first-class modules (Elseon's PFE):
- Val/Hylo offers no equivalent of Elseon's PFE: C headers are not ingested as
semantic modules.
- The original ambition was C++ interoperability, not C-header ingestion: the
2022 Val homepage headline was "Interoperable with C++", and the 2022 roadmap
planned a two-phase C++ interop that would first generate "C-like low-level
APIs for all public Val symbols" and later interface the compiler with clang.
- Current status (2026): interoperability is a research roadmap, not a shipped
feature.
The paper "High-Fidelity C Interoperability in Hylo" (a 2025 bachelor thesis
at TU Delft, listed on the Hylo homepage as research) proposes a design that
leverages "Clang for high-fidelity parsing and correct ABI handling" plus a
semantic mapping framework for C constructs such as bit-fields, flexible array
members, untagged unions, and C's "semantic dialects" (enum-as-flags and
similar idioms); the thesis itself describes the result as "a complete
roadmap", with only targeted prototypes validating parts of the mapping.

Drop-in C compilation:
- None; `hc` compiles Hylo source files and directories of files, and there is
no `zig cc`-style C compilation or C-source front end (unverified as an
explicit statement, but no such capability appears anywhere in the docs).

## 5. Toolchain

Backend: LLVM; the current hylo repository requires LLVM 20 packaged by the
project, and the project maintains Swifty-LLVM bindings.
Compiler language: the compiler is written in Swift 6.2 or later (hylo-new
requires Swift 6.3), with the front end owned by the project and code
generation through LLVM; this mirrors Elseon's chosen split but with Swift as
the implementation language rather than a kernel-adjacent one.
Compiler binaries and status: the classic compiler produces an executable
named `hc`; the repository README now says "Most of our efforts now go towards
the new compiler at https://github.com/hylo-lang/hylo-new" and describes the
hylo repository as "the sources of the former implementation".
The new compiler (hylo-new, created 2024-10-08) shipped its first
"Experimental release with LLVM lowering" as v0.0.1 on 2026-05-09 and has
reached v0.0.8 (2026-08-29), which adds inlinable floating-point operations
and build-system fixes; v0.0.7 (2026-08-22) "Enable cross-compilation".
The only release on the classic hylo repository is tagged "v-old-0.0.42",
confirming no stable release exists.
Build story: `hc` compiles single modules and bundles of files; incremental
compilation works at module granularity with interface-hash files
(`--emit-module-interface-hash-to`); linking goes through `clang`/`lld` with a
`shims.c` file providing the hosted parts of the standard library.
CMake support is experimental and maintained outside the main repository; no
package manager exists yet (the infrastructure blog lists one as future work).
CI-verifiability: GitHub Actions workflows, Codecov coverage, a setup-hylo
GitHub Action, and prebuilt toolchains (development containers, Docker images,
Homebrew tap) exist; CI docs cover GitHub Actions and mark GitLab, Forgejo,
and SourceHut as "contributions are welcome".
Debugging: an LLDB-based prototype was produced as research (a 2025 TU Delft
thesis) and the docs state the implementation "is not yet transferred to a
production-ready state"; on the standards side, Hylo is registered in DWARF 6
as a language (DW_LANG_Hylo = 0x0042, per the project's debugging docs and the
linked DWARF issue 240213.1).
Kernel-adjacent constraint: the compiler supports a `--freestanding` flag and
documents that free-standing programs must be linked with code providing
essentially one operation, `halt`; however, the toolchain is heavyweight
(Swift-built compiler, pinned LLVM 20, clang/lld for linking), no kernel or
embedded use is claimed or observed anywhere in the sources, and the language
itself is officially "not ready to be used yet".
Maturity: pre-1.0 across the board — repeated architecture changes (repo tags
such as archive/llvm-codegen and archive/legacy), a compiler restart in
hylo-new, the language tour page warning "This is a quite outdated document",
the reference pages for the specification and IR marked "outdated", blog posts
published as "TODO write article", and the unchanged "not ready to be used yet"
statement from 2022 through 2026.

## 6. Ecosystem and adoption

Real-world use: none found; the project itself says the language is not ready
to be used, and no production project, kernel-adjacent or otherwise, was found
in the sources consulted (absence of evidence, not proof of absence).
Kernel-adjacent use: none observed; the freestanding capability exists on
paper only (section 5).
Community activity (verified 2026-09-03): hylo-lang/hylo has about 1.55k
stars, 64 forks, and 218 open issues, with the last push on 2026-08-24;
hylo-new has 37 stars and was pushed 2026-09-03.
The project runs a Slack workspace (the invite URL still names it "val",
evidence of the rename) and GitHub Discussions.
Press and academic attention: coverage in The New Stack (July 2023, Hacker
News thread with 423 points) during the Val period; a C++ on Sea 2024 keynote
by Dave Abrahams ("Hylo: the safe systems- and generic-programming language
built on value semantics"); a steady research output (papers from 2021 to
2025, including the 2025 Programming conference paper by Racordon), and
supervised theses at TU Delft on C interop, debugging, and a documentation
compiler.
Tooling around the language: a VSCode extension, a JetBrains plugin, an Emacs
mode, a language-server prototype, Compiler Explorer support (the hello-world
page links a godbolt.org instance), HyloDoc, and the DWARF 6 registration.
License: Apache-2.0.
Maintenance status: active but pre-1.0; the classic compiler is being
sidelined in favor of hylo-new, whose first usable LLVM-lowering release
appeared only in May 2026.
Naming confusion is real in the ecosystem: Val collides with other languages
(Vale, Vala, and an unrelated Val hosted at val-lang.org since 2021), and the
Val-to-Hylo rename left dead domains, redirects, and the "formerly Val"
moniker behind.

## 7. What worked

The mutable-value-semantics research program produced credible, published
theory and working prototypes — the strongest asset of the project (observed
across the 2021 ICOOOLPS paper, the 2022 JOT paper, the 2023 "Borrow checking
Hylo" work, and the 2024 C++ on Sea keynote).
Alias-free mutation with visible markers works as a user model: the docs'
running example mutates a projected value through `inout` and `&` with no
pointers and no copies, and the language tour claims the mutation "occurs
directly on the value of y... neither copied, nor moved" (observed as
documented, working sample programs with end-to-end test cases in the
repository).
The `&` mutation marker keeps mutation visible in source, which is compatible
with Elseon's no-hidden-mutation instinct and worth studying.
Consuming moves and definite (de)initialization are enforced as compiler
passes, giving linear use of values without lifetime annotations (observed in
the repository design docs and IR documentation).
File-based modules with API resilience boundaries and interface-hash-based
incremental compilation replace the preprocessor cleanly (observed in the
modules and build-system docs) — the same instinct as Elseon's semantic
header import, though applied to Hylo modules rather than C headers.
The project attracted external recognition early: a DWARF 6 language code, a
Compiler Explorer integration, a C++ on Sea keynote, and supervised thesis
research (observed via the docs and homepage).
The 2022 implementation-status page is a model of honest staging: it
explicitly says the implementation is "at a very early stage", lists open
design questions (stored projections, concurrency), and dates milestones —
transparency Elseon can imitate.
Safe-by-default with "explicit, auditable opt-in" to unsafe constructs (stated
by the project in both 2022 and 2026) is a workable framing for a safety
boundary that Elseon could mirror.

## 8. What did not work

Name instability: the language went public as Val and was renamed back to Hylo
on 2023-08-11, leaving a dead domain (www.val-lang.dev no longer resolves,
observed 2026-09-03), redirects (github.com/val-lang/val now serves
hylo-lang/hylo), a Slack workspace still named "val", and the "Hylo (formerly
Val)" header in the README; the published reason for the rename is unverified.
Compiler restarts: the repository shows archived implementation generations
(tags such as archive/llvm-codegen and archive/legacy), and the README now
directs all new work to hylo-new, whose first experimental LLVM-lowering
release came only in May 2026 — five years after the repository was created,
no stable release exists (observed in tags and releases).
The C++ interoperability headline did not ship: "Interoperable with C++" was a
2022 headline aim and the roadmap promised a first phase by end of 2022, but
as of 2026 interoperability is still a research roadmap (the 2025 thesis) with
only prototypes, and even the current goal is C interop rather than the
original C++ interop (observed by comparing the 2022 homepage and roadmap with
the 2026 homepage research list).
Documentation discipline lagged: the language tour warns it is "quite
outdated", the specification and IR reference pages are marked "outdated", and
two of the three blog posts are "TODO" stubs (observed on the site 2026-09-03).
Concurrency remained a design exercise from 2022 through 2026: the 2022
roadmap lists concurrency questions as open, and the 2026 concurrency page
still carries a warning that the approach "is still under design".
Kernel-adjacent suitability was never demonstrated: freestanding support is a
flag plus a `halt` requirement on paper, no kernel or embedded experiment is
reported, and the automatic memory-management costs (copy-on-write buffers,
compiler-inserted deinitialization) for such environments are unexplored in
the sources consulted.
The "not ready to be used yet" sentence survived from 2022 to 2026, so the
project's value proposition has not been testable by real users in four years;
all "what worked" evidence above is therefore prototype-level, not
production-level.

## 9. Verdict for Elseon

Classification: idea source — not a model.
Val/Hylo cannot be Elseon's model because its surface is Swift-shaped rather
than C/JavaScript-shaped, its memory management is automatic rather than
explicit, it offers no deterministic layout contract, and it is pre-1.0 and
officially unusable as of 2026.
It is a first-rate idea source for the value-semantics research program and
for several concrete mechanisms (below).
Refinement of `documents/08-related-work.md`: keep Val in Camp 1 as a fresh
design near Elseon's space, but correct the description to "Swift-shaped
syntax with mutable value semantics, to kill aliasing bugs — research-stage,
renamed Hylo in 2023, still pre-1.0"; the current row overstates the C-likeness
of the surface.

Borrow list:
- Subscripts and `inout` projections — an alias-free way to express mutable
views without pointers, giving Elseon a mechanism to kill aliasing bugs while
keeping mutation visible in source.
- The `&` mutation marker — explicit, source-visible mutation that fits
Elseon's no-hidden-mutation rule (note that Val's `&` is semantic, not
address-of).
- Consuming moves as a compile-time linear discipline — value transfer that is
explicit and checkable, a concept Elseon already takes from Rust.
- Definite (de)initialization as a mandatory compiler pass — a concrete
technique for proving every object is initialized and reclaimed exactly once,
reusable in Elseon's conformance checks.
- File-based modules with API resilience boundaries and interface-hash
incremental compilation — a clean replacement for textual includes that
Elseon's module story should emulate.
- "Guaranteed optimizations" stated as language promises — Val's planned
closure-allocation guarantee shows the value of spelling out cost invariants;
Elseon should promise layout and allocation invariants the same way.
- Safe-by-default with auditable unsafe opt-in — a boundary framing Elseon can
mirror for its C-boundary checks.
- Honest staging and public roadmaps — the 2022 status page is a model of
communicating immaturity without overclaiming.
- Low-cost ecosystem moves — Compiler Explorer support, DWARF language
registration, and editor plugins gave the project visibility before a usable
compiler existed.

Avoid list:
- Automatic memory management with compiler-inserted deinitialization — hidden
scope-exit behavior and implicit allocation fail Elseon's kernel test; Elseon
keeps allocation and reclamation visible.
- Copy-on-write containers as a "zero-cost" story — COW hides sharing,
bookkeeping, and potential hidden allocation behind value syntax; Elseon's
deterministic-layout guarantee must not rest on it.
- Swift-shaped surface (fun/type/let/inout keywords, argument labels) — outside
Elseon's C/JavaScript syntax family.
- Restarting the compiler core repeatedly — the archive tags and the hylo-new
restart show the cost; Elseon should treat the front-end/backend split and its
conformance corpus as stable commitments.
- Announcing headline interoperability (C++ interop) years before shipping —
Elseon's PFE claim should be gated on a working header-ingestion pipeline from
milestone one, or kept out of headlines.
- Two renames with domain churn — Val-to-Hylo destroyed link equity and
discoverability; Elseon should fix its name and URLs once.
- Letting core documentation rot to "outdated" status — Elseon's spec and docs
must track the implementation or the language reads as abandoned.
- An open-ended "not ready" status without shipped milestones — transparency
is good, but Elseon should define what "ready" means and test it against the
kernel corpus early.

## 10. Evidence

Primary sources (project site and documentation, verified 2026-09-03 unless
noted):
- https://hylo-lang.org/ — homepage: "Hylo — A Systems Programming Language",
achievements, research and talk lists.
- https://hylo-lang.org/introduction/ — current introduction: positioning,
aims, "not ready to be used yet", sample program, Swift-borrowing statement.
- https://github.com/hylo-lang/hylo — repository README "Hylo (formerly Val)",
build requirements (Swift 6.2+, LLVM 20), statement that effort moved to
hylo-new.
- https://github.com/hylo-lang/hylo-new — new compiler repository.
- https://github.com/hylo-lang/hylo/releases — classic repository release
"v-old-0.0.42" only.
- https://github.com/hylo-lang/hylo-new/releases — v0.0.1 (2026-05-09,
"Experimental release with LLVM lowering") through v0.0.8 (2026-08-29).
- https://github.com/hylo-lang/hylo/commit/a7bf5c462a73fa9ba0f5ad6d7f0f488a8dc1dbbb
— commit "Rename 'Val' to 'Hylo'" by Dimi Racordon, dated 2023-08-11.
- https://hylo-lang.org/docs/user/language-tour/ — language tour index with
"quite outdated document" warning.
- https://hylo-lang.org/docs/user/language-tour/modules/ — file-based modules,
resilience boundaries, `hc` invocation.
- https://hylo-lang.org/docs/user/language-tour/bindings/ — let/var/inout,
lifetimes, consuming operations.
- https://hylo-lang.org/docs/user/language-tour/functions-and-methods/ —
`fun`, argument labels, deinitialization, Rust drop analogy.
- https://hylo-lang.org/docs/user/language-tour/basic-types/ — static typing,
Int/Float64, type(of:).
- https://hylo-lang.org/docs/user/language-tour/concurrency/ — concurrency
principles; warning that the approach "is still under design".
- https://hylo-lang.org/docs/user/language-tour/hello-world/ — hello world,
godbolt.org (Compiler Explorer) link.
- https://hylo-lang.org/docs/user/tooling/build-systems/ — hc CLI, incremental
compilation, experimental CMake support.
- https://hylo-lang.org/docs/user/tooling/ci/ — setup-hylo action, releases
from hylo-new, per-platform CI status.
- https://hylo-lang.org/docs/user/tooling/debugger/ — LLDB research prototype,
DWARF 6 codes (DW_LANG_Hylo = 0x0042), dwarfstd issue 240213.1 link.
- https://hylo-lang.org/docs/contributing/building-the-compiler/ — compiler
build guide.
- https://github.com/hylo-lang/hylo/blob/main/README.md — same as the hylo
repository README above.
- https://github.com/hylo-lang/hylo/blob/main/Docs/DefiniteInitialization.md —
definite (de)initialization pass description.
- https://github.com/hylo-lang/hylo/blob/main/Docs/Freestanding.md —
free-standing mode; `halt` as the only required external function.
- https://github.com/hylo-lang/hylo/blob/main/StandardLibrary/Sources/LibC.hylo
— `@ffi` bindings of malloc/free/memcpy/abort and friends.
- https://github.com/hylo-lang/hylo/blob/main/StandardLibrary/Sources/Core/MemoryLayout.hylo
— size/stride/alignment runtime queries.
- https://hylo-lang.org/docs/user/language-tour/further-reading/ — links to
end-to-end test cases and standard library sources.

Val-era primary sources (archived):
- https://web.archive.org/web/20220807203437/https://www.val-lang.dev/ — Val
homepage snapshot 2022-08-07: positioning, aims including "Interoperable with
C++", "not ready to be used yet".
- https://web.archive.org/web/20220823124621/https://www.val-lang.dev/pages/implementation-status.html
— Val roadmap snapshot 2022-08-23: early-stage implementation, milestones,
C++ interop plan, concurrency open questions.
- https://web.archive.org/web/20220824131306/https://www.val-lang.dev/pages/language-tour.html
— Val language tour snapshot 2022-08-24.

Research papers and theses (linked from the project homepage):
- https://doi.org/10.5381/jot.2022.21.2.a2 — Racordon, Shabalin, Zheng,
Abrahams, Saeta, "Implementation Strategies for Mutable Value Semantics",
Journal of Object Technology 2022 (stack allocation, copy-on-write).
- https://arxiv.org/abs/2106.12678 — "Native Implementation of Mutable Value
Semantics", ICOOOLPS 2021 ("stack allocation for static garbage collection").
- https://ambrus.dev/_astro/High-Fidelity%20C%20Interoperability%20in%20Hylo.7fUYiq3A.pdf
— Ambrus Tóth, "High-Fidelity C Interoperability in Hylo", TU Delft bachelor
thesis, 2025-06 (Clang-based design, roadmap, prototypes).
- https://drops.dagstuhl.de/storage/01oasics/oasics-vol134-programming2025/OASIcs.Programming.2025.25/OASIcs.Programming.2025.25.pdf
— Racordon, "Who Owns the Contents of a Doubly-Linked List?", Programming 2025.

Secondary sources (press, community, talks):
- https://thenewstack.io/meet-val-a-new-language-alternative-to-c-rust/ —
The New Stack, July 2023, Val period.
- https://news.ycombinator.com/item?id=36778566 — Hacker News thread on Val,
2023-07-18 (423 points).
- https://news.ycombinator.com/item?id=32955685 — Hacker News item "The Val
Programming Language", 2022-09-23.
- https://cpponsea.uk/2024/session/hylo-the-safe-systems-and-generic-programming-language-built-on-value-semantics
— Dave Abrahams, "Hylo: the safe systems- and generic-programming language
built on value semantics", C++ on Sea 2024.
- https://raw.githubusercontent.com/hylo-lang/Documentation/main/val-for-swift-users.md
— "A primer on the design of Val", written for Swift users (evidence that the
intended reader knows Swift, not C).
