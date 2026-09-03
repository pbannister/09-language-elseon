# Hare vs C

Study note for the episode 1-A C-comparison series.
The comparison baseline is C.
The aim is to identify what Hare tried, what worked, and what did not work, so Elseon can borrow what worked and avoid what did not.
Hare sources consulted are the ones listed in section 10, fetched 2026-09-03.
"Stated by the project" marks project claims; "observed" marks independently visible facts; live-state facts carry `verified 2026-09-03`.

## 1. Positioning

C is the baseline: a small, portable, imperative systems language with manual memory management, direct pointer access, and a 50-plus-year track record in operating systems, kernels, and embedded software.
C leaves much behavior undefined and puts memory safety in the programmer's hands.

Hare states its position on its [home page](https://harelang.org/): "Hare is a systems programming language designed to be simple, stable, and robust.
Hare uses a static type system, manual memory management, and a minimal runtime.
It is well-suited to writing operating systems, system tools, compilers, networking software, and other low-level, high performance tasks."

The [April 2022 announcement](https://harelang.org/blog/2022-04-25-announcing-hare/) adds: "Hare is most similar to C, and almost all programs written in C can also be written in Hare.
Hare is simpler than C, however."

Hare does not position itself as "improved C", "safer C", or a "C replacement".
The post [Will Hare replace C?](https://harelang.org/blog/2022-05-02-what-is-hares-scope/) answers "Nope" and says Hare aims to succeed within its niche for programmers who find its ideas compelling, while C stays in the bootstrap path "indefinitely".
The project explicitly rejected the press framing of Hare as a C replacement (stated by the project, in the same post).

Hare's distinguishing position is longevity: [Hare aims to become a 100-year programming language](https://harelang.org/blog/2023-11-08-100-year-language/) and [Hare is a boring programming language](https://harelang.org/blog/2022-11-27-hare-is-boring/).
The plan is a conservative design of battle-tested idioms, a formal specification, and a permanent freeze of grammar and semantics at Hare 1.0, after which the standard library only accepts source-compatible changes (stated by the project).

Hare is deliberate about who it is for: upstream supports only free software platforms, with Linux and the BSDs supported and Windows and macOS "not planned" upstream ([installation guide](https://harelang.org/documentation/install/index.html), [FAQ](https://harelang.org/documentation/faq.html)).

Timeline: the initial prototype commit is dated 2019-12-27 ([fourth-birthday post](https://harelang.org/blog/2023-12-27-hare-4th-birthday/)); the language went public 2022-04-25; the first versioned release 0.24.0 shipped 2024-02-16 ([release post](https://harelang.org/blog/2024-02-16-hare-0.24.0-released/)); the latest release at the time of writing is 0.26.0 (2026-02-13, [release post](https://harelang.org/blog/2026-02-13-hare-0.26.0-released/), verified 2026-09-03).

`documents/08-related-work.md` classifies Hare in "Camp 1: Fresh C-like designs" as "simple, C-like, no memory management required; minimal and static; for UNIX-like OSes — used to build a real OS".
That classification is verified with refinements.
"Simple, C-like" and "minimal and static" hold: static typing, minimal runtime, no libc by default, static linking by default (all stated by the project; see sections 2 and 5).
"for UNIX-like OSes" holds and is stricter than the note suggests: Hare is free-software-only by policy, so the target set is Linux plus the BSDs.
"no memory management required" overstates: memory management is manual, and the standard library allocates internally; what Hare offers is low-ceremony defaults (bounds-checked slices, `defer`, abort on out-of-memory) so that simple programs rarely write explicit `alloc`/`free`.
"used to build a real OS" is verified: the Hare toolchain builds the [Helios microkernel](https://sr.ht/~sircmpwn/helios/) ("an experimental microkernel inspired by seL4", x86_64 with aarch64 work in progress), its successor [Hermes](https://git.sr.ht/~sircmpwn/hermes/) ("an experimental microkernel", active commits in 2026), and the [Ares operating system](https://sr.ht/~sircmpwn/ares/) project that describes Hermes as aiming to replace Helios; all require "an up-to-date Hare toolchain" (observed in the project repositories, verified 2026-09-03).

## 2. Kernel-test adherence

Elseon's Kernel Test asks four questions: no garbage collection or hidden runtime, no hidden allocations, no hidden control flow, and deterministic memory layout.
C passes the first two structurally (manual `malloc`/`free`, no mandated runtime) but fails the last two in spirit: undefined behavior gives compilers license to do almost anything, and struct layout is implementation-defined rather than language-guaranteed.

No garbage collection / no hidden runtime — passes, with strong evidence.
Hare has no garbage collector; the [safety-features post](https://harelang.org/blog/2022-06-21-safety-features/) explains that a collector was rejected because it interferes with predictable, explicit program behavior and is "definitely off the table for use-cases like kernels".
The FAQ contrasts Hare with Go precisely on "Hare does not use a garbage collector".
The runtime is minimal and explicit: programs do not link with libc by default (announcement, FAQ: "Hare is self-contained – it does not depend on libc"), the standard library `rt` module provides the runtime, and in freestanding builds the user supplies `rt` ([freestanding docs](https://harelang.org/documentation/usage/freestanding.html)).
The compiler emits calls to a small, documented set of `rt` functions such as `memcpy` and `memmove`, which a custom runtime must implement (freestanding docs, stated by the project).
Only linking a C library switches Hare to a "libc-oriented Hare runtime" ([system-libraries doc](https://harelang.org/documentation/usage/system-libraries.html)).

No hidden allocations — passes with caveats, evidence from the language specification.
Allocation is an explicit `alloc` expression and `free` discards the resources ([spec section 6.7.20 "Allocations"](https://harelang.org/specification)); growable operations `append`, `insert`, `delete` on slices are builtins visible in source and may reallocate.
Out-of-memory behavior is defined rather than hidden: the default is abort, `alloc` into a nullable pointer type yields `null` on failure, and since approximately Hare 0.25 the operations can return the `nomem` error singleton ([OOM-strategies post](https://harelang.org/blog/2021-04-28-oom-strategies/), [RFC tour 2025](https://harelang.org/blog/2025-06-02-planned-breaking-changes/)).
Kernel-oriented controls exist: `static append`/`static insert` never allocate, the compiler flag `-Fstrictoom` turns any non-static append or non-nullable allocation into a compile error, and a custom `rt` that omits `rt::ensure` yields link errors for dynamic slices (OOM post).
The caveat: dynamic allocation still happens behind source-visible builtins, and strings plus dynamic slices carry implicit capacity state.

No hidden control flow — mostly passes, with two caveats.
There are no exceptions; errors are values (tagged unions) handled with the explicit postfix operators `?` (error propagation: return the error from the current function when the error test fails) and `!` (error assertion: print a diagnostic and abort when the error test fails), and `match`/`switch` are required to be exhaustive ([spec section 6.7.31 "Error checking"](https://harelang.org/specification), [advances-on-C post](https://harelang.org/blog/2021-02-09-hare-advances-on-c/)).
`defer` is explicit scope-exit code in the source.
Bounds checks on arrays and slices are runtime tests with defined failure behavior: a diagnostic is printed and the execution environment aborts ([spec section 6.7.26 "Indexing"](https://harelang.org/specification)); unbounded arrays `[*]T` are the unchecked escape hatch (safety post).
The aborts are deterministic and specified, but they are control transfers the programmer does not write by hand — Elseon's "everything visible in the source" bar would call for an explicit or compilable-out failure policy.
The two caveats: hosted builds run `@init`/`@fini` functions implicitly at startup and teardown, with the ordering within a module undefined ([spec section 5.4.5](https://harelang.org/specification)); and the freestanding environment deliberately leaves the behavior of initialization and finalization functions undefined ([spec section 5.4.4](https://harelang.org/specification)).

Deterministic memory layout — passes as a *specified* layout, with implementation-defined knobs, but C-identical layout is not automatic.
The spec fixes struct field offsets: each field lands at the minimum aligned offset that meets its alignment requirement and follows the previous field, with padding added to satisfy alignment and trailing padding so total size is a multiple of the type's alignment ([spec section 6.6.13](https://harelang.org/specification)).
`struct @packed` removes padding entirely and aborts translation if alignment requirements cannot be met.
Sizes are constrained (scalar sizes are powers of two), while alignment values and pointer representation are implementation-defined with bounds (spec, stated by the project).
To reproduce a specific C struct, the programmer must hand-tune: Hare 0.26.0 replaced the labor-intensive `@offset` attribute with explicit unnamed padding fields `_: type` ([0.26.0 release post](https://harelang.org/blog/2026-02-13-hare-0.26.0-released/)).
This means deterministic layout exists per platform, but layout compatible with a given C header is a manual job, not a language guarantee.

Overall: Hare passes the Kernel Test on no-GC, explicit allocation, and defined behavior, with the caveats that bounds/OOM aborts and `@init`/`@fini` are implicit-by-spec control flow, and that exact C layout requires hand-tuning.

## 3. Syntax family

Hare keeps C's statement shape: braces and semicolons, `if`/`else`, `for`, `switch`, `return`, C-family operators, and comments, so a C programmer recognizes the skeleton.
Hare also keeps the C mental model: pointers, addresses, structs, unions, enums, manual memory.

The divergences from C's surface are where the cognitive friction sits.

Declarations put the name first and the type after a colon, Go/Rust style: `let x: int = 5;` and `const y: str = "hi";`, versus C's type-first `int x = 5;`.
Elseon's design takes "type-first declarations" from C ([`documents/07-elseon-language.md`](07-elseon-language.md)); Hare's name-first order is a visible break from that family.

Functions are introduced with `fn` and use `= { ... };` with a trailing semicolon on the body: `export fn main() void = { ... };`.
Hare is expression-based, which the FAQ cites as the reason for "so many semicolons".

Types are written with keywords and postfix decoration: slices `[]T`, bounded arrays `[N]T`, unbounded arrays `[*]T`, tagged unions `(result | error)`, nullable pointers `nullable *T`, tuples, and `str`/`rune` builtins (spec; tutorial).
Errors are handled with the visible postfix operators `!` and `?`, and exhaustive `match`; there is no exception machinery (advances post, spec 6.7.31).

Resource handling uses `defer` (Go-style) rather than destructors, and `abort`/`assert` are builtins (spec section 6.7.21).

Modules replace headers and the preprocessor: `use` imports, `::` namespaces, and per-module translation units; there is no textual `#include`, no macros (FAQ: Hare "has namespaces" and lacks "generics, traits, macros").

Deliberately absent features: no generics (FAQ: "a deliberate design choice which simplifies the language considerably and is more aligned with its design roots in C"; users implement hash tables themselves), no classes or inheritance, no closures as of the studied 0.24–0.26 material (closures were listed as an open research area in [2021](https://harelang.org/blog/2021-03-30-future-research-areas/) and no studied release note adds them — absence after 0.26.0 unverified), no operator overloading.

Surface choices Elseon would reject per the Kernel Test and its C/JavaScript family: name-last declarations and expression-semicolon functions (unnecessary friction against C's type-first form); `@init`/`@fini` with unspecified intra-module ordering (hidden control flow); and shipping `const` with weak, inconsistently enforced semantics — Hare's own 2025 RFC tour admits "`const` is inconsistently implemented" and plans an overhaul ([RFC tour](https://harelang.org/blog/2025-06-02-planned-breaking-changes/)).
Borrowable surface ideas: tagged-union errors with mandatory handling, nullable/non-nullable pointer distinction, `defer`, and bounds-checked slices as first-class types.

## 4. C interoperability

C-compatible ABI: stated as "Hare uses a superset of the standard C ABI for the platform" — x86_64 System V, aarch64 AAPCS64, riscv64 ([system-libraries doc](https://harelang.org/documentation/usage/system-libraries.html)).
The doc refines this to "mostly": Hare does not support decimal types, complex numbers, `long double`, or `int128_t`.
Hare-only constructs (tagged unions, tuples, slices, strings) have spec-defined internal representations (`types::slice`, `types::string`) so their layout is knowable.

FFI: calling C from Hare means forward-declaring the C symbols in Hare source with the `@symbol("name")` attribute and using the `types::c` aliases for C scalar types; calling Hare from C means writing a C header by hand for Hare functions restricted to the C-ABI-compatible subset; C-style variadics are supported through `...`, the `valist` type, and `vastart`/`vaarg`/`vaend` (system-libraries doc).
Hare strings are not NUL-terminated and are not directly compatible with `char *`; conversions such as `c::fromstr` and `c::tostr` are provided (system-libraries doc).

C-header reuse (Elseon's PFE angle): Hare has no equivalent of ingesting C headers as first-class semantic modules.
Every foreign symbol and type must be re-declared by hand in Hare, and there is no tool that parses C headers for this purpose.
The official doc's example shows a C `FILE *fopen(...)` turned into a hand-written Hare declaration; there is no `#include` and no semantic header import (system-libraries doc).
Struct layout compatibility with a C header is likewise manual (section 2), and the draft spec contains no bitfield syntax, so C structs with bitfields need manual reinterpretation as masks and shifts.

Drop-in C compilation: none.
There is no `zig cc`-style facility; harec compiles Hare only, and mixed Hare/C binaries are assembled by compiling each side to objects and linking with `hare build` or `cc`/`ld` (system-libraries doc).
Linking any C library implicitly links libc and switches to a libc-oriented Hare runtime under the `+libc` build tag (system-libraries doc).

The extended-library list includes `hare-c`, described as "C compiler and support libraries" ([extended libraries](https://harelang.org/documentation/extlib.html)); its status and role are unverified.

## 5. Toolchain

Backend: Hare does not use LLVM.
The compiler `harec` lowers Hare to [qbe](https://c9x.me/compile/) intermediate code, and qbe generates assembly; Hare 0.26.0 is compatible with qbe 1.2 ([0.26.0 release post](https://harelang.org/blog/2026-02-13-hare-0.26.0-released/)).
The [FAQ's "Why qbe instead of LLVM?"](https://harelang.org/documentation/faq.html) states the reason: qbe is roughly 15,000 lines of portable C99 versus LLVM's tens of millions, keeping the whole toolchain understandable by one person.
The FAQ states the cost openly: qbe-generated code runs at 25% to 75% of the runtime performance of comparable LLVM-generated code depending on workload, which is sometimes mitigated by hand-written assembly (the standard library uses AES-NI for cryptography).

Compiler implementation: `harec` is the single compiler front end, "a Hare compiler written in C11 for POSIX-compatible systems", self-described as the "Hare bootstrap compiler" ([harec repository](https://git.sr.ht/~sircmpwn/harec)).
C remains part of the bootstrap path indefinitely (scope post).
The standard library, the `hare` build driver, and `haredoc` are written in Hare and compiled by harec ([hare repository](https://git.sr.ht/~sircmpwn/hare), [bootstrap guide](https://harelang.org/documentation/install/bootstrap.html)).

Build story: a module is the translation unit; `hare build/test/run/deps` drive the build; Hare programs are statically linked by default, which also simplifies cross-compilation using distribution cross toolchains ([cross-builds post](https://harelang.org/blog/2022-09-06-cross-builds-with-hare/)).
Freestanding builds run with `-F`, a custom `HAREPATH`, and a user-supplied `rt` module ([freestanding docs](https://harelang.org/documentation/usage/freestanding.html)).
Bootstrap from source needs only a POSIX environment, a C11 compiler, and qbe (bootstrap guide).
Versioning follows `0.<YY>.<Q>` (year, zero-indexed quarter) under a quarterly release policy introduced with 0.24.0 (release post); actual cadence has been slower than quarterly (0.24.0 Feb 2024, 0.24.2 Jul 2024, 0.25.2 Jun 2025, 0.26.0 Feb 2026, per the [blog index](https://harelang.org/blog/)).

Maturity: Hare is pre-1.0 (0.26.0, verified 2026-09-03) and still makes breaking changes, now announced through release notes and an RFC process, with a `hare-update` migration tool ([RFC tour](https://harelang.org/blog/2025-06-02-planned-breaking-changes/), [hare-update post](https://harelang.org/blog/2025-06-11-hare-update/)).
The language specification is explicitly a draft "not considered authoritative" ([specification](https://harelang.org/specification), PDF at https://harelang.org/specification.pdf).
The plan is to finalize and freeze the language at 1.0 (announcement, 100-year post).

Debugging: the standard library has a `debug` module (backtraces), `hare test` runs `@test`-annotated tests, gdb attaches to Hare kernels (Helios provides `make nographic-gdb`), and the project published ongoing debugging work ([Making Hare more debuggable](https://harelang.org/blog/2022-11-04-making-hare-debuggable/), [debugging-features post](https://harelang.org/blog/2024-02-01-debugging-features/)).
There is no language server yet (FAQ: "Not yet").

CI-verifiability: `make check` test suites ship with harec and the standard library, and the harec README shows SourceHut build status for Linux, FreeBSD, and NetBSD on x86_64.

Kernel-adjacent constraint: satisfied in practice.
Hare programs need no libc and no runtime beyond the explicit `rt`; freestanding mode is a documented, first-class build path; the constraint that a custom `rt` must implement the functions the compiler emits (such as `memcpy`) is documented (freestanding docs); and kernels in Hare exist (section 1).
The caveat for a kernel builder: bounds checks and abort paths are compiled in by default and rely on the runtime's abort behavior, and `@init`/`@fini` semantics are undefined in the freestanding environment (spec 5.4.4).

## 6. Ecosystem and adoption

Real-world use: Hare is self-hosting for its standard library and build tooling; the announcement lists in-house projects including Himitsu (secrets manager) and Helios (microkernel); later posts document an SSH agent and powerctl, a setuid power-management tool written in Hare ([powerctl case study](https://harelang.org/blog/2022-08-28-powerctl-a-hare-case-study/)).
Kernel-adjacent use is the strongest signal: the Helios, Hermes, and Ares OS projects build kernels and userspace with the Hare toolchain (section 1, observed in the repositories).
The 0.26.0 release post draws a real code example from "the scheduler in the Hermes kernel".
The community runs builtwithhare.org to host documentation sites for Hare projects ([2025 post](https://harelang.org/blog/2025-08-22-builtwithhare.org/)).

Community activity: active through SourceHut mailing lists (`hare-dev`, `hare-users`, `hare-announce`, `hare-rfc`) and IRC; roughly 30 contributors are credited in the 2022 announcement; maintainership has grown (0.26.0 welcomed a new maintainer); upstream ports extended to OpenBSD (2023) and DragonflyBSD (2026).
Releases continue through 0.26.0 (2026-02-13), and a Hare meetup ran at FOSDEM 2026 ([blog index](https://harelang.org/blog/)).

Distribution packaging: Debian carries the `hare` source package in main, maintained by the Debian Hare Team, at version 0.26.0.1-1 and migrated to testing ([Debian package tracker](https://tracker.debian.org/pkg/hare), verified 2026-09-03).
Alpine packaging is referenced in the project's own 2022 cross-build post (`apk add hare`).
Fedora received a Hare change proposal and package review requests in 2023–2024 ([Fedora wiki](https://fedoraproject.org/wiki/Changes/HareProgrammingLanguage)); current Fedora availability is unverified (the package page returns no result, checked 2026-09-03).
Upstream supports Linux, FreeBSD, NetBSD, OpenBSD, and DragonflyBSD; a third-party macOS port exists but is explicitly unsupported upstream (FAQ, installation guide).
No upstream package manager exists, and the project states it "encourage[s] less code reuse as a shared value" (FAQ).

Licensing: the Hare standard library is MPL (freely linkable), while the executables — the `hare` build driver and the `harec` compiler — are GPL-3.0-only (not "any later version"), and the specification text is GNU FDL ([hare repository README](https://git.sr.ht/~sircmpwn/hare), [spec front matter](https://harelang.org/specification)).
Contributions require Developer Certificate of Origin sign-off (hare repository README).

Press and perception: the launch drew secondary coverage that framed Hare as an alternative to C (e.g. [The Register](https://www.theregister.com/software/2022/04/26/heresy-hare-programming-language-an-alternative-to-c/), 2022-04-26), a framing the project explicitly pushed back on (scope post).
Fundraising runs through Open Collective (announcement).

## 7. What worked

What follows are ideas Hare proved in practice, with where the outcome was observed, that Elseon should consider borrowing.

Spec-first design with defined behavior instead of C-style undefined behavior — worked as a process.
Hare's spec defines behaviors C leaves undefined (signed overflow, bounds failures) and constrains optimizers to conservative rewrites (safety post, spec).
Observed: the spec exists and kernels and the crypto suite are built against it.
Elseon already plans a conformance-testable spec; Hare shows the discipline is workable.

Feature-freeze ambition and "boring language" conservatism — worked as a community and stability strategy.
Observed: the project sustains a multi-year pre-1.0 phase without feature sprawl, and the community cites stability as a shared value (100-year post, boring post).
This matches Elseon's "boring syntax, safe semantics" ethos.

Tagged-union errors with mandatory handling — worked as the language's core error model.
Hare calls tagged unions "the key innovation" (advances post), and exhaustive `match` forces error cases to be considered.
Observed across the entire standard library API (docs.harelang.org) and real programs.

Nullable versus non-nullable pointer types — worked as cheap safety.
Non-nullable pointers cannot hold `null`; nullable pointers must be tested before dereference (advances post, spec 6.6.12).
Observed in every function signature in the standard library.

Bounds-checked slices with a defined abort, plus the `[*]T` unbounded escape — worked in kernel code.
Helios kernel code is shown using both (safety post).
Observed: bounds checks and the escape hatch coexist in a real microkernel.

Explicit memory management with ergonomic defaults — worked for systems programs.
`alloc`/`free`, `defer`, abort-on-OOM by default, `nomem` for recoverable paths, no-allocation `static append`/`insert`, and the `-Fstrictoom` enforcement flag give kernel developers a visible, controllable allocation story (spec, OOM post, RFC tour).
Observed: kernels and setuid tools are written this way.

Freestanding environment with a user-supplied `rt` and a documented compiler/runtime contract — worked for kernel builds.
The freestanding build path, custom `rt` implementing the functions harec emits, and the resulting kernels are all documented and real (freestanding docs, Helios/Hermes repositories).
Observed: Helios, Hermes, and Ares build kernels and userspace with the stock toolchain.

Small, self-contained toolchain — worked as a differentiator.
A C11 compiler plus qbe bootstraps everything; no libc by default; static binaries by default; cross-compilation is a config change (FAQ, announcement, cross-builds post).
Observed: distro packaging became feasible (Debian), and kernel builds do not drag in a huge runtime.

A bounded standard library with integrated docs — worked for adoption.
The library covers crypto, networking, date/time, regex, and I/O with terminal docs via `haredoc` (announcement, [stdlib reference](https://docs.harelang.org/)).
Observed: projects like powerctl rely on it, and extended libraries (HTTP, JSON, XML, an event loop, a C compiler project) grew around it ([extended libraries](https://harelang.org/documentation/extlib.html)).

## 8. What did not work

Failures, dead ends, and pitfalls, with where the outcome was observed, that Elseon should avoid.

No borrow checker and no temporal memory safety — did not deliver a memory-safe language.
Hare itself concedes: "This is an area where Hare presently does not make any improvements over C" for use-after-free and double-free (safety post, 2022).
The project's plans evolved from allocator hardening to a possible linear-type system that "may never land in Hare" (RFC tour, 2025).
Where observed: project admission; community criticism reported in the same posts.

The qbe backend's performance ceiling — worked against Hare in performance-sensitive code.
Project-stated: qbe code runs at 25%–75% of LLVM-generated code, mitigated by hand assembly (FAQ).
Where observed: project admission; no third-party benchmarks were consulted in this study.
Elseon's LLVM backend avoids this trade-off.

No generics as a permanent constraint — cost real effort.
The deliberate omission pushes hash tables and other containers onto every programmer (FAQ).
Where observed: the FAQ itself documents "So I need to implement hash tables myself?" as a standing question.
This is a friction point Elseon need not copy; nothing in the Kernel Test forbids safe, explicit generics.

Manual C interoperability — did not remove the re-declaration burden.
Every C symbol and type must be forward-declared by hand, struct layout must be hand-tuned, strings need conversion, and the ABI superset excludes `long double`, complex, decimal, and `int128_t` types (system-libraries doc).
Where observed: the official FFI documentation is essentially a manual step list.
This is exactly the pain Elseon's PFE header ingestion is designed to remove.

Struct layout that is not C-compatible by default — caused ongoing friction.
Deterministic layout is specified, but reproducing a C struct requires `@packed` or manual padding; Hare 0.26.0 replaced the earlier `@offset` attribute with `_` padding fields because `@offset` was "quite labor intensive and cumbersome to use, and required a pretty complicated implementation" (0.26.0 release post).
Where observed: the release notes document the abandoned attribute and its replacement.

Inconsistent `const` semantics carried too long — became pre-1.0 design debt.
Hare's own RFC tour says `const` "has never been properly implemented, nor has it ever had well-defined semantics" and that the planned mutability overhaul "will break nearly every existing Hare codebase" (RFC tour, 2025).
Where observed: project admission ahead of a planned breaking change.

No threading in the standard library — limited the language's reach.
Multithreading is "Probably not" supported upstream; the stdlib makes no reentrancy guarantees, and OSes written in Hare implement threading themselves (FAQ).
Where observed: the 2022 scope post already listed the lack of stdlib multithreading as ruling Hare out for many use-cases.

Free-software-only platform policy — capped the audience by design.
No upstream Windows or macOS support, and WSL is out of scope (FAQ, installation guide).
Where observed: the FAQ states the policy explicitly.
This is a values choice, not a technical failure, but it limits adoption.

Release cadence slipped from the stated quarterly policy.
The policy promised quarterly releases with 0.YY.Q versioning (0.24.0 post, 2024), but actual releases were roughly half-yearly through 0.26.0 (2026-02-13), per the [blog index](https://harelang.org/blog/).
Where observed: the release history itself.

The language specification remains a draft after years of development.
The spec is explicitly "a DRAFT, and is not considered authoritative" (specification front matter).
Where observed: the spec PDF and its own disclaimer.
Elseon should note how long a full spec takes; Hare started the spec early (2020–2024 copyright) and still calls it a draft in 2026.

## 9. Verdict for Elseon

Classification: idea source with selected model aspects, not a model.
Hare is the closest philosophical neighbor in the fresh C-like camp alongside C3 and Zig — it proves the entire Kernel-Test recipe (no GC, explicit allocation, defined behavior, freestanding runtime, real kernels) works in practice.
But Elseon should not model its surface or toolchain on Hare: Hare's syntax deliberately diverges from C's type-first form, it rejects LLVM for comprehensibility, it does no C-header ingestion, and it declines memory-safety features that the Kernel Test does not forbid.
Hare's value to Elseon is the demonstrated engineering of specification discipline, defined failure behavior, and a kernel-clean runtime boundary.

Borrow list (concrete ideas with one-line rationale each):

- Specification-first design that defines behavior where C has undefined behavior, with conservative optimizer rules — gives Elseon a testable contract for its conformance tests.
- A permanent feature freeze at 1.0 plus source-compatibility-only standard library changes — matches Elseon's "boring" simplicity goal and protects users.
- Explicit `alloc`/`free` builtins with defined out-of-memory semantics (abort default, `nomem` for recoverable paths, nullable results) — a direct implementation of "no hidden allocations".
- No-allocation operation variants (`static append`/`static insert`) plus a compile flag that rejects any implicitly allocating construct in kernel builds — kernel-mode enforcement of no hidden allocation.
- A freestanding execution environment as a first-class spec concept, with a user-supplied runtime and a short documented list of functions the compiler emits calls to — a clean kernel-adjacent toolchain boundary Elseon should specify the same way.
- Nullable versus non-nullable pointer types with mandatory null tests — cheap, explicit safety that fits Elseon's checked call boundaries for ingested C headers.
- Bounds-checked slices as first-class types with a defined abort, alongside an explicit unbounded-array escape — the "explicit safety, not hidden control flow" pattern the Kernel Test admits.
- Tagged-union error values with exhaustive, mandatory handling and no exceptions — an error model worth borrowing into Elseon's own surface.
- `defer` for explicit scope-exit resource management instead of destructors — matches Elseon's explicit-resource-management rule with no hidden control flow.
- An `rt`/`debug` split and integrated terminal documentation tooling — cheap developer experience that aids adoption without runtime weight.

Avoid list (concrete things with one-line rationale each):

- A small-backend strategy in the style of qbe with a stated 25%–75% performance range — Elseon needs LLVM-grade optimization and already chose LLVM.
- Name-last declarations and expression-semicolon function bodies — needless friction against Elseon's C type-first family.
- `@init`/`@fini` with unspecified intra-module ordering — hidden control flow that fails Elseon's determinism rule.
- Shipping a `const` qualifier with weak, inconsistently enforced semantics for years before 1.0 — do not freeze ill-defined semantics; settle them before the feature freeze.
- No generics as a standing design constraint that forces hand-rolled hash tables — a self-imposed burden with no Kernel-Test justification.
- Manual forward-declaration FFI with no C-header ingestion — the exact re-declaration pain Elseon's PFE semantic header import eliminates.
- Language-specified but not C-identical struct layout that requires hand padding for ABI compatibility — Elseon must guarantee C-compatible representation for ingested header types at the semantic layer.
- Bounds/OOM aborts as the only defined failure path with no language-level way to configure per-target failure policy — Elseon should let failure behavior be explicit and compilable-out, never silently different.
- A draft specification left non-authoritative for years while the language is in use — set a hard spec-authoritative milestone before broad adoption.

## 10. Evidence

Primary sources (fetched and read 2026-09-03 unless noted):

- Hare home page: https://harelang.org/
- Language announcement (2022-04-25): https://harelang.org/blog/2022-04-25-announcing-hare/
- "Will Hare replace C?" scope post (2022-05-02): https://harelang.org/blog/2022-05-02-what-is-hares-scope/
- "Hare's advances compared to C" (2021-02-09): https://harelang.org/blog/2021-02-09-hare-advances-on-c/
- "Safety features of the Hare programming language" (2022-06-21): https://harelang.org/blog/2022-06-21-safety-features/
- "Strategies for handling OOMs in Hare programs" (2021-04-28): https://harelang.org/blog/2021-04-28-oom-strategies/
- "Future research areas" (2021-03-30): https://harelang.org/blog/2021-03-30-future-research-areas/
- "Hare is a boring programming language" (2022-11-27): https://harelang.org/blog/2022-11-27-hare-is-boring/
- "Hare aims to become a 100-year programming language" (2023-11-08): https://harelang.org/blog/2023-11-08-100-year-language/
- "Happy fourth birthday, Hare!" (2023-12-27): https://harelang.org/blog/2023-12-27-hare-4th-birthday/
- Hare 0.24.0 release and release policy (2024-02-16): https://harelang.org/blog/2024-02-16-hare-0.24.0-released/
- "A tour of upcoming RFCs" (2025-06-02): https://harelang.org/blog/2025-06-02-planned-breaking-changes/
- hare-update announcement (2025-06-11): https://harelang.org/blog/2025-06-11-hare-update/
- Hare 0.26.0 release (2026-02-13): https://harelang.org/blog/2026-02-13-hare-0.26.0-released/
- Blog index (release timeline): https://harelang.org/blog/
- "Making Hare more debuggable" (2022-11-04): https://harelang.org/blog/2022-11-04-making-hare-debuggable/
- "New debugging features coming to Hare" (2024-02-01): https://harelang.org/blog/2024-02-01-debugging-features/
- "Cross-compiling Hare programs is easy" (2022-09-06): https://harelang.org/blog/2022-09-06-cross-builds-with-hare/
- "powerctl: A small case study in Hare" (2022-08-28): https://harelang.org/blog/2022-08-28-powerctl-a-hare-case-study/
- "Introducing builtwithhare.org" (2025-08-22): https://harelang.org/blog/2025-08-22-builtwithhare.org/
- Hare FAQ (qbe rationale, C/Go/Rust/Zig comparisons, threads, generics, platform policy): https://harelang.org/documentation/faq.html
- Language specification landing and draft PDF: https://harelang.org/specification and https://harelang.org/specification.pdf
- Standard library reference (module inventory): https://docs.harelang.org/
- "System libraries and C FFI" documentation: https://harelang.org/documentation/usage/system-libraries.html
- "Freestanding Hare programs" documentation: https://harelang.org/documentation/usage/freestanding.html
- Installation guide with supported platforms: https://harelang.org/documentation/install/index.html
- Bootstrapping guide: https://harelang.org/documentation/install/bootstrap.html
- Hare extended libraries list: https://harelang.org/documentation/extlib.html
- Hare standard library and tooling repository (licensing, contribution rules): https://git.sr.ht/~sircmpwn/hare
- harec compiler repository ("Hare bootstrap compiler", C11): https://git.sr.ht/~sircmpwn/harec
- Helios microkernel project (seL4-inspired, Hare toolchain): https://sr.ht/~sircmpwn/helios/
- Hermes microkernel repository: https://git.sr.ht/~sircmpwn/hermes
- Ares operating system project: https://sr.ht/~sircmpwn/ares/
- qbe compiler backend (referenced by Hare): https://c9x.me/compile/

Observational and secondary sources:

- Debian package tracker for hare (0.26.0.1-1 in main, testing; verified 2026-09-03): https://tracker.debian.org/pkg/hare
- Debian ITP for hare (2023; page behind an anti-bot wall, title from search): https://bugs.debian.org/1058645
- Fedora change proposal for Hare (2023–2024): https://fedoraproject.org/wiki/Changes/HareProgrammingLanguage
- The Register launch coverage (secondary press, 2022-04-26): https://www.theregister.com/software/2022/04/26/heresy-hare-programming-language-an-alternative-to-c/
- LWN coverage of the announcement (secondary press): https://lwn.net/Articles/893796/

Classification reference inspected but not modified:

- Elseon related-work survey: `documents/08-related-work.md`
- Elseon language design and Kernel Test: `documents/07-elseon-language.md`
