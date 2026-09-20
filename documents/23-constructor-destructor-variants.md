# C++ constructor/destructor invocation inventory, overt vs implicit

**Provenance:** produced by a research subagent and reviewed against primary sources by the maintainer agent.
It is the per-invocation-site ruling input for the admissibility boundary in `documents/22-fork-or-extend-decision.md` §7.

Scope: every site in C++ where a constructor or destructor runs, classified as **OVERT**
(visible at the declaration, or an explicit call the programmer wrote) or **IMPLICIT**
(invoked by a rule that the source text does not spell out). Normative citations are to
the working draft at [eel.is/c++draft](https://eel.is/c++draft/) (clause names are stable
across C++20/23/26 drafts); cppreference is used only as a secondary restatement.

Two governing rules set the frame.

- A destructor for a class type is **implicitly invoked** for static storage duration at
  program termination, thread storage duration at thread exit, automatic storage duration
  when the block exits, and for a temporary when its lifetime ends; also via `delete`
  ([\[class.dtor\]/14](https://eel.is/c++draft/class.dtor)). A destructor "can also be
  invoked explicitly", and explicit calls use `~` with a qualified name
  ([\[class.dtor\]/16](https://eel.is/c++draft/class.dtor)).
- Automatic variables with side-effecting initialization or destruction **may not be
  destroyed early or eliminated** as an optimization, even if unused; only copy/move
  elision is excepted ([\[basic.stc.auto\]/2](https://eel.is/c++draft/basic.stc.auto)).
  This is the single most important rule for the design question (see "Unused variables", below).

## Table 1 — Constructors

| Invocation site | Overt or Implicit | Trigger rule | Can it be statically removed by design? |
| --- | --- | --- | --- |
| `T v(args);` / `T v{args};` | Overt | Direct-initialization: constructors enumerated, best chosen by overload resolution, selected constructor called with the arguments ([\[dcl.init.general\]/14–15.6.2](https://eel.is/c++draft/dcl.init.general)) | No, if it has side effects ([\[basic.stc.auto\]/2](https://eel.is/c++draft/basic.stc.auto)). Only copy/move of a class object may be elided. |
| `T v = other;` (same type) | Overt declaration; the copy/move is **implicit except when elided** | Copy-initialization may invoke the move constructor ([\[dcl.init.general\]/13](https://eel.is/c++draft/dcl.init.general)). It is elided whenever the initializer is a prvalue of the same type (mandatory since C++17: the prvalue *is* the object) and permitted for same-type objects under [\[class.copy.elision\]/1](https://eel.is/c++draft/class.copy.elision) | Yes in the sense that elision is always allowed and mandatory for prvalues; no when the source is a named lvalue and the implementation chooses to copy. |
| By-value function parameter | Overt argument, **implicit constructor** | Each parameter is initialized with its corresponding argument ([\[expr.call\]/7](https://eel.is/c++draft/expr.call)); a class-type argument is a user-defined conversion sequence ([\[over.ics.user\]/1](https://eel.is/c++draft/over.best.ics)) | No. Cannot be elided except for the conceptual parameter-copy cases ([\[class.copy.elision\]/1.3](https://eel.is/c++draft/class.copy.elision)). |
| By-value return | Overt `return`; the copy/move is **implicit** | Result object initialized from the operand ([\[stmt.return\]](https://eel.is/c++draft/stmt.return)); NRVO permitted for a named local, URVO mandatory for a prvalue ([\[class.copy.elision\]/1.1](https://eel.is/c++draft/class.copy.elision)) | Conditional: permitted (and for prvalues mandatory) to elide; otherwise a move/copy runs. |
| `throw e;` / `catch (T e)` | Overt throw; the copy is **implicit** | Exception object copy-initialized from the operand, and the handler parameter copy-initialized from the exception object ([\[except.throw\]/5](https://eel.is/c++draft/except.throw), [\[except.handle\]](https://eel.is/c++draft/except.handle)); both may be elided ([\[class.copy.elision\]/1.2, 1.4](https://eel.is/c++draft/class.copy.elision)) | Elision is permitted; otherwise the copy/move runs. |
| Container insertion (`push_back`, `insert`, `emplace_back`) | Overt call, **implicit constructor of `T`** | Element constructed from the argument (copy/move for `push_back`, direct-initialization for `emplace`) (container requirements: `X u(rv)` is equivalent to `X u = std::move(rv)`, [\[container.requirements\]](https://eel.is/c++draft/container.requirements), [\[allocator.requirements.general\]](https://eel.is/c++draft/allocator.requirements.general)) | No: the element is constructed in container storage the caller never named. This is the canonical "far from the source" site. |
| `std::move(x)` passed to a by-value or `T&&` parameter | Overt cast, **implicit move constructor** | `std::move` is a cast to `T&&`; the destination is initialized by the move constructor via overload resolution ([\[class.copy.ctor\]/2](https://eel.is/c++draft/class.copy.ctor)) | No (the move executes), unless elided as above. |
| `T v;` (no initializer) | Overt declaration, **implicit default constructor** | Object is default-initialized; applicable constructors enumerated and the best for `()` is called ([\[dcl.init.general\]/6](https://eel.is/c++draft/dcl.init.general)); "A default constructor is implicitly invoked ... when no initializer is specified" ([\[class.default.ctor\]/5](https://eel.is/c++draft/class.default.ctor)) | No if non-trivial/side-effecting ([\[basic.stc.auto\]/2](https://eel.is/c++draft/basic.stc.auto)). |
| `new T` | Overt `new`, **implicit default constructor** | New-initializer absent ⇒ object default-initialized ([\[expr.new\]](https://eel.is/c++draft/expr.new), [\[dcl.init.general\]/6](https://eel.is/c++draft/dcl.init.general)); `new T()` value-initializes ([\[dcl.init.general\]/8](https://eel.is/c++draft/dcl.init.general)) | No (constructor side effects are observable). |
| `T arr[10];` | Overt declaration, **implicit constructors per element** | If no initializer, each element is default-initialized ([\[dcl.init.general\]/6.2](https://eel.is/c++draft/dcl.init.general)); an array default-constructs once per element, and temporaries in default arguments of the constructor are destroyed before the next element ([\[class.temporary\]/5](https://eel.is/c++draft/class.temporary)) | No. |
| Base/member subobject construction inside a constructor | Explicit only if named in the *ctor-initializer*; otherwise **implicit** | Non-delegating constructor: virtual bases, then direct bases in declaration order, then members in declaration order; any subobject not designated by a *mem-initializer-id* is default-initialized or initialized from its default member initializer ([\[class.base.init\]/9, 15](https://eel.is/c++draft/class.base.init)). Delegating constructors call the target constructor ([\[class.base.init\]/6](https://eel.is/c++draft/class.base.init)) | No. Note: no inheritance planned, but member subobjects (struct fields) raise the same implicit-call pattern. |
| `T{}` | Overt | List-initialization; empty list and a class with a default constructor ⇒ value-initialized ([\[dcl.init.list\]/3.5](https://eel.is/c++draft/dcl.init.list)) | Same as above. |
| Aggregate `T v = {a,b}` / `T v{a,b}` | Overt; **no constructor of `T` runs** | Aggregate elements are copy-initialized from the clauses ([\[dcl.init.aggr\]/5.3](https://eel.is/c++draft/dcl.init.aggr)); an aggregate is defined precisely by the absence of user-declared/inherited constructors, private/protected members/bases, and virtual functions/bases ([\[dcl.init.aggr\]/1](https://eel.is/c++draft/dcl.init.aggr)) | Yes, fully static — this is the "C-like" subset. |
| `T v(a,b)` where `T` is an aggregate (C++20) | Overt | Parenthesized aggregate initializer: if no constructor is viable, elements are copy-initialized from the expression list ([\[dcl.init.general\]/15.6.2.2](https://eel.is/c++draft/dcl.init.general)); proposed in [P0960R3](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2019/p0960r3.html) | Yes for the aggregate itself; per-element conversions may still invoke constructors. |
| Braced list selecting `initializer_list<T>` ctor | Overt | An initializer-list constructor is one whose first parameter is `std::initializer_list<E>` ([\[dcl.init.list\]/2](https://eel.is/c++draft/dcl.init.list)); it is favored over other constructors ([\[over.match.list\]](https://eel.is/c++draft/over.match.list)); the backing array is materialized and its elements copy-initialized ([\[dcl.init.list\]/5–6](https://eel.is/c++draft/dcl.init.list)) | No. Note the **hidden backing array**: an invisible temporary array of `N const E` with reference-like lifetime extension. |
| Implicit conversion `T(U)` (non-`explicit`) | **Implicit** — the classic hidden call | At assignment, argument passing, and `return`, copy-initialization performs user-defined conversion via the converting constructor ([\[dcl.init.general\]/15.6.3](https://eel.is/c++draft/dcl.init.general), [\[over.ics.user\]/1](https://eel.is/c++draft/over.best.ics)); forbidden as a second user-defined conversion ([\[over.best.ics\]/4](https://eel.is/c++draft/over.best.ics)) | N/A for a design that forbids it: this is exactly the site to ban. `explicit` already restricts it ([\[dcl.fct.spec\]](https://eel.is/c++draft/dcl.fct.spec)). |

## Table 2 — Destructors

| Invocation site | Overt or Implicit | Trigger rule | Can it be statically removed by design? |
| --- | --- | --- | --- |
| End of an automatic variable's scope | Overt in the sense that the declaration is visible; invocation is **implicit** | On each transfer of control from P to Q inside a function, block variables active at P and not at Q are destroyed in reverse order of construction ([\[stmt.dcl\]/2](https://eel.is/c++draft/stmt.dcl)); also [\[class.dtor\]/14.3](https://eel.is/c++draft/class.dtor) | No ([\[basic.stc.auto\]/2](https://eel.is/c++draft/basic.stc.auto)). This is the site the design wants to keep as "overt like C". |
| End of a temporary's full-expression | **Implicit** | Temporaries are destroyed as the last step in evaluating the full-expression that lexically contains their creation, "even if that evaluation ends in throwing an exception" ([\[class.temporary\]/4](https://eel.is/c++draft/class.temporary), [\[class.dtor\]/14.4](https://eel.is/c++draft/class.dtor)) | No, unless the temporary itself is removed (elision/lifetime extension). |
| Stack unwinding on exception | **Implicit** | Each automatic object constructed since the `try` block was entered and not yet destroyed is destroyed in reverse order of completion of construction ([\[except.ctor\]/2](https://eel.is/c++draft/except.ctor)) | No. |
| `delete p;` / `delete[] p;` | Overt expression; destructor invocation **implicit** | Evaluating `delete` invokes the destructor for the object or, for arrays, the elements in order of decreasing address ([\[expr.delete\]/5](https://eel.is/c++draft/expr.delete), [\[class.dtor\]/14](https://eel.is/c++draft/class.dtor)); null pointer ⇒ no destructor ([\[class.dtor\]/16 note 7](https://eel.is/c++draft/class.dtor)) | No. |
| Container/smart-pointer destruction of elements | **Implicit and remote** | `unique_ptr`'s destructor destroys the owned object via `get_deleter()(get())` unless null ([cppreference: `~unique_ptr`](https://en.cppreference.com/w/cpp/memory/unique_ptr/~unique_ptr), normative requirements in [\[unique.ptr\]](https://eel.is/c++draft/unique.ptr)); `vector`'s destructor destroys its elements ([\[vector\]](https://eel.is/c++draft/vector)); allocator requirement `a.destroy(c)` destroys the object at `c` ([\[allocator.requirements.general\]](https://eel.is/c++draft/allocator.requirements.general)) | No, and the site is textually far from the element's construction. |
| Static / thread-local objects at exit / thread exit | **Implicit** | Static storage duration at program termination, thread storage duration at thread exit ([\[class.dtor\]/14.1–14.2](https://eel.is/c++draft/class.dtor)); destroyed as part of `std::exit`, which `main` returning invokes ([\[basic.start.term\]/1](https://eel.is/c++draft/basic.start.term)); `std::abort` runs none ([\[basic.start.term\]/8](https://eel.is/c++draft/basic.start.term)) | No. |
| Ordering of destruction | n/a | Reverse of the completion of construction, for bases/members ([\[class.dtor\]/13.3](https://eel.is/c++draft/class.dtor)), for arrays ([\[class.dtor\]/13.5](https://eel.is/c++draft/class.dtor)), for locals ([\[stmt.dcl\]/2](https://eel.is/c++draft/stmt.dcl)), for temporaries ([\[class.temporary\]/11](https://eel.is/c++draft/class.temporary)), and for statics by reverse deemed construction ([\[basic.start.term\]/4](https://eel.is/c++draft/basic.start.term)); destruction interleaves with autos/temporaries by construction order ([\[class.temporary\]/11](https://eel.is/c++draft/class.temporary)) | n/a. |
| Constructor throws (partial construction) | **Implicit** | If initialization of an object (other than by delegating constructor) is terminated by an exception, the destructor runs for each subobject whose initialization completed, in reverse order of completion of construction ([\[except.ctor\]/3](https://eel.is/c++draft/except.ctor)); delegating constructor body throwing invokes the object's destructor ([\[except.ctor\]/4](https://eel.is/c++draft/except.ctor)) | No. |
| Explicit destructor call `p->~T();` | **Overt** | Explicit destructor call with `~` and a qualified/type name ([\[class.dtor\]/16](https://eel.is/c++draft/class.dtor)); needed for placement-new objects; also valid on scalar type names as a pseudo-destructor ([\[class.dtor\]/19](https://eel.is/c++draft/class.dtor)) | Yes — an ordinary call the programmer wrote. |

## C++ subtleties

**Temporaries.** A temporary is created when a prvalue is converted to an xvalue and when
the implementation needs one to pass or return an object
([\[class.temporary\]/1](https://eel.is/c++draft/class.temporary)); materialization is
delayed and happens on reference binding to a prvalue, member access or member call on a
class prvalue, subscripting an array prvalue, `initializer_list<T>` initialization, and a
discarded-value non-`void` prvalue ([\[class.temporary\]/2](https://eel.is/c++draft/class.temporary)).
The standard's own example: `X b = f(X(2));` constructs `X(2)` in `f`'s argument storage
and the result in `b`, whereas `a = f(a)` materializes a temporary so `operator=`'s
reference parameter can bind. Since C++17 a prvalue is not materialized until needed, so
copy-looking initialization need not invoke any copy constructor
([cppreference: Copy elision, "Prvalue semantics"](https://en.cppreference.com/w/cpp/language/copy_elision)).

**Lifetime extension.** A temporary bound to a reference by a temporary materialization
conversion (parentheses, subscripting, member access, pointer-to-member, non-user-defined
casts, glvalue conditional/comma) persists for the reference's lifetime, recursively
through reference members ([\[class.temporary\]/6](https://eel.is/c++draft/class.temporary)).
The exceptions are where hidden destruction stays hidden: a temporary bound to a
**reference parameter** in a call, to a **reference element of an aggregate initialized
from a parenthesized expression-list**, or in a **new-initializer** dies at the end of the
full-expression ([\[class.temporary\]/6.10–6.12](https://eel.is/c++draft/class.temporary)).
So for `struct A { int a; int&& r; };`, `A a1{1, f()}` extends and `A a2(1, f())` dangles
([P0960R3](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2019/p0960r3.html)).

**Elision.** Copy elision is permitted for NRVO, a throw operand, a coroutine parameter
copy, and a handler parameter; source and target then become two ways of naming one object
([\[class.copy.elision\]/1](https://eel.is/c++draft/class.copy.elision)). It is **never**
performed in a constant-expression context or constant initialization. Because it is
optional outside the mandatory prvalue cases, programs relying on copy/move side effects
are "not portable" ([cppreference: Copy elision, Notes](https://en.cppreference.com/w/cpp/language/copy_elision)).

**Unwinding.** Destruction during unwinding is mandatory and ordered; a destructor invoked
by unwinding that exits with an exception calls `std::terminate`
([\[except.throw\]/9 Note 7](https://eel.is/c++draft/except.throw)).

**Unused variables and optimizer removal.** `[[maybe_unused]]` only suppresses a warning;
it has no code-generation meaning
([cppreference: maybe_unused](https://en.cppreference.com/w/cpp/language/attributes/maybe_unused)).
Under the as-if rule only *observable behavior* must be preserved
([\[intro.abstract\]](https://eel.is/c++draft/intro.abstract)), and copy elision is an
express exception that may remove copy/move calls and matching temporary destructors even
with side effects ([\[class.copy.elision\]/1](https://eel.is/c++draft/class.copy.elision)).
But an unused **automatic** variable with side-effecting initialization or destructor is
protected: "an implementation shall not destroy it before the end of its block nor
eliminate it as an optimization, even if it appears to be unused", except for class-object
copy/move elision ([\[basic.stc.auto\]/2](https://eel.is/c++draft/basic.stc.auto)).
So **the compiler may not remove an overt, side-effecting ctor/dtor pair for an automatic
variable**; it may only elide the copy/move itself. Trivial or provably side-effect-free
ctors/dtors leave nothing observable, so the storage may vanish. GCC's `-Wunused-variable`
(`-Wall`) is purely diagnostic ([GCC Warning Options](https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html)),
and `cleanup` is not removable either because removal changes semantics
([N2895](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2895.htm)).

## Non-C++ precedents

**ISO C `defer` — ISO/IEC TS 25755.** The normative text is the draft TS N3734,
"Programming Languages — C — defer, a mechanism for general purpose, lexical scope-based
undo" ([N3734](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n3734.pdf)); the TS is
registered as ISO/IEC TS 25755 ([ISO project 91402](https://bds-bg.org/en/project/show/iso:proj:91402)),
and GCC patches implement it "as per TS 25755"
([gcc-patches v7](https://gcc.gnu.org/pipermail/gcc-patches/2026-July/723240.html)). Note
the design changed between the earlier paper [N2895](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2895.htm)
(lambda-based *declaration*, inner blocks implementation-defined) and the TS
(`_Defer deferred-block` as an unlabeled **statement**, legal anywhere an unlabeled
statement is; N3734 §6.3). The deferred block `S` is not run when reached; during `D`'s
scope it runs on termination of the enclosing block `E` and/or `D`'s scope, or on any exit
via `return`, `goto`, `break`, or `continue`, "just before leaving the enclosing block",
with return expressions computed first (N3734 §6.4 p4). Multiple defers run in reverse
order of appearance, recursively for nested defers (§6.4 p5). Jumps by `goto`/`switch`
into a defer or its scope are constraint violations, and `return`/`break`/`continue`/`goto`
shall not exit `S` (§6.4 p3). If a non-local jump leaves `D`'s scope before `S` runs, `S`
is **not** executed; `longjmp`/`setjmp` unwinding is implementation choice (§6.4 p6,
p11); `_Noreturn` calls and `SIGABRT`/`SIGINT`/`SIGTERM` run no `S` unless the
implementation specifies otherwise (§6.4 p10). Crucially, `S` is only the statement the
programmer wrote — N3734 §6.4 p7: "execution of a defer statement only ensures that `S` is
run on any exit from that scope" — so there is no implicit copy, conversion, or temporary.
The keyword is `_Defer`; `<stddefer.h>` defines `defer` and
`__STDC_VERSION_STDDEFER_H__` as `202602L`, and `__STDC_DEFER_TS25755__` is `2` when
`defer` is provided (§6.2, §6.5, §7.2).

**GCC/Clang `__attribute__((cleanup(f)))`.** Applies to automatic variables with block
scope (GCC excludes parameters and static-storage variables); `f` must take one pointer
parameter compatible with the variable and its return value is ignored. Multiple such
variables run their cleanup functions at scope exit **in reverse order of definition**.
With `-fexceptions` the function also runs during stack unwinding, and "it is undefined
what happens if cleanup_function does not return normally"
([GCC Common Attributes](https://gcc.gnu.org/onlinedocs/gcc/Common-Attributes.html),
[Clang AttributeReference](https://clang.llvm.org/docs/AttributeReference.html)). The
invocation rule is exactly "scope exit of the named variable", so the only overt surface
is the declaration; there is still a hidden call at block exit, but there is no hidden
copy, conversion, or temporary. N2895 documents the same feature and notes it cannot be
adopted as a standard attribute because removing it changes program semantics
([N2895](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n2895.htm)); N2895's claim that
inner blocks are impossible is nevertheless too strong — Clang's own example uses one
([Clang AttributeReference](https://clang.llvm.org/docs/AttributeReference.html)).

**Objective-C ARC.** ARC "works by adding code at compile time" — it "automatically
inserts appropriate memory management calls" the source does not show
([Apple, Transitioning to ARC](https://developer.apple.com/library/archive/releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html)).
Assignment to a `__strong` object retains the new value, stores it, and releases the old
one (in the runtime, `objc_storeStrong`); `__weak` assignment is atomic and nil-ing and a
`__weak` read retains and releases within the full-expression; `__autoreleasing` retains,
autoreleases, stores; initialization stores a null pointer and then assigns; destruction
"is semantically equivalent to assigning a null pointer to the object"
([Clang ARC spec, Semantics and runtime support](https://clang.llvm.org/docs/AutomaticReferenceCounting.html)).
Crucially, ARC explicitly makes local `__strong` variable lifetimes **imprecise** by
default: an object held in a normal `__strong` local may be released as soon as the value
is no longer used, and the `objc_precise_lifetime` attribute is required to force release
at the end of the variable's formal lifetime ([Clang ARC spec, "Precise lifetime
semantics" and "Object liveness"](https://clang.llvm.org/docs/AutomaticReferenceCounting.html)).
ARC is thus a counter-example for this design: its scope-exit action is not guaranteed and
is an optimizer-visible property, whereas the target design wants scope exit to be a solid
overt boundary. (Manual retain/release has no scope-exit insertion at all — ownership is
relinquished only by an explicit `release`/`autorelease`,
[Apple Memory Management Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/mmRules.html).)

**Cforall.** The Cforall user manual documents constructors as ordinary functions using
`?{}` (first parameter a reference to the object) and destructors using `^?{}`; a
destructor "is called when a variable is deallocated (variable goes out of scope or object
is deleted)", and both can also be called explicitly as `?{}( baz, 24, 0.91 );` and
`^?{}( bar );` ([Cforall User Manual, §25 "Constructors and Destructors"](https://cforall.uwaterloo.ca/doc/user.pdf)).
Cforall also documents copy constructors (`void ?{}(VLA &, VLA)`), "implicitly generated
default/copy constructors, assignment, and destructor (similar to C++)" for its `Object`
kind, and compiler-generated temporaries that "copy from the references"
([Cforall Features](https://cforall.uwaterloo.ca/features),
[User Manual §12.1](https://cforall.uwaterloo.ca/doc/user.pdf)). It therefore is **not**
an example of a language with scope-exit destruction but no hidden copies or temporaries;
it is closer to C++ with explicit `?{}`/`^?{}` spellings. Its documented restrictions are
narrower than that: implicit conversions remain and are costed in overload resolution
([§26](https://cforall.uwaterloo.ca/doc/user.pdf)), with only local carve-outs such as no
implicit conversions for assertion arguments ([§20.10](https://cforall.uwaterloo.ca/doc/user.pdf))
and removal of implicit `void*`↔`T*` conversion. Treat any general claim that Cforall
prohibits implicit invocation as **UNVERIFIED** (evidence indicates the opposite; the
linked `refrat.pdf` and the trac-hosted ctor/dtor thesis chapter have gone 404).

## Admissibility summary for a constructor-on-declaration / destructor-at-scope-exit design

Sites that are already fully static and need no hidden machinery: aggregate
initialization ([\[dcl.init.aggr\]](https://eel.is/c++draft/dcl.init.aggr)), explicit
`new`/`delete` ([\[expr.new\]](https://eel.is/c++draft/expr.new),
[\[expr.delete\]](https://eel.is/c++draft/expr.delete)), explicit destructor calls
([\[class.dtor\]/16](https://eel.is/c++draft/class.dtor)), direct-initialization
([\[dcl.init.general\]/14](https://eel.is/c++draft/dcl.init.general)), scope-exit
destruction of automatic variables ([\[stmt.dcl\]/2](https://eel.is/c++draft/stmt.dcl)),
and C `defer`/`cleanup` callbacks.

Sites that are inherently hidden and must be banned or made explicit if the design forbids
hidden invocation: implicit conversion constructors at assignment/argument/return
([\[dcl.init.general\]/15.6.3](https://eel.is/c++draft/dcl.init.general)); copy/move at
by-value parameters and returns; exception-object and handler copies; element construction
inside containers; temporaries materialized for reference binding and discarded-value
expressions ([\[class.temporary\]/2](https://eel.is/c++draft/class.temporary)); the
`initializer_list` backing array ([\[dcl.init.list\]/5](https://eel.is/c++draft/dcl.init.list));
destructors run by unwinding, by `delete`, by containers/smart pointers, and at
program/thread exit ([\[class.dtor\]/14](https://eel.is/c++draft/class.dtor)); and
destruction of already-constructed subobjects when a constructor throws
([\[except.ctor\]/3](https://eel.is/c++draft/except.ctor)).

## Rulings for this design

Applying the maintainer's decisions (base Clang; no vtables; explicit constructor,
destructor, and module syntax) and the overt/hidden distinction:

**Admitted.**

- Constructor at a declaration, and destructor at the end of that object's scope.
  Both boundaries are visible in the source, exactly as C's automatic storage duration
  makes a primitive's lifetime visible, and the destructor ordering is the reverse of
  construction.
- Explicit destructor calls, spelled as written calls.
- Explicit `new` and `delete`, with the destructor invocation being the direct,
  named consequence of the written `delete`.
- Aggregate-style initialization, which involves no constructor of the type at all.
- Manually written cleanup callbacks in the style of C `defer`/`cleanup`, as an
  alternative spelling that needs no object model.

**Excluded.**

- Implicit conversion constructors: the classic unnamed call at assignment, argument
  passing, and `return`.
- Copy and move construction, including at by-value parameters and by-value returns.
  In this model there are exactly two ways to bring an object into existence — a
  declaration and an explicit allocation — and neither is a copy. Copying is an
  ordinary, differently named operation that must be written out.
- Temporaries materialized by the compiler: reference binding, discarded-value class
  prvalues, and subscripting or member access on a class prvalue.
  Whether the language admits temporaries at all is an open question; if it does, they
  must be spelled rather than synthesized.
- Destructors driven by stack unwinding, which is moot while exceptions are excluded but
  must be re-ruled if they are ever admitted.
- Element or member construction the source does not name, including container element
  construction and per-element array construction.
- Destruction at program or thread exit for objects the programmer did not declare.
- Destruction of partially constructed objects.

**Guarantee the language should state normatively.**

C++ already has the rule this design needs, for its own subset: an automatic variable
with side-effecting initialization or destruction "shall not" be destroyed before the end
of its block nor eliminated as an optimization, even if unused
([\[basic.stc.auto\]/2](https://eel.is/c++draft/basic.stc.auto)).
Elseon's scope boundary should be a guarantee of the same strength rather than an
optimizer convenience, because a boundary the optimizer may move is not an overt
boundary.

The Objective-C ARC precedent is the warning here: ARC deliberately makes local
`__strong` lifetimes imprecise, releasing an object as soon as its value is no longer
used, and `objc_precise_lifetime` is required to force release at the end of the
variable's formal lifetime ([Clang ARC spec](https://clang.llvm.org/docs/AutomaticReferenceCounting.html)).
A design that wants scope exit to mean something must say so normatively, or the
optimizer will quietly take it away.
