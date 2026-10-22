# Feature: Site Build

## Purpose

The project contains a static-site input directory (`site.in/`) and a generated static-site output directory (`site.out/`).

The Site Build feature provides the script that converts `site.in/` into `site.out/`.

## Requirements

- `SITE-BUILD-R001` — `scripts/site-build.sh` must generate the static site in `site.out/` from the input in `site.in/`.
- `SITE-BUILD-R002` — Each `site.in/*.txt` input file must produce `site.out/<name>.html`.
- `SITE-BUILD-R003` — Generated output must be identified as generated.
- `SITE-BUILD-R004` — The script must accept optional input and output directory arguments.
- `SITE-BUILD-R005` — When no arguments are given, the script must use `site.in/` and `site.out/` relative to the repository root.
- `SITE-BUILD-R006` — The script must be a POSIX shell script.
- `SITE-BUILD-R007` — The HTML page structure must live in `site.in/template.html`, not in the build script.
- `SITE-BUILD-R008` — `site.in/template.html` must contain the marker line `<!-- SITE-CONTENT -->` where page content is inserted.
- `SITE-BUILD-R009` — `scripts/site-verify.sh` must check that each `site.in/*.txt` input has a matching `site.out/<name>.html` page; it lists every missing page and, with `--strict`, exits nonzero when any page is missing.

## Behavior

- Running the script recreates `site.out/` from `site.in/`.
- Re-running the script overwrites existing output deterministically.
- Running the verifier with `--strict` exits nonzero when a generated page is missing.

## Dependencies

- None.
