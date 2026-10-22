# Record: Adopt the shared rules

## Outcome

This project now pins the shared rules at `2026-10-22.5`. `rules.lock` holds the
version and a SHA-256 per vendored file, `scripts/rules-check.sh` verifies the
copy, and `tests/04-rules-pin.sh` runs it in the suite.

The adoption was `breaking` for this project: the contract gains a non-overridable
safety precedence level, file modification becomes authorization-based instead of
prohibition-based, and nine capability conventions now apply.

Conformance cleared in the same change: 105 validator findings across twelve task
files, four feature files, two stale rule files, and a missing `AGENTS.md`.

## Decisions

- **The twelve task files were conformed, not retired.** They are live planned
  work (`TODO.md`: episode 1-A study series, unchecked), so the modern task format
  was applied to each: operation lines in `TASK-DESCRIPTION`, a `TASK-FILES`
  table, `TASK-VERIFY`, and the closing `OUTPUT:` restatement. The transforms were
  applied by script so the twelve stay uniform; two tasks that reference a feature
  also gained `TASK-FEATURES` and `TASK-ACCEPTANCE`.
- **A local rule file moved out of `common/`.** `prompts/common/04-c-comparison-criteria.md`
  became `prompts/11-c-comparison-criteria.md`. Anything under `prompts/common/`
  must appear in the contract's shared registry, which a project-specific criteria
  document cannot, so the file was in a shared home while being local. Seven
  documents that cite it were updated.
- **Deleted `prompts/common/00-overview.md` and `01-requirements.md`** — stale
  boilerplate from an older generation, superseded by the contract and the
  universal rules.
- **Kept each feature's own requirements and gave them identifiers** rather than
  importing the skeleton's set: `SITE-BUILD-R001`–`R008`, `LANG-R001`–`R014`,
  `C-HEADER-R001`–`R005`, `LLVM-R001`–`R006`.
- **`PHASES.md` is declared** in `prompts/10-project.md`; it is a root file the
  shared list cannot know about.
- **The glossary states the DELTA term and points at contract section 6** instead
  of restating it.

## Verification

- `rules-check`: ok (v2026-10-22.5, 36 files, 0 deviations).
- `tests/09-prompt-contract.sh`: ok.
- `tests/10-prompt-validator.sh`: 54 rejected, 6 accepted.
- `tests/13-corpus-coverage.sh`: ok (15 checks, 54 rejection cases).
- `make test`: 11 of 11 pass.

## Behavioral evidence

**Not run.** The six `evals/` cases arrived with the adoption and none was handed
to a real agent, because scoring them needs a model and a person. The adoption is
mechanically verified and behaviorally unverified.

This project is live, so the gap is tracked where it will be seen: `TODO.md` now
opens with a blocking item to run the six cases before the next dispatch, naming
`02-scope-discipline` (authorization replaced prohibition) and
`05-acceptance-remains-human` as the most exposed.

## Cost finding

`make test` took about ten minutes, and the cause is the shared adversarial
corpus, not this project: `tests/10-prompt-validator.sh` copies the working tree
once per case (54 times), and this tree is 3.9 GB because `sources/` holds ignored
research evidence. That is roughly 210 GB of copying per run.

The fix belongs in the shared rules: the corpus should build each fixture from
`git ls-files` rather than from the working tree, because the validator only ever
reads tracked files. Proposed as the next version.

## Commits

- `44c12ce` — adopt the shared rules at v2026-10-22.5, including this record.
