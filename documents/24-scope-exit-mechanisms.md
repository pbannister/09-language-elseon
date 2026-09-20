# Running code at scope exit: four non-C++ mechanisms

**Provenance:** produced by a research subagent; reviewed by the maintainer agent.
**Relationship to other documents:** this is a companion detail file.
The same four mechanisms are summarized in `documents/23-constructor-destructor-variants.md`, which also carries the design's per-site rulings; this file records the finer clause-level detail (grammar, exact constraint paragraphs, runtime entry points, and the confidence list).
Where the two disagree, `documents/23-constructor-destructor-variants.md` is authoritative, because it reflects the later verification of the `defer` design change from N2895 to N3734.

## 1. ISO C `defer` — ISO/IEC TS 25755

Normative text: draft TS **N3734**, *Programming Languages — C — defer, a mechanism for general purpose, lexical scope-based undo* ([N3734](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n3734.pdf)). N2895 is the earlier paper, which made `defer` a lambda-based *declaration* and left inner-block placement implementation-defined ([N2895](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2895.htm)).

- **Grammar/placement.** `defer-statement: _Defer deferred-block`; `deferred-block: unlabeled-statement`; `defer-statement` is added to `unlabeled-statement` ([N3734 §6.3](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n3734.pdf)). It is a *statement*, legal anywhere an unlabeled statement is (any block, or the body of `if`/`for`/`while`/`switch`); its block may be one statement or a compound statement.
- **When it runs.** On reaching D, S is not run immediately. For D's scope, S runs on termination of the enclosing block E and/or D's scope (reaching the end), or on any exit via `return`, `goto`, `break`, or `continue`; it runs just before leaving E, with return expressions and conversions computed first ([N3734 §6.4 p4, EXAMPLE 2](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n3734.pdf)).
- **`longjmp`/termination.** If a non-local jump leaves D's scope before S runs, S is not executed; unwinding on `longjmp` is implementation choice (NOTE 2). Termination via `_Noreturn`/`exit`, or SIGABRT/SIGINT/SIGTERM, runs no S unless the implementation specifies ([N3734 §6.4 p6, p10, EXAMPLE 3](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n3734.pdf)).
- **No implicit action.** Only the programmer-written deferred statement runs; "execution of a defer statement only ensures that S is run on any exit from that scope" ([N3734 §6.4 p7 NOTE 1](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n3734.pdf)).
- **Ordering.** Reverse order of appearance; nested defers recursively reverse-ordered within their own deferred block ([§6.4 p5, EXAMPLE 5](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n3734.pdf)).
- **Constraints.** `goto`/`switch` must not jump into D or D's scope; `return`/`break`/`continue`/`goto` must not exit S ([§6.4 p3](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n3734.pdf)).
- **C-only.** Normative reference is ISO/IEC 9899:2024; new keyword `_Defer` (§6.2); `<stddefer.h>` defines `defer` and `__STDC_VERSION_STDDEFER_H__` (202602L) (§7.2); `__STDC_DEFER_TS25755__` is 2 if `defer` exists, else 1 (§6.5); returns from `main` and `thrd_create` run in-scope defers first (§5.2, §7.1).

## 2. GCC/Clang `__attribute__((cleanup(fn)))`

- **Semantics/signature.** Runs `fn` when the variable goes out of scope; `fn` takes one argument, "a pointer to a type compatible with the variable"; return value ignored ([GCC Common Variable Attributes](https://gcc.gnu.org/onlinedocs/gcc/Common-Variable-Attributes.html), [GCC cleanup entry](https://gcc.gnu.org/onlinedocs/gcc/Common-Attributes.html#index-cleanup)). Clang: run "when a local variable goes out of scope", function's parameter is "a pointer to the type with the attribute" ([Clang AttributeReference](https://clang.llvm.org/docs/AttributeReference.html#cleanup)).
- **Which variables.** GCC: only `auto` function-scope variables; not parameters, not static storage duration. Clang's own example uses an inner block (`int y __attribute__((cleanup(bar)));`), so [N2895](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2895.htm)'s claim that inner blocks are impossible is inaccurate.
- **Ordering.** Same scope: reverse order of definition ([GCC](https://gcc.gnu.org/onlinedocs/gcc/Common-Attributes.html#index-cleanup)).
- **Exits.** Block exit, plus stack unwinding during exceptions with `-fexceptions`; "undefined what happens if cleanup_function does not return normally" ([GCC](https://gcc.gnu.org/onlinedocs/gcc/Common-Attributes.html#index-cleanup)). `break`/`continue`/`goto`/`longjmp` are not addressed.

## 3. Objective-C ARC (and MRR)

- **Synthetic.** "ARC works by adding code at compile time"; it "automatically inserts appropriate memory management calls for you at compile time" ([Apple ARC notes](https://developer.apple.com/library/archive/releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html)).
- **Qualifiers.** `__strong` (default), `__weak`, `__unsafe_unretained`, `__autoreleasing` ([ARC spec](https://clang.llvm.org/docs/AutomaticReferenceCounting.html)). `__strong` assignment retains the new pointee, stores it, then releases the old; `__weak` assignment is atomic and nil-ing; `__unsafe_unretained` is primitive; `__autoreleasing` retains, autoreleases, stores. Reading `__weak` retains and releases at end of the full-expression (same URL).
- **Scope exit.** Destruction "occurs when an object's lifetime ends... semantically equivalent to assigning a null pointer to the object" (same URL) — for `__strong`, the release in that assignment sequence.
- **Runtime.** `void objc_storeStrong(id *object, id value)` performs the full `__strong` assignment sequence; `void objc_release(id)` releases exactly like `release` ([ARC spec, Runtime support functions](https://clang.llvm.org/docs/AutomaticReferenceCounting.html)).
- **Precise lifetime.** Automatic `__strong` locals default to *imprecise* lifetime; `objc_precise_lifetime` forces retention for the full formal lifetime; otherwise ARC may release once the value is unused ([ARC spec, "Precise lifetime semantics", "Object liveness"](https://clang.llvm.org/docs/AutomaticReferenceCounting.html)).
- **MRR.** Explicit: "You own any object you create... you must relinquish ownership... by sending it a release message or an autorelease message" ([Apple Memory Management Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/mmRules.html)). No scope-exit insertion.

## 4. Cforall (C∀)

- Constructors are `?{}`, destructors `^?{}`; "C∀ adds destructors that are called when a variable is deallocated (variable goes out of scope or object is deleted)" ([C∀ User Manual §25, Fig. 12](https://cforall.uwaterloo.ca/doc/user.pdf)). Constructors run implicitly at declaration (`Widget foo{};`, `Widget bar{23,2.45};`); both are also explicitly callable (`?{}(baz,24,0.91)`, `^?{}(bar)`); `x{5};`/`^x{};` appear in ([C∀ Features](https://cforall.uwaterloo.ca/features)).
- Copy/temporaries: copy constructors exist (`void ?{}(VLA &, VLA)`; `VLA z = y;` copies) and the "Object" kind has "implicitly generated default/copy constructors, assignment, and destructor (similar to C++)" ([C∀ Features](https://cforall.uwaterloo.ca/features)); temporaries "copy from the references" and the compiler "implicitly creates the necessary temporary (copying the argument)" ([User Manual §12.1](https://cforall.uwaterloo.ca/doc/user.pdf)).
- Limits: implicit conversions remain and are costed in overload resolution ([User Manual §26](https://cforall.uwaterloo.ca/doc/user.pdf)); documented restrictions are narrower — "no implicit conversions are applied to assertion arguments" ([§20.10](https://cforall.uwaterloo.ca/doc/user.pdf)) and implicit `void*`⇄`T*` is removed ([Appendix, change 8](https://cforall.uwaterloo.ca/doc/user.pdf)).

## Confidence / unverified

- N3734 is marked DRAFT; TS wording may change before publication.
- `cleanup` under `break`/`continue`/`goto`/`longjmp`: **UNVERIFIED** (not in GCC/Clang docs).
- Whether Clang rejects `cleanup` on static-storage variables (GCC does): **UNVERIFIED**.
- `_Defer`/`<stddefer.h>` in freestanding C: not addressed in N3734 → **UNVERIFIED**.
- C∀: `refrat.pdf` and the trac-hosted ctor/dtor thesis chapter returned 404; claims rest on `user.pdf` and the features page. A general C∀ "no implicit conversions" rule: **UNVERIFIED** (evidence indicates implicit conversions exist).
- C++ precedent (optional): `explicit` restricts implicit conversion — explicit constructors work only in direct-initialization/casts ([C++ draft [class.conv.ctor]](https://eel.is/c++draft/class.conv.ctor)).
