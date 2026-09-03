# C-Comparison Synthesis: C3, Odin, Hare, Val (Hylo), Cake

> Synthesis deliverable of episode 1-A (`prompts/episodes/02-episode-plan.md`).
> It pools the five C-comparison study notes and feeds phase 2 (language
> specification). The comparison baseline is C.

This document compares the five studied candidates — C3, Odin, Hare, Val
(now Hylo), and Cake — on the criteria in
`prompts/common/04-c-comparison-criteria.md` (authoritative; unmodified).
Across the five it states what has been tried before, what worked, and what
did not work; it selects the ideas Elseon should use and the ideas Elseon
should avoid, each with reasoning and the source study; it recommends
candidates to drop from the list (the human decides); and it proposes
revisions to criteria that proved weak or missing (proposals only, the
criteria file is not modified).

## 1. Inputs, method, and provenance

Inputs and their roles:

- `prompts/common/04-c-comparison-criteria.md` — authoritative study
  criteria; compared against, not modified.
- `documents/13-c3-vs-c.md` (C3 study), `documents/14-odin-vs-c.md` (Odin
  study), `documents/15-hare-vs-c.md` (Hare study),
  `documents/16-val-vs-c.md` (Val study), `documents/17-cake-vs-c.md`
  (Cake study) — the five completed study notes, each following the
  10-heading study-note structure from the criteria file.
- `documents/08-related-work.md` (survey) — the starting survey whose rows
  the studies verify, refine, or correct.
- `documents/07-elseon-language.md` (language doc) — Elseon's kernel test,
  principles, and syntax family used as the comparison standard.

Method and provenance rules:

- Every claim in this synthesis traces to one of the five study notes or to
  the survey; no claim is added from outside those sources.
- Where a study marks a claim "unverified", this synthesis carries that
  marking rather than upgrading it.
- Where a study distinguishes "stated by the project" from "observed in
  practice", this synthesis preserves the distinction.
- Live-state facts inside the studies were recorded around 2026-09-03; this
  synthesis adds no new live facts.
- Verdicts use the criteria-file classification vocabulary (model / idea
  source / avoid), extended where a study needed a qualifier (for example
  Hare's "idea source with selected model aspects").

## 2. The five candidates as the studies left them

| Candidate | Refined identity (per study) | Survey camp | Study verdict | Backend |
|---|---|---|---|---|
| C3 | Applications-targeted "evolution of C"; documented fork of C2 that outgrew it; modules replace headers; no PFE header ingestion; safe-mode checks vanish at -O2 | Camp 1 (with C2 as one lineage) | Idea source — the strongest Camp 1 sibling, not a model | LLVM |
| Odin | Data-oriented "C alternative"; C statement shape but type-last declarations; explicit allocators with an implicit per-scope context default; ships real software; self-hosted compiler | Camp 1 | Idea source, not a model | LLVM |
| Hare | Spec-first "boring" systems language; name-last declarations; QBE backend, not LLVM; manual FFI; free-software platforms only; builds real kernels with the stock toolchain | Camp 1 | Idea source with selected model aspects | QBE |
| Val / Hylo | Research language on mutable value semantics; Swift-shaped surface; renamed from Val to Hylo 2023; automatic compile-time memory management; pre-1.0 and officially "not ready to be used yet" | Camp 1 (row wording needs correction) | Idea source, not a model | LLVM |
| Cake | Camp 2 superset "C23 and beyond"; a C front end that transpiles to C89; compile-time ownership checks on ordinary C pointers; single-maintainer, GPLv3 plus AI-training addendum | Camp 2 | Idea source; the superset strategy itself is what Elseon avoids | None (emits C89) |

Row corrections and refinements the studies established:

- C3 and C2 are not two independent survey rows: C3 is documented as a fork
  of C2 by Bas van den Berg that outgrew it, so the survey pair reads as one
  lineage (C3 study §1).
- The survey's Odin row "C-like" should read "C-shaped with type-last
  declarations", and "explicit allocators" should read "explicit allocator
  mechanism with an implicit per-scope default allocator" (Odin study §1,
  §9).
- The survey's Hare row overstates with "no memory management required":
  memory management is manual with low-ceremony defaults, Hare supports only
  free software platforms (Linux and the BSDs upstream), its backend is QBE
  rather than LLVM, and "used to build a real OS" is verified via Helios,
  Hermes, and Ares (Hare study §1, §5).
- The survey's Val row overstates C-likeness: the surface is Swift-shaped,
  the language was renamed Hylo in 2023, and it remains research-stage and
  pre-1.0 (Val study §1, §9).
- The survey's Camp 2 Cake row is verified in essence and refined: Cake is a
  front end and transpiler rather than a full compiler, most of its "modern
  features" are later-standard C, and it is the most conservative Camp 2
  member — closer to a supercompiler or static analyzer than to a competing
  language (Cake study §1).

## 3. Comparison on the criteria

### 3.1 Positioning (criteria dimension 1)

- C3 claims to be the "ergonomic, safe evolution of C" for building native
  applications — an "improved C for application development", not primarily
  a safer C and not primarily a kernel language (C3 study §1).
- The C3 author concluded that marketing C3 as a "C alternative" or "C
  replacement" was a years-long mistake, because C programmers today mean
  OS/embedded/niche work by "what C is for", while C3 targets general
  applications (C3 study §1, §8).
- Odin positions as "the C alternative for the joy of programming" and a
  data-oriented language for modern systems, aimed at the "C alternative"
  programmer with games and graphics first but kernels, servers, and CLI/TUI
  work also intended (Odin study §1).
- The Odin creator states the language is not an "improved C" in the
  compatibility sense and deliberately has no "killer feature" (Odin study
  §1).
- Hare does not position as improved C, safer C, or a C replacement; it aims
  at longevity ("a 100-year programming language"), a boring conservative
  design, and a permanent freeze at 1.0, for long-lived systems software on
  free platforms (Hare study §1).
- Hare explicitly rejected the press framing of it as a C replacement (Hare
  study §1, §6).
- Val/Hylo positions against C++ and Rust, not C: a "high-level systems
  programming language" on mutable value semantics, research-stage and
  "not ready to be used yet" in both 2022 and 2026 wording (Val study §1).
- Cake does not position as a rival to C at all: it is "C23 and beyond", a
  front end for C programmers who want newer or experimental C on older
  toolchains and checked ownership without leaving C (Cake study §1).
- Synthesis: every candidate that framed itself against C as a replacement
  either retracted the frame (C3), denied it (Hare), or conceded weak
  adoption without one (Odin); the survivors position by purpose and domain
  instead.

### 3.2 Kernel-test adherence (criteria dimension 2)

The four Elseon guarantees are assessed per candidate; a study's "stated",
"observed", and "unverified" markings are preserved.

**No garbage collection / no hidden runtime.**

- C3: no GC is real and documented; "no runtime beyond what a kernel build
  accepts" is not demonstrated — freestanding ELF targets exist in the
  support matrix but are marked untested (C3 study §2).
- Odin: no GC runtime exists in the implementation; the compiler and its
  `base/runtime` provide allocator and context support, not a collector;
  hosted builds link a C runtime (Odin study §2, §5).
- Hare: passes with strong evidence — no libc by default, a minimal `rt`
  module, freestanding mode with a user-supplied `rt`, and a documented list
  of functions the compiler emits calls to (Hare study §2, §5).
- Val/Hylo: no tracing GC or managed runtime is described anywhere observed,
  so the guarantee holds in spirit, but management is automatic
  compile-time management; whether the current compiler emits runtime
  bookkeeping (for example reference counting for copy-on-write) is
  unverified (Val study §2).
- Cake: passes — the output is C89 source and the final compiler produces
  object code; no runtime, runtime library, or GC exists at any stage (Cake
  study §2).
- Elseon takeaway: no-GC is universal among the five; the differentiator is
  whether the runtime boundary is documented and kernel-clean, which only
  Hare demonstrates with real kernels.

**No hidden allocations.**

- C3: allocation mechanisms are explicit and allocator-aware, but allocation
  sites can be implicit — uninitialized `List`/`HashMap`/`DString` values
  default to the temp allocator, and the compiler injects a `@pool()` scope
  around `main` once a temp-allocation call is found (C3 study §2).
- Odin: the allocator mechanism is explicit and replaceable, but many
  allocation sites in core operations default to `context.allocator`
  (dynamic-array growth, string handling in core packages, `fmt`); a strict
  reading of Elseon's "no hidden allocations" fails for default Odin code
  (Odin study §2).
- Hare: allocation is the explicit `alloc` expression; out-of-memory behavior
  is defined (abort by default, `null` for nullable pointer types, the
  `nomem` error since about 0.25); `static append`/`static insert` never
  allocate and `-Fstrictoom` rejects implicitly allocating constructs — with
  the caveat that dynamic allocation still happens behind source-visible
  builtins and strings and dynamic slices carry implicit capacity state
  (Hare study §2).
- Val/Hylo: fails Elseon's strict guarantee — allocation is automatic and
  implicit for dynamic containers and for values whose storage must escape a
  scope; safe code never spells allocation out (Val study §2).
- Cake: passes for Cake's own semantics — the compiler introduces local
  temporaries and `alloca` for the optional C23 VLA, both source-visible,
  and never inserts a hidden heap operation (Cake study §2).
- Elseon takeaway: mechanism-level explicitness (Odin, C3) is not enough;
  site-level visibility in every mode is the standard, and Hare's
  strict-mode enforcement shows how to make the guarantee a compile error in
  kernel builds.

**No hidden control flow.**

- C3: no exceptions and no hidden unwinding — errors are optionals with
  pointer-sized faults and explicit `!`/`catch`/`try`/`defer`; constructors
  and destructors are rejected ("data is inert"); but safe mode (default at
  -O0/-O1) inserts implicit bounds checks, null checks, contract evaluation,
  and backtraces that unchecked mode (-O2+) removes, and `assert`/`unreachable`
  change meaning by mode (C3 study §2).
- Odin: no exceptions, no hidden dispatch, no implicit overloading; but
  bounds checks and union/`any` type assertions are on program-wide by
  default as panics (disable-able per statement or globally), the compiler
  generates `__$startup_runtime`/`__$cleanup_runtime` around `main`, and the
  implicit `context` is hidden state threaded through the calling convention
  (Odin study §2).
- Hare: errors are values with explicit postfix `?`/`!` operators and
  exhaustive `match`; bounds failures and OOM aborts are defined and
  deterministic but are control transfers the programmer does not write; the
  two caveats are hosted `@init`/`@fini` with ordering within a module
  undefined, and freestanding init/fini behavior left undefined (Hare study
  §2).
- Val/Hylo: the compiler automatically inserts deinitialization instructions
  at the end of storage lifetimes, so synthesized scope-exit code exists by
  design; whether user-written deinit bodies run implicitly at scope exit in
  the current compiler is unverified; no exceptions appear in the language
  tour, and the concurrency plan (spawn/await with the same syntax as
  synchronous code) is still under design (Val study §2).
- Cake: compiling standard C is a faithful lowering; the opt-in extension
  layer adds execution at unwritten points — `_Defer` scope-exit blocks and
  the postfix checked `!` that transfers to the nearest catch; `try`/`catch`
  is a visible local-jump construct and cannot cross function boundaries
  (Cake study §2).
- Elseon takeaway: the explicit error-value family (C3, Odin, Hare) matches
  Elseon's posture; the recurring violations Elseon rejects are
  mode-dependent checks (C3), default-on panics (Odin), implicit
  initialization/deinitialization (Val, Hare `@init`/`@fini`), and
  scope-exit sugar (Cake `_Defer`).

**Deterministic memory layout.**

- C3: the strongest dimension — fixed-width integers, C layout rules by
  default with explicit control through `@packed`, `@align`, endianness
  attributes, and `bitstruct`; signed overflow always wraps and evaluation
  order is defined; whether "never reordered" is an explicit language
  guarantee is unverified (C3 study §2).
- Odin: struct fields are laid out in source order with a strong
  directive toolbox (`#packed`, `#align`, `#raw_union`, field-alignment
  bounds, endian-specific integer types) and compile-time
  `size_of`/`offset_of`/`#assert`; the formal layout contract is thinner
  than Elseon's promise, and no published statement equates default layout
  to a specific C ABI (Odin study §2, §4).
- Hare: layout is specified per platform (field offsets per the spec,
  `@packed` for zero padding); alignment values and pointer representation
  are implementation-defined with bounds; reproducing a specific C struct is
  a manual job — 0.26.0 replaced the labor-intensive `@offset` attribute
  with explicit unnamed padding fields (Hare study §2).
- Val/Hylo: no language-level layout control (padding, alignment, field
  order) was found; `MemoryLayout<T>` runtime queries read the compiler's
  choice rather than fixing it; deterministic layout in Elseon's sense is
  unmet or at best unverified (Val study §2).
- Cake: changes no layout semantics — layout is C's, decided by the
  downstream compiler for the selected target via `-target`; cross-target
  correctness depends on Cake's target model matching the real compiler's
  ABI, and no failure was observed in the study (unverified in practice)
  (Cake study §2).
- Elseon takeaway: Elseon's promise — language-specified layout honored by
  the backend and C-compatible for ingested types — is stronger than any of
  the five delivers; C3 and Odin provide the vocabulary, Hare shows why
  hand-tuning is not a substitute for a guarantee.

**C-compatibility (the fourth kernel-test element).**

- C3: full C ABI compatibility is a headline claim exercised by mixed
  C/C3 builds (vkQuake) (C3 study §2, §4).
- Odin: ABI compatibility is a property of the procedure boundary and of
  programmer-declared types; Odin structs are not automatically their C
  counterparts (Odin study §4).
- Hare: uses "a superset of the standard C ABI", refined to "mostly" —
  excluding decimal types, complex numbers, `long double`, and `int128_t`
  (Hare study §4).
- Val/Hylo: minimal `@ffi` bindings exist; no evidence that arbitrary Hylo
  user types get a guaranteed C-compatible layout (Val study §4).
- Cake: inherited trivially because its output is C (Cake study §4).

### 3.3 Syntax family (criteria dimension 3)

- C3 keeps C's statement shape and return-type-first declarations with a
  mandatory `fn`, and adds slices, optionals, `defer`, `foreach`, and value
  methods; the grammar reshapes the surface — PascalCase types versus
  lower-case identifiers (a lexer rule), types moved left in arrays, and
  `const`/`volatile`/`restrict` removed (C3 study §3).
- Odin keeps the C statement shape and operator precedence but deliberately
  rejects C's type-first declarations (`x: int`, `x := 1`, pointers `^int`),
  has no `while`, makes semicolons optional, and offers `when` instead of a
  preprocessor; the type-last form comes from Pascal/Newsqueak (Odin study
  §3).
- Hare keeps the C statement shape and mental model but uses name-last
  declarations (`let x: int = 5;`), `fn` with expression-style bodies ending
  `= { ... };`, tagged-union types, and has no generics, classes, macros, or
  closures as of the studied material (absence after 0.26.0 unverified)
  (Hare study §3).
- Val/Hylo's surface is Swift-shaped: `fun`, `let`/`var`, `inout`,
  `subscript`, argument labels, `&` marking mutation (explicitly not
  address-of), and `${...}` interpolation; its documentation is written for
  Swift users, not C programmers (Val study §3).
- Cake's surface is C itself (the C23 grammar); its extensions read like C
  — qualifiers after `*`, `_Defer { ... }`, `try`/`catch`, postfix `!` — and
  the C23 preprocessor remains central (Cake study §3).
- Synthesis on distance from Elseon's C/JavaScript family: C3 is closest,
  Cake is C by construction, Odin and Hare keep the statement shape but
  break the declaration form, and Val/Hylo leaves the family entirely.
- Surface choices the studies identify as kernel-test failures for Elseon:
  C3's mode-dependent semantics and its removal of `const`/`volatile`; Odin's
  type-last declarations, implicit `context`, and default-on checks; Hare's
  name-last declarations and weak `const`; Val/Hylo's automatic-management
  semantics and Swift surface; Cake's `_Defer` and postfix `!` implicit
  execution points.

### 3.4 C interoperability and the PFE angle (criteria dimension 4)

- C3: full C ABI with mixed builds, but calling C is hand-written `extern`
  re-declaration with a long gotcha list (bit fields, enums, atomics, no
  `const`/`volatile`, non-decaying arrays); an automatic C-to-C3 converter
  is only a future help-wanted item (C3 study §4).
- Odin: the `foreign` system with manual per-procedure declarations,
  `core:c` type mapping, and `cstring`; bindings in the official `vendor`
  are hand-written; community binding generators exist to reduce the toil
  (Odin study §4).
- Hare: forward-declaring C symbols with `@symbol`, `types::c` aliases,
  strings that need conversion, and no bitfield syntax; no C-header
  ingestion and no drop-in C compilation (Hare study §4).
- Val/Hylo: minimal `@ffi` bindings in the standard library and an
  `@external("halt")` mechanism; no PFE equivalent; the original headline
  ambition was C++ interoperability, which never shipped — a 2025 TU Delft
  thesis proposes a Clang-based design that remains a roadmap (Val study
  §4).
- Cake: interoperability is inherited because its output is C; headers
  remain text in C's preprocessor model, with the author's documented
  workaround of re-declaring `malloc` etc. because system headers carry no
  owner qualifiers (Cake study §4).
- Synthesis: none of the five offers Elseon's PFE — C headers ingested as
  first-class semantic modules; the nearest in ABI terms (C3) still treats a
  converter as future work, and every study documents the manual
  re-declaration burden Elseon's semantic header import removes.

### 3.5 Toolchain (criteria dimension 5)

- C3: LLVM backend (LLVM 19–24 supported, default 23); compiler written in C
  with a small C++ LLVM wrapper; LLVM codegen and linking take over 98% of
  unoptimized compile time (author-measured); integrated `project.json`
  build with `c3c init/build/run/test`; 0.8.3 at observation, 1.0 targeted
  2028-06; freestanding and MCU targets untested (C3 study §5).
- Odin: LLVM C API backend since dev-2021-05; the compiler is self-hosted in
  Odin; one-command build with monthly `dev-YYYY-MM` binary releases and CI;
  freestanding builds exist but are not turnkey (SSE cannot be disabled on
  x86, startup/cleanup runtime and `Context` layout must be handled, `core:`
  replaced); no incremental compilation and no official package manager (Odin
  study §5).
- Hare: QBE backend (roughly 15,000 lines of portable C99), chosen so one
  person can understand the toolchain; QBE-generated code runs at 25% to 75%
  of comparable LLVM-generated code; `harec` is a C11 bootstrap compiler and
  the standard library is written in Hare; static linking by default;
  freestanding is a documented first-class build path; the specification is
  explicitly a draft not considered authoritative (Hare study §5).
- Val/Hylo: LLVM backend with the compiler written in Swift (6.2/6.3);
  the classic `hc` compiler is being sidelined by the hylo-new restart whose
  first experimental LLVM-lowering release came in May 2026 (v0.0.1),
  reaching v0.0.8 in August 2026; the classic repository's only release is
  tagged v-old-0.0.42; `--freestanding` exists on paper with `halt` as the
  only required external function (Val study §5).
- Cake: no machine-code backend — it emits C89 source for GCC, MSVC, or
  Clang, so optimization is whatever the downstream compiler achieves;
  trivial GCC bootstrap and CI on three host compilers; the front end
  performs no inlining (`inline` is equivalent to `static`); pre-1.0 with an
  informal release process and a GPLv3 license plus an AI-training addendum
  (Cake study §5).
- Synthesis: three of five candidates run LLVM, corroborating Elseon's
  backend choice; the studies supply the calibration — LLVM costs dominate
  compile time (C3), a small backend costs runtime performance (Hare), and
  a transpiler floor costs expressiveness and optimization (Cake).
- Kernel-adjacent constraint: only Hare demonstrates a kernel-clean runtime
  boundary with real kernels; C3's freestanding story is untested, Odin's is
  community-driven, Val/Hylo's is a flag on paper, and Cake has no
  freestanding or kernel target in its list.

### 3.6 Ecosystem and adoption (criteria dimension 6)

- C3: about 5,800 stars and ~400 forks at observation; dual MIT (stdlib,
  tests, examples) and LGPL 3.0 (compiler sources under `src`); showcase
  dominated by bindings, games, emulators, a UEFI library, and one hobby
  microkernel (muon-kernel); no company or product-scale adoption documented
  (unverified if any exists); pre-1.0 with regular monthly releases (C3
  study §6).
- Odin: about 11.9k stars and 1.1k forks; zlib license; shipping real
  software — Blick (video editor), Vigil, Fish Lab and Daisy Trains (Steam
  games), VirtualXT (emulator) — and a self-hosted compiler; kernel use is
  hobby-scale (flysand7) with no mainstream kernel or embedded production
  codebase; growth stated as "steady, stable, and albeit slow" with thin
  funding (Odin study §6).
- Hare: Helios, Hermes, and Ares kernels and userspace built with the stock
  toolchain; Debian packaging in main; MPL standard library, GPL-3.0-only
  executables, GNU FDL specification; free-software platforms only; no
  package manager by stated preference ("encourage[s] less code reuse")
  (Hare study §6).
- Val/Hylo: about 1.55k stars (hylo) and 37 (hylo-new); no production or
  kernel use found (absence of evidence, not proof of absence); research
  papers and TU Delft theses; Apache-2.0; naming churn from the Val-to-Hylo
  rename left dead domains and redirects; the "not ready to be used yet"
  sentence survived from 2022 to 2026 (Val study §6).
- Cake: about 701 stars, single-maintainer (1,114 of 1,134 commits by
  thradams); the ownership checks are used by Cake's own source and one
  embedded toolchain (Catalina/Propeller, title-level evidence); GPLv3 plus
  an AI-model-training-restriction addendum; pre-1.0 with no stable release
  (Cake study §6).
- Synthesis: adoption correlates with shipping software (Odin, Hare) and
  with a kernel story (Hare); hobby-scale kernel work exists in C3, Odin,
  and Hare, but only Hare's is first-class through the stock toolchain.

## 4. What has been tried, what worked, and what did not work

### 4.1 Recurring patterns across the five

- Manual memory management with no GC: tried by all five; works everywhere
  it is actually manual (C3, Odin, Hare) and is bypassed by automatic
  management in Val/Hylo.
- Explicit allocators: tried by C3 (malloc/free plus temp arena), Odin
  (allocators as data with a context default), and Hare (alloc builtins
  with defined OOM); each kept a default or arena to reduce ceremony, and
  each default became an implicit-allocation hazard.
- Modules replacing headers and the preprocessor: tried by C3 (`module`/
  `import`), Odin (packages plus compile-time `when`), Hare (`use`/`::`),
  and Val/Hylo (file-based modules with resilience boundaries); worked at
  standard-library scale in C3 and Hare; Cake stays inside C's textual
  preprocessor.
- Error values instead of exceptions: tried by C3 (optionals), Odin
  (multi-return with `or_return`), and Hare (tagged unions with `?`/`!`);
  worked as the core error model; Cake adds a visible local `try`/`catch`,
  and Val/Hylo's tour shows no exceptions.
- Bounds and null checks: tried by C3 (safe-mode-only, vanish at -O2), Odin
  (default-on panics), Hare (defined aborts with an unbounded escape), and
  Cake (compile-time ownership and nullability); the recurring failure is
  checks that are implicit or mode-dependent rather than explicit in source.
- Deterministic-layout control: tried by C3, Odin, and Hare with different
  depths of guarantee (C attributes-plus-fixed-widths, Odin directives, Hare
  spec-defined offsets); none guarantees C-compatible layout as a language
  promise for arbitrary foreign structs.
- Scope-exit behavior: `defer` is explicit and source-visible in C3, Odin,
  and Hare and works; Val/Hylo's automatic deinitialization and Hare's
  `@init`/`@fini` show the failure mode of implicit scope-exit execution;
  Cake's `_Defer` is opt-in sugar Elseon would re-express.
- Freestanding and kernel builds: tried by all; only Hare's is a documented,
  first-class path with real kernels; C3's targets are untested, Odin's
  require manual workarounds, Val/Hylo's is a flag on paper, and Cake has no
  kernel target.

### 4.2 What worked (with where it was observed)

- Staying close to C where it matters — statement shape, ABI, manual memory —
  works for onboarding C programmers (C3 study §7; Odin's and Hare's C-shaped
  statement form).
- Modules replacing user headers and the preprocessor work at scale: C3 runs
  its whole standard library without `#include` (C3 study §7); Hare's
  namespace model underlies its standard library (Hare study §7).
- Value-returning errors without exceptions work as the core error model:
  Hare calls tagged unions "the key innovation" and the standard library
  uses them throughout (Hare study §7); C3 dogfoods optionals in its
  standard library (C3 study §7); Odin's self-hosted compiler is practical
  evidence that a large low-level codebase lives without exceptions or
  hidden dispatch (Odin study §7).
- Scope-based arenas with an explicit pool work as a memory idiom: C3's temp
  allocator with `@pool` gives GC-like ease with manual predictability and a
  project-reported clean Valgrind run (C3 study §7); Odin's temp allocator
  with `free_all` is a practical per-frame pattern (Odin study §7).
- "Data is inert" — rejecting constructors and destructors — kept C3
  simpler and survived years of use (C3 study §7); it matches Elseon's
  explicit-resource-management rule.
- Determinism fixes C lacks — fixed widths, defined overflow, no implicit
  narrowing, defined evaluation order, zero-initialization — work and remove
  whole bug classes (C3 study §7).
- Spec-first design that defines behavior instead of C's undefined behavior
  works as a process: Hare's spec, kernels, and crypto suite are built
  against it, and the spec constrains optimizer rewrites (Hare study §7).
- Feature-freeze ambition and "boring language" conservatism work as a
  community and stability strategy: Hare sustains a multi-year pre-1.0 phase
  without feature sprawl (Hare study §7); Odin keeps syntax "effectively
  done" while iterating on libraries (Odin study §7).
- A freestanding environment with a user-supplied runtime and a documented
  compiler/runtime contract works for kernel builds: Helios, Hermes, and
  Ares build with the stock Hare toolchain (Hare study §7).
- Self-hosting and dogfooding work as the strongest usability evidence: the
  Odin compiler is written in Odin (Odin study §7); Hare's standard library
  and tooling are written in Hare (Hare study §7); Cake runs its front end
  over its own source (Cake study §7).
- Compile-time-only checks with zero runtime cost work where the analysis is
  intra-procedural: Cake's ownership and nullability contracts run on
  ordinary C pointers with "no runtime overhead", exercised on Cake's own
  codebase (Cake study §7).
- The C-standard-ahead laboratory works as PFE applied to the standard
  itself: Cake implements C23 and experiments with C2Y proposals against
  WG14 N-documents (Cake study §7).
- LLVM is the best first backend despite real costs: C3's author measured
  that codegen dominates compile time and LLVM is "very much a backend for
  C/C++", yet calls it the best backend to start with (C3 study §7); Odin and
  Val/Hylo run on LLVM.
- Iterating in public with honest accounting works: C3's monthly releases,
  deprecation-first breaking changes, design post-mortems, and docs-drift
  warnings (C3 study §7); Val's 2022 implementation-status page is a model of
  honest staging (Val study §7); Hare's RFC process and migration tool smooth
  breaking changes (Hare study §5).
- High-quality configurable diagnostics work as a differentiator: Cake's
  numbered, individually enable-able warnings with SARIF output plug into
  Visual Studio and VS Code (Cake study §7).

### 4.3 What did not work (with where it was observed)

- Framing a language as a "C alternative" or "C replacement" failed as
  marketing: C3's author called it a years-long mistake (C3 study §8);
  Odin's creator concedes the language has no "killer feature" to market and
  growth is slow (Odin study §8); Hare rejected the press framing outright
  (Hare study §1).
- Mode-dependent safety failed: C3's bounds/null checks and contracts exist
  only in safe mode and vanish at -O2, with `assert` degrading to an
  optimization hint; the author concedes fast mode is "just as unsafe as C"
  (C3 study §8).
- Implicit allocation through defaults failed and had to be reverted: Odin
  disallowed dynamic literals by default in dev-2025-01 "to remove implicit
  allocations from Odin" (Odin study §8); C3's uninitialized-container
  defaults and compiler-injected `@pool` are hidden allocations by Elseon's
  standard (C3 study §2, §9).
- Automatic memory management failed Elseon's test in Val/Hylo: compiler-
  inserted deinitialization is hidden scope-exit behavior and COW containers
  hide sharing and potential allocation behind value syntax (Val study §8,
  §9).
- Implicit startup and finalization failed or stayed ill-defined: Odin's
  generated `__$startup_runtime`/`__$cleanup_runtime` is invisible startup
  behavior (Odin study §2); Hare's `@init`/`@fini` ordering is undefined
  within a module and undefined in freestanding builds (Hare study §2).
- The implicit context system has sharp edges: an Odin context value cannot
  be updated from within a loop, forcing workarounds (Odin study §8).
- Superset-of-C cannot fix C's semantics: Cake can only warn about
  undefined behavior, bounds, and implicit conversions, and warnings do not
  remove the bug classes unless a whole project opts in and stays opted in
  (Cake study §8).
- A lowered old-C codegen target caps the language: Cake's C89 floor makes
  features unimplementable (complex types, `_Atomic`, `_BitInt`, decimal
  floats), rewrites are lossy beyond 64-bit doubles, and the front end does
  no inlining so the second compiler must re-optimize lowered code (Cake
  study §8).
- A small backend costs runtime performance: Hare's qbe-generated code runs
  at 25% to 75% of comparable LLVM-generated code (Hare study §8).
- No-C-header-ingestion interop is laborious everywhere: C3's hand-written
  `extern` re-declaration with a long gotcha list and a converter that
  remains help-wanted (C3 study §8); Odin's manual foreign re-declaration
  with layout equivalence left to the programmer (Odin study §8); Hare's
  manual forward declarations, hand-tuned struct layout, and string
  conversions (Hare study §8); Cake's re-declaration workaround for
  unannotated system headers (Cake study §8).
- Removing or weakening C qualifiers backfired: C3 removed `const`/
  `volatile`/`restrict`, harming header fidelity (C3 study §3); Hare shipped
  `const` with weak, inconsistently enforced semantics for years, and its own
  RFC tour says the planned overhaul "will break nearly every existing Hare
  codebase" (Hare study §8).
- Decade-long pre-1.0 breaking changes cost users: C3 breaks in every 0.x.0
  release with 1.0 targeted 2028 (C3 study §8); Odin's `dev-2026-03`
  replaced `core:os` with a rewritten v2 (Odin study §8); Hare plans breaking
  changes through an RFC process before its 1.0 freeze (Hare study §5).
- Compiler restarts cost years: Val/Hylo archived implementation generations
  and restarted as hylo-new, whose first usable LLVM-lowering release came
  five years after repository creation (Val study §8).
- Name and domain churn destroyed continuity: the Val-to-Hylo rename left a
  dead domain, redirects, a Slack workspace still named "val", and naming
  collisions with Vale, Vala, and an unrelated Val (Val study §6, §8).
- Optional, annotation-only safety is advisory: Cake's checks can be
  silenced per function or bypassed by extracting raw pointers, skeptics
  argue annotation-first schemes cannot retrofit real libraries, and only
  Cake itself uses the checks (Cake study §8).
- Local-only analysis pushes work into annotations and suppressions: Cake's
  analysis is not inter-procedural, forcing `//lint` suppressions exactly
  where bugs live (Cake study §8).
- Platform overreach without testing wasted credibility: C3's WASM is
  "really incomplete" with no CI and freestanding/MCU targets untested (C3
  study §8); Odin dropped macOS AMD64 from CI in 2026 (Odin study §8); Cake
  targets no kernel platform (Cake study §5).
- A draft specification left non-authoritative for years is a risk: Hare's
  spec started early and is still a draft in 2026 (Hare study §8).
- No generics as a permanent constraint costs real effort: Hare's deliberate
  omission pushes hash tables and containers onto every programmer, a
  friction with no kernel-test justification (Hare study §8).
- No threading support caps reach: Hare's standard library has no
  multithreading, ruling it out for many use cases (Hare study §8).
- Weak ecosystem mechanics slowed adoption: C3 has no package manager and no
  product-scale adoption documented (C3 study §8); Odin's permanent
  no-package-manager policy shifts dependency costs onto users (Odin study
  §8).
- Breaking-freeze timing matters: freezing a weak `const` (Hare) and waiting
  a decade to freeze anything (C3) are both failure modes; settle semantics
  before the freeze.
- Compiler licensing can poison reuse: Cake's GPLv3 plus AI-training
  addendum makes embedding it into a non-GPL toolchain problematic (Cake
  study §5, §8).

### 4.4 What nobody has tried — the PFE gap

- No candidate ingests C headers as first-class semantic modules: C3's
  converter is future work, Odin's bindings are hand-written, Hare's FFI is
  manual forward declaration, Val/Hylo's C-interop work is a research
  roadmap, and Cake keeps headers as text (C3 study §4; Odin study §4; Hare
  study §4; Val study §4; Cake study §4).
- Every candidate pays the re-declaration tax that Elseon's PFE removes
  (survey §"What this means for Elseon"; each study's C-interop section).
- The survey's third position — compatibility without superset baggage and
  without re-declaring the world — is therefore unoccupied by any studied
  candidate (survey; confirmed per-study).

## 5. Use list for Elseon

Each item names the reasoning and the source study. Admission remains
subject to the kernel test; items from candidates whose own semantics fail
the test are borrowed as mechanisms only.

Memory and allocation:

1. Explicit allocators as data, with any per-scope default spelled out in
   source — reasoning: Odin proves the mechanism works and ships software;
   the default must be source-visible to satisfy Elseon's no-hidden-
   allocations rule (Odin study §2, §9).
2. Scope-based arena idiom with bulk free — reasoning: C3's temp allocator
   with an explicit `@pool` and Odin's temp allocator with `free_all` give
   per-frame memory with manual predictability (C3 study §7, §9; Odin study
   §9).
3. Tracking allocator for leak and bad-free detection at debug time —
   reasoning: cheap, build-time-gated verification observed working in Odin
   (Odin study §7, §9).
4. Defined out-of-memory behavior: abort by default, a recoverable error
   path, and nullable results — reasoning: Hare specifies OOM instead of
   leaving it hidden, matching "no hidden allocations" (Hare study §2, §9).
5. No-allocation operation variants plus a strict-mode compile flag that
   rejects any implicitly allocating construct — reasoning: Hare's `static
   append`/`static insert` and `-Fstrictoom` enforce the guarantee at kernel
   build time (Hare study §2, §9).
6. Compiler-known pointee contracts for standard allocators
   (`_Uninitialized`/`_Clear` on malloc/calloc) — reasoning: Cake catches
   use-before-init and null passing at compile time with zero runtime cost
   (Cake study §7, §9).

Errors and control flow:

7. Value-returning errors with no exceptions — reasoning: proven in three
   candidates (C3 optionals with pointer-sized faults; Odin multi-return
   with `or_return` spelled in source; Hare tagged unions with exhaustive
   `match` and `?`/`!`) with zero hidden control flow (C3 study §7, §9; Odin
   study §9; Hare study §7, §9).
8. Explicit `defer` for scope-exit resource management — reasoning: matches
   Elseon's explicit-resource-management rule with no hidden control flow
   (C3 study §9; Odin study §9; Hare study §9; language doc §4).
9. Nullable versus non-nullable pointer types with mandatory null tests —
   reasoning: Hare's cheap, explicit safety fits Elseon's checked call
   boundaries for ingested C headers (Hare study §7, §9).
10. Bounds-checked slices as first-class types with an explicit unbounded
    escape hatch — reasoning: deterministic, ABI-friendly iteration in C3,
    Odin, and Hare; the checks must be explicit per Elseon's standard (C3
    study §9; Hare study §9; Odin study §9).
11. Mutable-value-semantics mechanisms where they fit: a semantic `&`
    mutation marker, subscripts/`inout` projections, consuming moves, and
    definite (de)initialization as a compiler pass — reasoning: Val/Hylo's
    research shows alias-free mutation with visible markers; Elseon takes
    the mechanisms, not the automatic management, and uses the pass
    technique in conformance checks (Val study §7, §9).

Determinism and layout:

12. Fixed-width integer types, defined wrapping, no implicit narrowing,
    defined evaluation order, zero-initialization with an opt-out —
    reasoning: C3 proves deterministic semantics C never standardized (C3
    study §7, §9).
13. A deterministic-layout toolbox: C-rules default layout plus explicit
    `@packed`/`@align`/endianness control and bit-accurate layout types —
    reasoning: C3's attributes and `bitstruct` and Odin's `#packed`/
    `#align`/`#raw_union`/endian-specific integers give the vocabulary for
    Elseon's language-specified layout (C3 study §2, §9; Odin study §2, §9).
14. Compile-time layout verification via `size_of`/`offset_of`/`#assert` —
    reasoning: Odin checks layout contracts at build time; Elseon's backend
    conformance tests need exactly this (Odin study §2, §9; language doc §6).
15. Spec-defined struct layout with source-order offsets as the fallback
    contract — reasoning: Hare demonstrates specifying offsets per platform;
    Elseon goes further and guarantees C compatibility at the semantic layer
    for ingested types (Hare study §2, §9).

Modules, toolchain, and the C boundary:

16. Module system replacing user headers and the preprocessor — reasoning:
    proven viable at standard-library scale in C3 and Hare; the same
    instinct as Elseon's semantic header import (C3 study §7; Hare study §7;
    survey).
17. Compiler-understood semantics for constructs C implements with macros
    (assert, offsetof, type traits) — reasoning: Cake shows the compiler must
    understand semantics, not text — the same instinct as Elseon's semantic
    header import (Cake study §7, §9).
18. Compile-time-only ownership and nullability checks placed at Elseon's
    C-header boundaries — reasoning: Cake's `_Owner`/`_Opt`/`_View`
    contracts give lifetime safety with zero runtime cost and incremental
    adoption; Elseon makes them part of the boundary system rather than
    optional annotations (Cake study §7, §9).
19. Numbered, configurable, IDE-integrated diagnostics (SARIF, gcc/msvc
    formats) and style checking from day one — reasoning: Cake shows tooling
    quality is a differentiator Elseon should ship early (Cake study §7, §9).
20. Self-hosting the compiler and standard library as dogfooding — reasoning:
    the strongest single evidence a systems language is usable, shown by
    Odin's compiler and Hare's standard library (Odin study §7; Hare study
    §7).
21. LLVM as the backend, accepting that codegen will dominate compile time —
    reasoning: three candidates run LLVM and C3's author measured the cost
    and still recommends it as the best first backend; matches Elseon's plan
    (C3 study §5, §7; language doc §6).
22. Freestanding environment as a first-class spec concept with a
    user-supplied runtime and a short documented list of compiler-emitted
    functions — reasoning: Hare's `rt` contract is the clean kernel-adjacent
    toolchain boundary Elseon should specify the same way (Hare study §7,
    §9).
23. One-command build, public CI, and integrated test/benchmark/docgen in
    the driver — reasoning: Odin's onboarding and C3's `@test`/`@benchmark`/
    docgen story keep CI-verifiability cheap (Odin study §7, §9; C3 study §7,
    §9).
24. A web playground for language evaluation — reasoning: Cake's reachable
    playground is a zero-install harness useful for Elseon's conformance
    corpus (Cake study §7, §9).

Process and governance:

25. Specification-first design that defines behavior where C has undefined
    behavior, with conservative optimizer rules — reasoning: Hare proves the
    discipline is workable and gives a testable contract for conformance
    tests (Hare study §7, §9).
26. A permanent feature freeze at 1.0 with source-compatibility-only
    standard-library changes — reasoning: Hare's "boring" 100-year plan
    matches Elseon's simplicity goal; but freeze only semantics that are
    already settled (Hare study §7, §9; Hare study §8 on `const`).
27. Feature-removal discipline and honest public accounting — reasoning:
    C3's removals and post-mortems freed compiler complexity and are a
    governance pattern for a pre-1.0 language (C3 study §7, §9).
28. The C-standard-ahead laboratory as PFE for language evolution —
    reasoning: Cake's tracking of C2Y proposals and WG14 N-documents gives
    Elseon a live design corpus for feature justifications (Cake study §7,
    §9).
29. Guaranteed cost invariants stated as language promises — reasoning:
    Val/Hylo's planned closure-allocation guarantee shows the value of
    spelling out invariants; Elseon should promise layout and allocation
    invariants the same way (Val study §7, §9).
30. Safe-by-default framing with explicit, auditable unsafe opt-in at the C
    boundary — reasoning: Val/Hylo's framing is workable; Elseon mirrors it
    for checks on ingested C headers (Val study §7, §9).

## 6. Avoid list for Elseon

Each item names the reasoning and the source study.

Memory and allocation:

1. Implicit allocation sites behind defaults — uninitialized-container
   defaults and a compiler-injected `@pool` (C3), and `context.allocator`
   defaults in core builtins, dynamic-array growth, and `fmt` (Odin) —
   reasoning: hidden allocations by Elseon's standard; Odin itself had to
   ban implicit dynamic literals in dev-2025-01 (C3 study §2, §9; Odin study
   §2, §8, §9).
2. Automatic memory management with compiler-inserted deinitialization and
   copy-on-write containers — reasoning: Val/Hylo's hidden scope-exit
   behavior and hidden sharing fail the kernel test, and deterministic
   layout must not rest on COW (Val study §2, §9).
3. An implicit per-scope `context` threaded through the calling convention —
   reasoning: Odin's hidden state flow is a documented source of bugs (the
   context cannot be updated in a loop) (Odin study §2, §8, §9).

Control flow and semantics:

4. Mode-dependent safety: checks only in safe mode that vanish at -O2 and
   `assert` degrading to an optimization hint — reasoning: C3's silent
   semantic drift is hidden control flow whose meaning changes with
   optimization level (C3 study §2, §9).
5. Default-on bounds and type-assert panics as hidden branches — reasoning:
   Odin's checks must be explicit opt-in in Elseon, not program-wide
   defaults (Odin study §2, §9).
6. Bounds/OOM aborts as the only defined failure path — reasoning: Hare
   gives no language-level way to configure per-target failure policy;
   Elseon should let failure behavior be explicit and compilable-out, never
   silently different (Hare study §9).
7. Implicit `@init`/`@fini` with unspecified ordering — reasoning: Hare's
   hidden control flow fails Elseon's determinism rule (Hare study §2, §9).
8. Scope-exit `_Defer` and postfix checked `!` as surface syntax —
   reasoning: Cake's implicit execution points violate Elseon's
   zero-hidden-control-flow standard unless re-expressed as explicit
   statements (Cake study §3, §9).

Syntax surface:

9. Type-last declarations and expression-semicolon function bodies —
   reasoning: Odin's `x: int` and Hare's `let x: int`/`= { ... };` are
   needless friction against Elseon's C type-first family (Odin study §9;
   Hare study §3, §9).
10. Swift-shaped surface (`fun`, `let`/`var`, `inout`, subscripts, argument
    labels, `&` redefined) — reasoning: Val/Hylo leaves Elseon's C/JavaScript
    syntax family entirely (Val study §3, §9).
11. Mandatory case-based identifier grammar for parseability — reasoning:
    C3's lexer rule sacrifices C identifier freedom for no kernel-test
    benefit (C3 study §3, §9).
12. Semicolon-optional syntax — reasoning: Odin's marginal friction helps
    neither machine nor reader of C-family code (Odin study §9).

C interop and the PFE boundary:

13. Removing `const`/`volatile` qualifiers and atomics keywords — reasoning:
    C3's removals harm C-header ingestion fidelity and const-correctness,
    which Elseon's PFE needs (C3 study §3, §9).
14. Shipping a `const` qualifier with weak, inconsistently enforced
    semantics for years — reasoning: Hare's `const` debt forced a planned
    overhaul that "will break nearly every existing Hare codebase"; settle
    semantics before the feature freeze (Hare study §8, §9).
15. Manual forward-declaration FFI as the primary C-interop path —
    reasoning: every study documents the re-declaration tax and none has
    header ingestion; Elseon's differentiator is ingesting the headers, with
    hand externs kept only as an escape hatch (C3 study §4, §9; Odin study
    §4, §9; Hare study §4, §9; Cake study §4).
16. Superset-of-C as the Elseon strategy — reasoning: extending C in place
    keeps C's semantic baggage and cannot give checked boundaries at the
    header edge; Elseon's PFE is the third position that avoids both Camp 2
    failure modes (Cake study §8, §9; survey).
17. Optional, annotation-only safety without mandatory boundaries —
    reasoning: if checks can be silenced per function or bypassed by
    raw-pointer extraction, the guarantee is advisory (Cake study §8, §9).
18. Inter-procedurally blind analysis with suppression escapes — reasoning:
    suppressions accumulate exactly where bugs live; plan cross-function
    inference or document the local granularity (Cake study §8, §9).

Toolchain and strategy:

19. A lowered old-C codegen target — reasoning: Cake's C89 floor becomes the
    language's ceiling, with unimplementable features and lossy rewrites;
    Elseon emits through LLVM (Cake study §8, §9).
20. A small-backend strategy in the style of qbe with a stated 25%–75%
    performance range — reasoning: Elseon needs LLVM-grade optimization and
    already chose LLVM (Hare study §8, §9).
21. Compiler core restarts — reasoning: Val/Hylo's archived generations and
    the hylo-new restart cost years; Elseon should treat the
    front-end/backend split and its conformance corpus as stable commitments
    (Val study §8, §9).
22. Name renames and domain churn — reasoning: Val-to-Hylo destroyed link
    equity and discoverability; Elseon should fix its name and URLs once
    (Val study §8, §9).
23. Announcing headline interoperability years before shipping —
    reasoning: Val's "Interoperable with C++" never shipped; Elseon's PFE
    claim should be gated on a working header-ingestion pipeline from
    milestone one (Val study §8, §9).
24. Marketing the language by what it replaces — reasoning: C3's documented
    "C alternative" mistake, Odin's conceded lack of a killer feature, and
    Hare's rejected press framing; position by purpose and domain (C3 study
    §8; Odin study §8; Hare study §1).
25. Decade-long pre-1.0 breaking changes — reasoning: C3 breaks in every
    0.x.0 toward a 2028 1.0; Elseon should freeze its core earlier (C3 study
    §8, §9).
26. Platform overreach without CI or testing — reasoning: C3's untested
    WASM/freestanding rows and Odin's macOS AMD64 CI drop are lessons in
    scope discipline (C3 study §8, §9; Odin study §8).
27. A draft specification left non-authoritative for years — reasoning:
    Hare's spec is still a draft in 2026 while the language is in use; set a
    hard spec-authoritative milestone (Hare study §8, §9).
28. No generics as a permanent constraint — reasoning: Hare's hand-rolled
    hash tables are a self-imposed burden with no kernel-test justification;
    nothing in the kernel test forbids safe, explicit generics (Hare study
    §8, §9).
29. Compiler licensing that blocks reuse — reasoning: Cake's GPLv3 plus
    AI-training addendum makes embedding problematic; take ideas, not code
    (Cake study §5, §8, §9).
30. Letting core documentation rot to "outdated" status and an open-ended
    "not ready" status without shipped milestones — reasoning: Val/Hylo's
    docs read as abandoned and its value proposition was untestable for four
    years; define what "ready" means and test it against the kernel corpus
    early (Val study §8, §9).

## 7. Candidate-drop recommendations (the human decides)

These are recommendations for the human to decide; nothing is decided here.
The criteria file keeps the list provisional ("a study may recommend
dropping a candidate in its verdict, and the synthesis task collects the
recommendations for the human to decide").

- Recommend dropping Cake from the active candidate list — reasoning: the
  study's verdict is that what Elseon avoids is the Camp 2 superset strategy
  itself, not the project's ideas; Cake contributes no language design to
  emulate (no new surface, no machine-code backend, GPLv3 plus AI-training
  addendum, single-maintainer and pre-1.0 with only self-use of its checks)
  (Cake study §9, §8). Its borrow-worthy ideas are already in the use list
  (§5) and its failure modes in the avoid list (§6), so continued candidacy
  adds no signal for phase 2 (Cake study §9).
- Recommend dropping Val/Hylo from the active candidate list — reasoning:
  its surface leaves Elseon's syntax family, its automatic memory management
  fails the kernel test, it offers no deterministic layout contract, it is
  pre-1.0 and officially "not ready to be used yet" from 2022 through 2026
  with a compiler restart and no stable release, and its kernel-adjacent
  suitability was never demonstrated; its value is as an idea source whose
  mechanisms are already extracted into the use and avoid lists (Val study
  §9, §8). If the human keeps it, it should be tracked as an archived idea
  source for value-semantics research, not as a design candidate.
- Recommend keeping C3, Odin, and Hare as the active reading set for phase 2
  — reasoning: C3 is the longest-running, most complete attempt with
  Elseon-like constraints and the best single source of proven design
  decisions (C3 study §9); Odin is the closest living proof that a no-GC,
  C-shaped, explicit-memory language can ship real commercial software (Odin
  study §9); Hare is the closest demonstration of the whole kernel-test
  recipe including real kernels, with model aspects for Elseon's
  specification and runtime boundary (Hare study §9).
- Recommend folding the C2 survey row into C3's lineage rather than dropping
  a studied candidate — reasoning: C3 is documented as a fork of C2, so the
  two rows describe one lineage (C3 study §1).
- No candidate classified as a full model and none as a full avoid; all five
  contributed items to the use and avoid lists, so dropping Val/Hylo or Cake
  from candidacy does not delete their findings from this synthesis.

## 8. Proposed criteria revisions (proposals only)

Proposed revisions to `prompts/common/04-c-comparison-criteria.md` for the
human to consider. The file is not modified by this task. Each proposal
names the evidence that showed the criterion weak or missing.

1. Add an identity-and-lineage check to dimension 1 (Positioning) —
   evidence: two of five candidates required identity work outside the
   criteria — C3 is a documented fork of C2 (C3 study §1), and Val was
   renamed to Hylo in 2023 with dead domains and naming collisions (Val
   study §1, §6).
2. Add an artifact-type classification to dimension 1 — evidence: Cake is a
   compiler front end and transpiler whose surface IS C, so comparing it as
   a "language" was awkward; the survey already carries non-language entries
   (CHERI/Morello as a hardware repair) that the candidate concept does not
   describe (Cake study §1).
3. Require an evidence-level tag (stated / observed / unverified) per
   kernel-test guarantee, with mode and optimization-level context where
   applicable — evidence: the studies answered guarantees at different
   standards — C3's freestanding targets are untested and its
   "never-reordered" guarantee is unverified (C3 study §2); Val/Hylo's
   runtime bookkeeping is unverified and its layout guarantee unmet or
   unverified (Val study §2); Cake's cross-target correctness is unverified
   in practice (Cake study §2).
4. Sharpen "no hidden allocations" and "no hidden control flow" to ask about
   source sites in every mode, not mechanisms — evidence: C3 and Odin both
   have explicit allocator mechanisms with implicit sites (container
   defaults, `context.allocator`), and C3's checks vanish at -O2 (C3 study
   §2; Odin study §2).
5. Add a toolchain sub-item for backend rationale, measured cost, and
   dogfooding evidence — evidence: C3 measured LLVM codegen at over 98% of
   compile time (C3 study §5); Hare's qbe costs 25%–75% of LLVM performance
   (Hare study §5); Odin's self-hosted compiler and Hare's Hare-written
   standard library were the strongest usability signals (Odin study §7;
   Hare study §7).
6. Add a license-and-reuse sub-item to dimension 6 (Ecosystem and adoption)
   — evidence: the five candidates carry five materially different license
   stacks (C3 MIT+LGPL 3.0; Odin zlib; Hare MPL+GPL-3.0+FDL; Val/Hylo
   Apache-2.0; Cake GPLv3 plus AI-training addendum), and Cake's license
   alone rules out code reuse (C3 study §6; Odin study §6; Hare study §6;
   Val study §6; Cake study §5, §6).
7. Ask for claimed versus observed positioning, including any first-party
   retrospection — evidence: C3's author retracted the "C alternative"
   framing (C3 study §8), Odin's creator concedes no killer feature and slow
   growth (Odin study §6, §8), and Hare rejected the press framing (Hare
   study §1); positioning predicted adoption failure modes better than any
   technical dimension.
8. Extend the verdict classification with a mandatory candidacy line (keep /
   drop / merge) and permit qualified classifications — evidence: the
   criteria say a study "may recommend dropping a candidate in its verdict",
   but none of the five did, leaving the synthesis to infer; and Hare needed
   the qualifier "idea source with selected model aspects", which the
   model/idea-source/avoid vocabulary does not name (Hare study §9).
9. Make the "stated by the project" versus "observed in practice"
   distinction mandatory per kernel-test guarantee rather than per study —
   evidence: application was inconsistent — C3 and Odin carried the
   distinction into section 2, while the value of tagging each guarantee was
   clearest where claims (freestanding support, layout contracts) outran
   observation (C3 study §2; Odin study §2; Hare study §2; Val study §2).

## 9. Sources and traceability

- [C3 study](13-c3-vs-c.md) — `documents/13-c3-vs-c.md` (inspect only).
- [Odin study](14-odin-vs-c.md) — `documents/14-odin-vs-c.md` (inspect only).
- [Hare study](15-hare-vs-c.md) — `documents/15-hare-vs-c.md` (inspect only).
- [Val study](16-val-vs-c.md) — `documents/16-val-vs-c.md` (inspect only).
- [Cake study](17-cake-vs-c.md) — `documents/17-cake-vs-c.md` (inspect only).
- [Survey](08-related-work.md) — `documents/08-related-work.md`; its Status
  section is updated by this task; the survey body is otherwise untouched.
- [Criteria](04-c-comparison-criteria.md) — `prompts/common/04-c-comparison-criteria.md`
  (authoritative; not modified).
- [Language doc](07-elseon-language.md) — `documents/07-elseon-language.md`;
  the kernel test and syntax-family wording used as the comparison standard.
- Task: `prompts/tasks/07-c-comparison-synthesis.md`; episode plan:
  `prompts/episodes/02-episode-plan.md` (episode 1-A).
