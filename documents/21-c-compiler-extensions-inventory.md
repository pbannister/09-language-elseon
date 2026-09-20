# Prior Work on Extending/Modifying C Compilers — A Decision Inventory

**Report date:** 2026-09-16. **Purpose:** inform a decision about forking the LLVM/Clang C frontend to build a C-derived language.
Status labels: **shipping** (in a released mainstream compiler today), **active** (maintained fork/experiment), **dormant/abandoned**, **academic**, **in-progress** (patches pending). Items I could not confirm from a primary source are marked **(unverified)**.

**Provenance:** this inventory was produced by a research subagent and then reviewed against primary sources by the maintainer agent.
Two subagent findings were resolved during review and are corrected inline below: Clang `defer` support is **verified present** (it was marked unverified), and GCC's `defer` merge status remains unverified.
See `documents/22-fork-or-extend-decision.md` for the decision this inventory feeds.

---

## 1. C extensions that already exist in mainstream compilers (no fork needed)

- **`__attribute__((cleanup(fn)))`** — *What:* runs `fn(&var)` when an auto variable leaves scope; invalid on parameters/statics; multiple cleanups run in reverse definition order; runs during unwinding under `-fexceptions`; behavior undefined if `fn` doesn't return normally. *Mechanism:* attribute in the type system + cleanup codegen (no fork). *Status:* **shipping** in GCC and Clang. *Sources:* [GCC Common Attributes](https://gcc.gnu.org/onlinedocs/gcc/Common-Attributes.html), [Clang Attribute Reference](https://clang.llvm.org/docs/AttributeReference.html). The exact introduction versions (GCC 2003 / Clang 2009) are **(unverified)**; the attribute was already present in GCC 3.4.x per [this gcc-help thread](https://gcc.gnu.org/pipermail/gcc-help/2012-May/107640.html). WG14 paper [N3927 "Improved `__attribute__((cleanup))` Through `defer`"](https://www.rap.no/jtc1/sc22/wg14/www/docs/n3927.htm) explicitly treats `cleanup` as the de-facto RAII building block.

- **`__attribute__((constructor))` / `((destructor))`** — *What:* functions called before `main`, and after `main` returns or `exit()` is called; optional priority 101–65535 (0–100 reserved for the implementation). *Mechanism:* attribute lowered to `.init_array`/`.fini_array` (no fork). *Status:* **shipping** in GCC ([Common Attributes](https://gcc.gnu.org/onlinedocs/gcc/Common-Attributes.html)) and Clang ([Attribute Reference](https://clang.llvm.org/docs/AttributeReference.html)).

- **Blocks (closures)** — *What:* a new derived type `int (^)(char,float)`, block literals `^{...}` capturing automatic variables as const copies, a `__block` storage qualifier for mutable captured storage, `Block_copy`/`Block_release`, and Objective-C object semantics. *Mechanism:* Clang **language extension** (Lexer/Parser/Sema/CodeGen) plus a runtime library (`libBlocksRuntime`); requires `-fblocks`. *Status:* **shipping in Clang, non-standard, not in GCC.** Spec revisions date 2008–2009. *Sources:* [Clang Blocks language spec](https://clang.llvm.org/docs/BlockLanguageSpec.html), [Block ABI spec](https://clang.llvm.org/docs/Block-ABI-Apple.html). This is the strongest existing precedent that closure semantics can be bolted onto C inside the Clang tree.

- **Statement expressions, `__auto_type`, `typeof`** — *What:* `({ stmt; expr; })` as an expression, type inference without spelling the type, and type-of. *Mechanism:* parser/Sema extension. *Status:* **shipping** in GCC and Clang; `typeof` was standardized by C23. *Sources:* [GCC Statement Exprs](https://gcc.gnu.org/onlinedocs/gcc/Statement-Exprs.html), [Clang Language Extensions](https://clang.llvm.org/docs/LanguageExtensions.html). These are the cheap "sugar" hooks a C-derived language could lean on before forking.

- **C23 `[[attributes]]`** — *What:* standardized attribute syntax replacing `__attribute__` spellings, with `__has_c_attribute` probing. *Mechanism:* standardized syntax; plugins can register new attributes (see §6). *Status:* **shipping** in GCC and Clang (C23 mode). *Source:* WG14 [N2335 "Proposal for C2x: attributes"](http://www9.open-std.org/JTC1/SC22/WG14/www/docs/n2335.pdf).

- **Modules-like facilities** — *What:* Clang's `-fmodules` compiles headers into serialized module files driven by **module maps**, with `@import`/`#import`; C++20 modules are implemented separately. `#import` is a Clang/ObjC extension (include-once). *Mechanism:* build-level module cache, not a C language module system; serialized AST read/write. *Status:* **shipping** but *not* a C language feature — C still has no modules. *Sources:* [Clang Modules](https://clang.llvm.org/docs/Modules.html), [PCH/Modules Internals](https://clang.llvm.org/docs/PCHInternals.html), [Standard C++ Modules](https://clang.llvm.org/docs/StandardCPlusPlusModules.html).

- **ISO/DIS TS 25755 `defer`** — *What:* a `defer <statement>` that runs at scope exit; constraints forbid jumping over/into a defer block and `return`/`break`/`continue` out of one. *Mechanism:* compiler statement (parser + scope/jump-barrier bookkeeping), no runtime. *Status:* **in-progress.** The draft TS is WG14 [N3734](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n3734.pdf). GCC carries an active patch series by Anna (navi) Figueiredo Gomes: [v1 Aug 2025](https://gcc.gnu.org/pipermail/gcc-patches/2025-August/691603.html), [v6 Dec 2025](https://gcc.gnu.org/pipermail/gcc-patches/2025-December/702875.html), [v7 Jul 2026](https://gcc.gnu.org/pipermail/gcc-patches/2026-July/723243.html). It adds a `_Defer` keyword under GNU extensions, `<stddefer.h>` mapping `defer`→`_Defer`, and `__STDC_DEFER_TS25755__`. Whether it has been merged into a released GCC is **(unverified)**. A separate **slimcc-defer** implements defer in the slimcc tiny compiler ([repo](https://github.com/fuhsnn/slimcc-defer)).
**Clang support is verified shipping:** Clang's own command-line reference documents `-fdefer-ts` / `-fno-defer-ts` — "Enable support for the C `_Defer` Technical Specification" — in both the [22.1.0](https://releases.llvm.org/22.1.0/tools/clang/docs/ClangCommandLineReference.html) and [23.1.0](https://releases.llvm.org/23.1.0/tools/clang/docs/ClangCommandLineReference.html) releases.
Jens Gustedt, a WG14 participant, reports using Clang's implementation "available starting with clang-22," confirms TS 25755 is complete and in ISO publication, and offers a `cleanup`-based shim for GCC 9+ ([blog, 2026-02-15](https://web.archive.org/web/20260412105234/https://gustedt.wordpress.com/2026/02/15/defer-available-in-gcc-and-clang/)).
Microsoft's stance on TS 25755 is **(unverified)**; MSVC's idiom remains `__try`/`__finally`, and portable library-level `defer` macros are widely discussed ([antonz.org survey](https://antonz.org/defer-in-c/)).

---

## 2. Real forked-C / modified-C compilers

- **Fil-C** — *Added:* whole-program memory safety ("garbage in, memory safety out") for unmodified C/C++. *Mechanism:* **fork of clang 20.1.8**; a new LLVM pass `llvm::FilPizlonator` (bounds checks, flight/rest pointers, changed calling convention, GC safepoints) plus "surgical" Clang CodeGen/Driver/`BackendUtil.cpp` changes and select LLVM pass tweaks, with its own runtime `libpizlo` and rebuilt libc. *Status:* **active** — repo created 2024-02-16, default branch `deluge`, ~3.8k stars, last push 2026-09 ([GitHub API](https://api.github.com/repos/pizlonator/fil-c)), release 0.675 noted ([discussions](https://github.com/pizlonator/fil-c/discussions/145)). *Source:* [fil-c.org/compiler](https://fil-c.org/compiler). Notable because it proves a large semantic feature can be added with a *small, localized* frontend diff plus a backend pass.

- **Clacc** — *Added:* OpenACC support in Clang/LLVM (directives, clause checking, codegen to the OpenACC runtime). *Mechanism:* **DOE-funded Clang/LLVM fork**, hosted at [llvm-doe-org/llvm-project](https://github.com/llvm-doe-org/llvm-project) on branch `doe` (API: not archived, recently pushed 2026-09, but the org hosts several DOE projects). *Status:* **academic/ECP; Clacc-specific activity (unverified).** *Sources:* [ECP PROTEAS/Clacc report](https://www.exascaleproject.org/wp-content/uploads/2018/07/ECP-ST-CAR-Public-2018-07-01.pdf), [ECP annual report](https://www.exascaleproject.org/wp-content/uploads/2021/01/ECP-ST-CAR-v2.5.pdf).

- **OOP-added-to-C forks/dialects** — the shipping one is **Objective-C** (§3). Others:
  - **C∀ (Cforall)** — adds constructors/destructors, tuples, polymorphism, traits; **academic** (University of Waterloo), still has a live build farm. *Source:* [Cforall user manual](https://cforall.uwaterloo.ca/doc/user.pdf).
  - **The C Object System (COS)** — OOP via a **library/macro layer** (no fork); academic, [arXiv 1003.2547](https://ar5iv.labs.arxiv.org/html/1003.2547) (2010).
  - **Circle** — a C++-superset compiler adding many features (not C, but adjacent); active hobby/research project, [seanbaxter/circle](https://github.com/seanbaxter/circle).

- **Cyclone** — *Added:* a safe C dialect with fat pointers, region-based memory, tagged unions, exceptions, no pointer arithmetic holes. *Mechanism:* modified C front end (Cornell). *Status:* **abandoned** (~2006, project ended). *Source:* [cyclone.thelanguage.org](http://cyclone.thelanguage.org/), [Wikipedia](https://en.m.wikipedia.org/wiki/Cyclone_(programming_language)).

- **Checked C** — *Added:* bounds-checked pointer types (`_Ptr`, `_Array_ptr`, `_Nt_array_ptr`), checked scopes, `_Checked` blocks, and a bounds-checking runtime. *Mechanism:* **Clang/LLVM fork** (`checkedc-clang`/`checkedc-llvm`). *Status:* **dormant.** The repo has moved from `microsoft/*` to a community org `checkedc/checkedc`; GitHub API shows not archived, ~3.3k stars, but **last push 2024-10-07**. *Sources:* [GitHub API](https://api.github.com/repos/checkedc/checkedc), [checkedc-purdue fork](https://github.com/checkedc-purdue/checkedc-macro), [Tarditi 2023 "Next steps for Checked C"](https://pnwplse.org/slides/2023/David%20Tarditi.pdf).

- **Cilk / Cilk Plus** — *Added:* `_Cilk_spawn`, `_Cilk_sync`, `cilk_for`, hyperobjects (task parallelism in C). *Mechanism:* compiler keywords + runtime, in Intel's compiler and GCC. *Status:* **abandoned** — GCC removed Cilk Plus in **GCC 8** (2018) ([GCC 8 changes](https://gcc.sourceware.org/gcc-8/changes.html)); Intel has deprecated it. Clang never supported it. A cautionary tale: adding keywords to a mainstream C frontend is politically hard even with vendor backing.

- **Tiny C compilers as experimental bases** — **tcc** (Bellard; tiny, fast, not designed as an extensible host), **chibicc** (Rui Ueyama; ~9k-line educational C11 compiler, widely used as a teaching/experiment base), **slimcc** (fuhsnn; a chibicc fork with far broader C11/C23 coverage), **slimcc-defer** (adds `defer`). *Status:* active hobby/educational. These are attractive because the whole frontend is comprehensible, but you inherit no optimizer, sanitizers, debug-info quality, or ecosystem. Sources: [slimcc-defer](https://github.com/fuhsnn/slimcc-defer).

- **Forked Clang to add a module system or OOP:** the historical, successful example is **Objective-C** in Clang itself (§3); its predecessor was GCC's ObjC frontend. I found **no** widely-used independent fork of Clang that adds a *C* module system or classes as a separate product (unverified that none exists).

---

## 3. Objective-C: frontend vs runtime

- **Frontend work:** Clang parses `@interface`/`@implementation`/`@end`, method declarations, `@selector`, properties, `@protocol`, and message sends `[recv sel:arg]`; it performs type checking, method lookup, and ARC ownership analysis; it emits class/ivar/method metadata and calls into the runtime. This is implemented as a **distinct language mode layered on the C parser/Sema**, i.e. *Objective-C is a C extension*, not a separate grammar. Evidence: Clang's API exposes dedicated ObjC sema/codegen units — [SemaObjC.cpp](https://clang.llvm.org/doxygen/SemaObjC_8cpp.html), [SemaExprObjC.cpp](https://github.com/llvm/llvm-project/blob/main/clang/lib/Sema/SemaExprObjC.cpp), and runtime-abstraction classes in [`clang/lib/CodeGen/CGObjCRuntime.h`](https://github.com/llvm/llvm-project/blob/main/clang/lib/CodeGen/CGObjCRuntime.h).
- **Runtime work:** message dispatch (`objc_msgSend` and variants), class registration, metaclasses, reference counting entry points, associated objects, and weak references live in the **runtime library** (Apple's objc4 or GNU `libobjc2`), not in Clang. Clang's `CGObjCRuntime` subclasses (Apple/GNU) select which runtime ABI to target. ARC semantics are documented in Clang's [ARC spec](https://clang.llvm.org/docs/AutomaticReferenceCounting.html); literal syntax in [Objective-C Literals](https://clang.llvm.org/docs/ObjectiveCLiterals.html).
- **Lesson for the project:** a C-with-classes design can be split into (a) parsing/type-checking in the frontend and (b) dispatch/refcounting in a runtime library — and it is entirely feasible as a frontend-only addition, as ObjC demonstrates. Crucially, ObjC already ships in **upstream** Clang, so this category needs no fork.

---

## 4. Attempts to add classes/methods/constructors/RAII directly to C

- **Shipping:** Objective-C (classes/methods/`@interface`, §3); C++ (a C-derived language with classes/RAII, but a separate frontend).
- **Shipping attributes that emulate RAII:** `cleanup`, `constructor`/`destructor` (§1).
- **In progress:** `defer` TS 25755 (§1) — scope-exit cleanup, the RAII primitive without classes.
- **Academic:** C∀ (constructors/destructors, OOP traits), COS (library OOP). WG14 papers relevant to the space include **N2335** (attributes), **N3734** (defer TS), and **N2605 "Gilding"** on block/lambda capture semantics ([n2605](http://www9.open-std.org/JTC1/SC22/WG14/www/docs/n2605.pdf)). I found **no adopted WG14 proposal adding classes or methods to C**; specific OOP WG14 paper numbers are **(unverified)**.
- **Failures/dormant:** Cyclone (abandoned), Checked C (dormant since 2024-10), Cilk Plus (removed from GCC), and the general pattern that "C with classes" hobby forks rarely reach critical mass. The recurring reasons are (i) source-level incompatibility with existing C, (ii) the lack of a runtime/ABI story, and (iii) the political difficulty of changing the C frontend of a mainstream compiler.

---

## 5. Compiler-fork maintenance burden

- **Clang/LLVM has no stable C++ API.** Clang's own docs state LibClang is "a stable high level C interface"; LibTooling is explicitly *not* to be used when you "want a stable interface so you don't need to change your code when the AST API changes". *Source:* [Choosing the Right Interface for Your Application](https://clang.llvm.org/docs/Tooling.html). Any fork or plugin that touches internals rebases against a moving target every LLVM release.
- **The canonical downstream-fork talk:** Robinson & Edwards, *"Living Downstream Without Drowning"*, LLVM Developers' Meeting 2015 — Apple's account of the cost of maintaining a large downstream fork and the practices that keep it tractable ([slides PDF](https://llvm.org/devmtg/2015-10/slides/RobinsonEdwards-LivingDownstreamWithoutDrowning.pdf)); the body was not machine-readable to me, so specific recommendations are cited by title only.
- **How Fil-C manages it:** keep the diff minimal and localized — a backend pass plus small CodeGen/driver/`BackendUtil` changes, with an LLVM `DataLayout` method used to flag "Fil-C rules" mode — and track a single upstream base (clang 20.1.8) on branch `deluge`. *Source:* [fil-c.org/compiler](https://fil-c.org/compiler).
- **How Clacc/DOE manages it:** continuous integration of upstream Clang/LLVM, i.e. rebasing as an ongoing process rather than periodic merges ([ECP annual report](https://www.exascaleproject.org/wp-content/uploads/2021/01/ECP-ST-CAR-v2.5.pdf)).
- **Fedora's compiler policy:** the F35 "CompilerPolicy Change" (Ben Cotton, Jeff Law, Tom Stellard, Apr 2021) lets packagers choose GCC or Clang per package and was motivated by the cost of packagers carrying and negotiating compiler patches — but it is about **compiler selection, not forking**, and it does not discuss creating a fork. Any "Fedora fork policy" claim beyond that is **(unverified)**. *Source:* [F35 change thread](https://lists.fedoraproject.org/archives/list/devel-announce@lists.fedoraproject.org/thread/KD3CQOHBTGBW4BLL4E6CBKLQ4O66SEKW/).
- **Practical implication:** forking Clang means rebasing a multi-million-line C++ codebase with no stable internal API. The cheaper rungs on the ladder are: (1) attributes/pragmas and macros (no fork), (2) `#pragma clang attribute` / APINotes to attach existing attributes, (3) a plugin for analysis or AST rewriting (no new syntax), (4) a small standalone frontend (chibicc/slimcc/tcc) if the language diverges a lot.

---

## 6. Clang plugin/extension points and their documented limits

- **What plugins can do** (per [Clang Plugins](https://clang.llvm.org/docs/ClangPlugins.html)): run `FrontendAction`s over the AST (`PluginASTAction`, via `-fplugin`/`-load`/`-add-plugin`); register `PragmaHandler`s for `#pragma`; and register **new attributes** via `ParsedAttrInfo` (`Spellings`, `handleDeclAttribute`, `handleStmtAttribute`, `diagAppertainsToDecl/Stmt`, `diagLangOpts`, `existsInTarget`). Plugin attributes can attach an `Attr` to an existing `Decl`/`Stmt`.
- **What plugins cannot do:** they cannot add **new syntax**, **new types**, or **new statements**. The canonical confirmation is the cfe-dev thread ["extend C syntax in clang plug-in?"](https://lists.llvm.org/pipermail/cfe-dev/2014-November/039975.html), where the question "new built-in types and new statements… completely in a plugin?" is answered by Sean Silva: **"No. Currently clang's plugin functionality is very limited."** The plugin docs list *only* pragmas and attributes as syntax-level hooks; there are no Lexer/Parser hooks. A plugin can rewrite the existing AST into standard C, but it cannot parse syntax Clang's parser rejects.
- **Where the boundary really sits:** `ParsedAttrInfo` lets you name a new attribute with GNU/C23/`__declspec`/keyword spellings, but you cannot define a new `Type` or `Stmt` class from a plugin; attribute semantics must lower to existing nodes. `-clear-ast-before-backend` further constrains plugins that run after codegen. *Source:* [Clang Plugins](https://clang.llvm.org/docs/ClangPlugins.html).
- **Adjacent, fork-free knobs:** `#pragma clang attribute` applies existing attributes to many declarations without editing them; [API Notes](https://clang.llvm.org/docs/APINotes.html) annotate APIs without modifying headers.
- **How far plugins can go in practice:** Hal Finkel, *"Changing Everything With Clang Plugins"*, LLVM Developers' Meeting 2020 ([slides](https://llvm.org/devmtg/2020-09/slides/Finkel-Changing_Everything_With_Clang_Plugins.pdf)) — powerful for analysis/IR transformation, but still within the grammar Clang already accepts, and still tied to the unstable C++ API.
- **Bottom line:** adding new syntax or new types to C requires modifying Clang's Lexer/Parser/Sema/AST — i.e. a fork (or upstreaming). Plugins are an analysis/attribute mechanism, not a language-extension mechanism.

---

## Decision-relevant summary

| Goal | Cheapest viable mechanism | Fork needed? |
|---|---|---|
| RAII/scope cleanup | `cleanup` attribute; `defer` (GCC pending, slimcc done) | No |
| Closures | Clang Blocks (`-fblocks` + runtime) | No |
| Type inference, statement exprs, `typeof` | Existing GCC/Clang extensions; C23 `typeof` | No |
| Classes/methods/`@interface` | Objective-C, already upstream in Clang | No |
| New attribute vocabulary | `ParsedAttrInfo` plugin | No |
| Analysis / AST rewriting | Clang plugin or LibTooling | No |
| New **syntax** or **types** | Modify Lexer/Parser/Sema/AST → fork or upstream | Yes |
| Whole-language semantics change with small diff | Fil-C pattern: frontend tweaks + LLVM pass | Yes (localized) |

The two precedents most worth studying before committing to a fork are **Fil-C** (large semantics, small diff, active, clang-20-based) and **Checked C** (large language surface, fork, now dormant with no commits since 2024-10). The dominant cost is not writing the feature; it is the unbounded rebase against an upstream with no stable internal API (Clang's own [Tooling doc](https://clang.llvm.org/docs/Tooling.html)).
