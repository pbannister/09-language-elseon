# C-Comparison Study Criteria

The criteria for the episode 1-A study series: each candidate language is
studied and compared to C as the baseline. This file is the single place
the criteria live. Revise this file — not the five study tasks — when the
criteria change, and record each revision in the changelog at the end.

## Purpose

The aim of each study is to identify, for one candidate, what has been
tried before, what worked, and what did not work — so Elseon can borrow
what worked (PFE) and avoid what did not.

## Candidate

One candidate per study, from the current list: C3, Odin, Hare, Val, Cake.
The list is provisional: a study may recommend dropping a candidate in its
verdict, and the synthesis task collects the recommendations for the human
to decide.

## Comparison baseline

C is the baseline, not a strawman. For every dimension, state what C does,
what the candidate changes, and whether the change works in practice.

## Dimensions

### 1. Positioning

- What problem does the candidate claim to solve versus C, and for whom?
- Does it position as "improved C", "safer C", "C replacement", or
  something else?

### 2. Kernel-test adherence

Assess each guarantee separately and name the evidence:

- No garbage collection / no hidden runtime.
- No hidden allocations (explicit allocators).
- No hidden control flow.
- Deterministic memory layout (struct layout, padding, alignment).

### 3. Syntax family

- How close to C and JavaScript (Elseon's chosen family)?
- Does the surface add minimal cognitive friction for a C programmer?
- Which surface choices would Elseon reject (per the kernel test)?

### 4. C interoperability (PFE angle)

- FFI and C-compatible ABI.
- Reuse of C headers as first-class semantic modules (Elseon's PFE) —
  does the candidate offer an equivalent?
- Drop-in C compilation (e.g. `zig cc` style) if present.

### 5. Toolchain

- Backend (LLVM or other), build story, maturity, debugging,
  CI-verifiability.
- Kernel-adjacent constraint: no runtime dependency beyond what a kernel
  build accepts.

### 6. Ecosystem and adoption

- Real-world use, kernel-adjacent use, community activity, license,
  maintenance status.

### 7. What worked

- Ideas proven in practice, with evidence, that Elseon should consider
  borrowing.

### 8. What did not work

- Failures, dead ends, and pitfalls, with evidence, that Elseon should
  avoid.

### 9. Verdict for Elseon

- Classification: model / idea source / avoid, with reasons.
- Borrow list: concrete ideas with a one-line rationale each.
- Avoid list: concrete things with a one-line rationale each.

## Study-note structure

Every study task must produce its note with exactly these headings:

1. Positioning
2. Kernel-test adherence
3. Syntax family
4. C interoperability
5. Toolchain
6. Ecosystem and adoption
7. What worked
8. What did not work
9. Verdict for Elseon
10. Evidence

## Evidence rules

- Prefer primary sources: official documentation, the language reference,
  the specification, the repository.
- Cite sources inline (URLs) and list them in the Evidence section.
- Mark a claim "unverified" when no source supports it. Do not guess.
- Distinguish "stated by the project" from "observed in practice".
- When assessing "worked" or "did not work", record where the outcome was
  observed (community reports, benchmarks, real projects).

## Changelog

- 2026-09-01: initial criteria for the episode 1-A study series (five
  candidates: C3, Odin, Hare, Val, Cake).
