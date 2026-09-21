#!/bin/sh
#
# llvm-build.sh: fetch, configure, and build the pinned LLVM/Clang base.
#
# Feature: prompts/features/05-llvm-backend.md
#
# Usage: llvm-build.sh [MODE]
#
# Modes:
#   check      verify that the required build tools are present; no writes
#   source     clone the upstream repository and check out the pinned base
#   configure  run the CMake configure step into the build tree
#   build      compile clang and lld
#   all        check, source, configure, and build (the default)
#   status     report the pin, the paths, and what is present
#
# Environment overrides:
#   VERSION_LLVM_PIN      upstream tag to build
#   NAME_BRANCH_LLVM      local branch that carries the pin
#   URL_LLVM_REPOSITORY   clone URL
#   LINKER_LLVM_BUILD     linker CMake should use
#
# The upstream checkout lives in sources/llvm-project/ and the generated
# build tree in dataflow.out/llvm-build/; neither is version-controlled.
# The pin is a release tag, not a branch, because the fork carries a small
# delta against a single upstream base: see
# documents/22-fork-or-extend-decision.md section 10.
set -eu

DIRECTORY_SCRIPT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPOSITORY_ROOT=$(CDPATH= cd -- "$DIRECTORY_SCRIPT/.." && pwd)

VERSION_LLVM_PIN=${VERSION_LLVM_PIN:-llvmorg-23.1.1}
NAME_BRANCH_LLVM=${NAME_BRANCH_LLVM:-elseon-pin}
URL_LLVM_REPOSITORY=${URL_LLVM_REPOSITORY:-https://github.com/llvm/llvm-project.git}
LINKER_LLVM_BUILD=${LINKER_LLVM_BUILD:-gold}

DIRECTORY_SOURCE="$REPOSITORY_ROOT/sources/llvm-project"
DIRECTORY_BUILD="$REPOSITORY_ROOT/dataflow.out/llvm-build"

NAME_BUILD_TYPE=Release
TARGETS_LLVM_BUILD='X86;AArch64'
PROJECTS_LLVM_BUILD='clang;lld'
TARGETS_NINJA_BUILD='clang lld'
JOBS_LLVM_LINK=4

# Verify the tools the configure and build steps need.
# Exit status is nonzero when any tool is missing.
check_tools() {
    status_missing=0

    for tool_required in git cmake ninja python3 cc c++; do
        if command -v "$tool_required" >/dev/null 2>&1; then
            printf 'llvm-build: tool %-8s %s\n' "$tool_required" "$(command -v "$tool_required")"
        else
            printf 'llvm-build: missing required tool: %s\n' "$tool_required" >&2
            status_missing=1
        fi
    done

    if [ 0 -ne "$status_missing" ]; then
        return 1
    fi

    return 0
}

# Clone the upstream repository once, then create or reuse the pinned branch.
# An existing branch is never reset, so local commits survive a re-run.
do_source() {
    if [ -d "$DIRECTORY_SOURCE/.git" ]; then
        printf 'llvm-build: fetching %s\n' "$DIRECTORY_SOURCE"
        git -C "$DIRECTORY_SOURCE" fetch --tags --prune origin
    else
        printf 'llvm-build: cloning %s into %s\n' "$URL_LLVM_REPOSITORY" "$DIRECTORY_SOURCE"
        mkdir -p "$(dirname -- "$DIRECTORY_SOURCE")"
        git clone "$URL_LLVM_REPOSITORY" "$DIRECTORY_SOURCE"
    fi

    if git -C "$DIRECTORY_SOURCE" show-ref --verify --quiet "refs/heads/$NAME_BRANCH_LLVM"; then
        printf 'llvm-build: branch %s exists; leaving it untouched\n' "$NAME_BRANCH_LLVM"
        git -C "$DIRECTORY_SOURCE" checkout "$NAME_BRANCH_LLVM"
    else
        printf 'llvm-build: creating branch %s at %s\n' "$NAME_BRANCH_LLVM" "$VERSION_LLVM_PIN"
        git -C "$DIRECTORY_SOURCE" checkout -b "$NAME_BRANCH_LLVM" "$VERSION_LLVM_PIN"
    fi

    printf 'llvm-build: HEAD %s\n' "$(git -C "$DIRECTORY_SOURCE" rev-parse --short HEAD)"
}

# Configure the generated build tree from the pinned source tree.
do_configure() {
    if [ ! -d "$DIRECTORY_SOURCE/llvm" ]; then
        printf 'llvm-build: source tree is missing: %s\n' "$DIRECTORY_SOURCE" >&2
        printf 'llvm-build: run "llvm-build.sh source" first\n' >&2
        return 1
    fi

    mkdir -p "$DIRECTORY_BUILD"

    cmake -G Ninja \
        -S "$DIRECTORY_SOURCE/llvm" \
        -B "$DIRECTORY_BUILD" \
        -DCMAKE_BUILD_TYPE="$NAME_BUILD_TYPE" \
        -DLLVM_ENABLE_ASSERTIONS=ON \
        -DLLVM_ENABLE_PROJECTS="$PROJECTS_LLVM_BUILD" \
        -DLLVM_TARGETS_TO_BUILD="$TARGETS_LLVM_BUILD" \
        -DLLVM_USE_LINKER="$LINKER_LLVM_BUILD" \
        -DLLVM_PARALLEL_LINK_JOBS="$JOBS_LLVM_LINK" \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_INCLUDE_BENCHMARKS=OFF \
        -DLLVM_INCLUDE_DOCS=OFF \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
}

# Compile the requested ninja targets. Re-run after configuring to rebuild
# incrementally; no configuration step is repeated here.
do_build() {
    if [ ! -f "$DIRECTORY_BUILD/build.ninja" ]; then
        printf 'llvm-build: build tree is not configured: %s\n' "$DIRECTORY_BUILD" >&2
        printf 'llvm-build: run "llvm-build.sh configure" first\n' >&2
        return 1
    fi

    cmake --build "$DIRECTORY_BUILD" --target $TARGETS_NINJA_BUILD
}

report_status() {
    printf 'llvm-build: pin %s\n' "$VERSION_LLVM_PIN"
    printf 'llvm-build: branch %s\n' "$NAME_BRANCH_LLVM"
    printf 'llvm-build: target(s) %s\n' "$TARGETS_NINJA_BUILD"

    printf 'llvm-build: source %s\n' "$DIRECTORY_SOURCE"
    if [ -d "$DIRECTORY_SOURCE/.git" ]; then
        printf 'llvm-build: source-state %s\n' \
            "$(git -C "$DIRECTORY_SOURCE" describe --tags --always 2>/dev/null || echo unknown)"
    else
        printf 'llvm-build: source-state absent\n'
    fi

    printf 'llvm-build: build %s\n' "$DIRECTORY_BUILD"
    if [ -x "$DIRECTORY_BUILD/bin/clang" ]; then
        printf 'llvm-build: clang %s\n' "$("$DIRECTORY_BUILD/bin/clang" --version | head -n 1)"
    else
        printf 'llvm-build: clang absent\n'
    fi
}

MODE_REQUESTED=${1:-all}

case "$MODE_REQUESTED" in
    check)
        check_tools
        ;;
    source)
        do_source
        ;;
    configure)
        do_configure
        ;;
    build)
        do_build
        ;;
    all)
        check_tools
        do_source
        do_configure
        do_build
        ;;
    status)
        report_status
        ;;
    *)
        printf 'llvm-build: unknown mode: %s\n' "$MODE_REQUESTED" >&2
        printf 'usage: llvm-build.sh [check|source|configure|build|all|status]\n' >&2
        exit 2
        ;;
esac

printf 'llvm-build: %s ok\n' "$MODE_REQUESTED"
exit 0
