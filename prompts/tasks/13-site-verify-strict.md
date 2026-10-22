# Task: Add a strict missing-page check for the site build

## TASK-DESCRIPTION
- Create: `scripts/site-verify.sh`

Create `scripts/site-verify.sh` as a POSIX shell script that checks the generated site.
For every `site.in/*.txt` input file, it must confirm that `site.out/<name>.html` exists, following the page mapping in `prompts/features/01-site-build.md`.
Report each missing page on standard output, one page path per line.
Accept optional input and output directory arguments; with no arguments, use `site.in/` and `site.out/` relative to the repository root, mirroring `scripts/site-build.sh`.
Without `--strict`, report missing pages and exit 0.
With `--strict`, exit nonzero when any generated page is missing.

## TASK-OUTPUT
- Report the created file and the verification result.
- End with the `VERIFICATION:` line.

## TASK-CONTEXT
- Feature requirements: `prompts/features/01-site-build.md`.
- Conventions: `prompts/03-conventions.md`.

## TASK-FILES

| Operation | Path |
|---|---|
| create | `scripts/site-verify.sh` |

## TASK-VERIFY
- Run: `make site && sh scripts/site-verify.sh --strict` from the repository root.
- Expected: exit status 0.
- Run: `rm -f site.out/index.html && sh scripts/site-verify.sh --strict` from the repository root.
- Expected: nonzero exit status and a line naming `site.out/index.html`.

## TASK-FEATURES
- `prompts/features/01-site-build.md`

## TASK-ACCEPTANCE
- `SITE-BUILD-R009`

OUTPUT: the created file and the verification result, ending with the `VERIFICATION:` line.
