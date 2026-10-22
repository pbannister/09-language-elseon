#!/bin/sh
#
# site-verify.sh: check that every generated site page exists.
#
# Feature: prompts/features/01-site-build.md
#
# Usage: site-verify.sh [--strict] [DIRECTORY_INPUT] [DIRECTORY_OUTPUT]
#
# Every site.in/*.txt input file must have a matching site.out/<name>.html page.
# Each missing page is reported on standard output, one page path per line.
# Without --strict, missing pages are reported and the exit status is 0.
# With --strict, any missing page makes the exit status nonzero.
#
# The default DIRECTORY_INPUT is site.in/ and the default DIRECTORY_OUTPUT is
# site.out/, both relative to the repository root.
set -eu

DIRECTORY_SCRIPT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPOSITORY_ROOT=$(CDPATH= cd -- "$DIRECTORY_SCRIPT/.." && pwd)

flag_strict=0
argument_input=""
argument_output=""

for argument in "$@"; do
    case "$argument" in
        --strict)
            flag_strict=1
            ;;
        -h|--help)
            echo 'usage: site-verify.sh [--strict] [DIRECTORY_INPUT] [DIRECTORY_OUTPUT]'
            exit 0
            ;;
        -*)
            echo "site-verify: unknown option: $argument" >&2
            echo 'usage: site-verify.sh [--strict] [DIRECTORY_INPUT] [DIRECTORY_OUTPUT]' >&2
            exit 2
            ;;
        *)
            if [ -z "$argument_input" ]; then
                argument_input=$argument
            elif [ -z "$argument_output" ]; then
                argument_output=$argument
            else
                echo 'site-verify: too many arguments' >&2
                exit 2
            fi
            ;;
    esac
done

DIRECTORY_INPUT=${argument_input:-"$REPOSITORY_ROOT/site.in"}
DIRECTORY_OUTPUT=${argument_output:-"$REPOSITORY_ROOT/site.out"}

if [ ! -d "$DIRECTORY_INPUT" ]; then
    echo "site-verify: input directory not found: $DIRECTORY_INPUT" >&2
    exit 1
fi

count_missing=0
for file_input in "$DIRECTORY_INPUT"/*.txt; do
    if [ ! -f "$file_input" ]; then
        continue
    fi
    name_base=$(basename "$file_input" .txt)
    file_output="$DIRECTORY_OUTPUT/$name_base.html"
    if [ ! -f "$file_output" ]; then
        echo "$file_output"
        count_missing=$((count_missing + 1))
    fi
done

if [ 0 -lt "$count_missing" ] && [ 1 -eq "$flag_strict" ]; then
    exit 1
fi

exit 0
