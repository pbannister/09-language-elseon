# Task: Inventory constructor and destructor invocation sites

## TASK-DESCRIPTION
Create `documents/23-constructor-destructor-variants.md`.
Enumerate every site in C++ where a constructor or destructor is
invoked, classify each as overt (visible at the declaration, or an
explicit call the programmer wrote) or hidden (invoked by a rule the
source text does not spell out), give the normative trigger rule, and
state whether the invocation can be removed by design.
Derive the per-site rulings for Elseon's design from the maintainer's
decisions: base Clang, no vtables, explicit constructor, destructor, and
module syntax, with invocation limited to a declaration and the end of
that object's scope.
Record the normative guarantee the language should state for scope exit,
using the automatic-storage-duration rule as the precedent.
Use the C++ working draft at eel.is/c++draft for normative citations,
and cover the non-C++ precedents: ISO C `defer` (TS 25755), the
`__attribute__((cleanup))` attribute, Objective-C ARC, and Cforall.
Do not modify any other file; this task creates only
`documents/23-constructor-destructor-variants.md`.

## TASK-OUTPUT
Provide only the complete content of
`documents/23-constructor-destructor-variants.md`.
No commentary.

## TASK-CONTEXT
This is the per-invocation-site ruling input for the admissibility
boundary in `documents/22-fork-or-extend-decision.md` §7.
The governing distinction is overt versus hidden invocation, not
explicit call versus automatic: scope-based construction and destruction
are overt because both boundaries are visible in the source.
The decisive normative precedent is the rule that an automatic variable
with side-effecting initialization or destruction shall not be destroyed
before the end of its block nor eliminated as an optimization
(`https://eel.is/c++draft/basic.stc.auto`).
Objective-C ARC is the counter-example: its local lifetimes are
imprecise by default, so scope exit is not a guaranteed boundary
(`https://clang.llvm.org/docs/AutomaticReferenceCounting.html`).

## TASK-FILES
- `documents/23-constructor-destructor-variants.md` — new
- `documents/22-fork-or-extend-decision.md` — existing (inspect only)
