#!/bin/sh
#
# Test for scripts/site-verify.sh (prompts/features/01-site-build.md).
# The verifier runs against a temporary directory so that generated output
# never lands in the repository tree.
set -eu

DIRECTORY_SCRIPT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPOSITORY_ROOT=$(CDPATH= cd -- "$DIRECTORY_SCRIPT/.." && pwd)
SCRIPT_VERIFY="$REPOSITORY_ROOT/scripts/site-verify.sh"

. "$DIRECTORY_SCRIPT/lib/test_helpers.sh"

NAME_TEST='05-site-verify'

[ -f "$SCRIPT_VERIFY" ] || fail_test "$NAME_TEST" "missing script: $SCRIPT_VERIFY"

DIRECTORY_TEMPORARY=$(mktemp -d)
trap 'rm -rf "$DIRECTORY_TEMPORARY"' EXIT HUP INT TERM

DIRECTORY_INPUT="$DIRECTORY_TEMPORARY/site.in"
DIRECTORY_OUTPUT="$DIRECTORY_TEMPORARY/site.out"
mkdir -p "$DIRECTORY_INPUT" "$DIRECTORY_OUTPUT"
printf '%s\n' 'hello' > "$DIRECTORY_INPUT/hello.txt"
printf '%s\n' 'world' > "$DIRECTORY_INPUT/world.txt"
: > "$DIRECTORY_OUTPUT/hello.html"
: > "$DIRECTORY_OUTPUT/world.html"

FILE_MISSING="$DIRECTORY_OUTPUT/world.html"

# Every page present: --strict succeeds with no output.
if output=$(sh "$SCRIPT_VERIFY" --strict "$DIRECTORY_INPUT" "$DIRECTORY_OUTPUT"); then
    status=0
else
    status=$?
fi
[ 0 -eq "$status" ] || fail_test "$NAME_TEST" 'strict failed with a complete page set'
[ -z "$output" ] || fail_test "$NAME_TEST" 'strict reported pages that exist'

rm -f "$FILE_MISSING"

# Missing page without --strict: reported, exit 0.
if output=$(sh "$SCRIPT_VERIFY" "$DIRECTORY_INPUT" "$DIRECTORY_OUTPUT"); then
    status=0
else
    status=$?
fi
[ 0 -eq "$status" ] || fail_test "$NAME_TEST" 'non-strict exited nonzero on a missing page'
printf '%s\n' "$output" | grep -Fqx "$FILE_MISSING" ||
    fail_test "$NAME_TEST" "missing page not reported: $FILE_MISSING"
if printf '%s\n' "$output" | grep -Fq "$DIRECTORY_OUTPUT/hello.html"; then
    fail_test "$NAME_TEST" 'reported a page that exists'
fi

# Missing page with --strict: reported, nonzero.
if output=$(sh "$SCRIPT_VERIFY" --strict "$DIRECTORY_INPUT" "$DIRECTORY_OUTPUT"); then
    status=0
else
    status=$?
fi
[ 0 -ne "$status" ] || fail_test "$NAME_TEST" 'strict exited zero on a missing page'
printf '%s\n' "$output" | grep -Fqx "$FILE_MISSING" ||
    fail_test "$NAME_TEST" 'strict did not report the missing page'

pass_test "$NAME_TEST"
