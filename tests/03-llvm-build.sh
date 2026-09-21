#!/bin/sh
#
# Test for the LLVM build setup (scripts/llvm-build.sh).
# Tool-gated: the LLVM build itself is far too large to run here, so this test
# checks the script interface and the pin instead, and reports a clean SKIP
# when the required build tools are absent.
set -eu

DIRECTORY_SCRIPT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPOSITORY_ROOT=$(CDPATH= cd -- "$DIRECTORY_SCRIPT/.." && pwd)
SCRIPT_BUILD="$REPOSITORY_ROOT/scripts/llvm-build.sh"

if [ ! -f "$SCRIPT_BUILD" ]; then
    echo "03-llvm-build: missing build script: $SCRIPT_BUILD" >&2
    exit 1
fi

if ! sh -n "$SCRIPT_BUILD"; then
    echo '03-llvm-build: build script fails sh -n' >&2
    exit 1
fi

output_status=$(sh "$SCRIPT_BUILD" status)

name_pin=$(printf '%s\n' "$output_status" | sed -n 's/^llvm-build: pin //p')

if [ -z "$name_pin" ]; then
    echo '03-llvm-build: status does not report a pin' >&2
    exit 1
fi

if ! printf '%s\n' "$name_pin" | grep -q '^llvmorg-[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$'; then
    echo "03-llvm-build: pin is not a release tag: $name_pin" >&2
    echo '03-llvm-build: a branch pin cannot be rebased against a fixed base' >&2
    exit 1
fi

if ! grep -q "$name_pin" "$REPOSITORY_ROOT/sources/README.md"; then
    echo "03-llvm-build: sources/README.md does not record the pin: $name_pin" >&2
    exit 1
fi

if ! sh "$SCRIPT_BUILD" check >/dev/null 2>&1; then
    echo '03-llvm-build: SKIP: build tools are absent (tool-gated)'
    exit 0
fi

echo '03-llvm-build: ok'
exit 0
