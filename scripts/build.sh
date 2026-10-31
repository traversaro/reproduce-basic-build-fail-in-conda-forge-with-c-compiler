#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

printf 'CONDA_PREFIX=%s\nCC=%s\nAR=%s\nRANLIB=%s\nLD=%s\n' \
    "${CONDA_PREFIX-}" "${CC-}" "${AR-}" "${RANLIB-}" "${LD-}"
for tool in cc gcc ar ranlib ld make cmake; do
    if path=$(command -v "$tool"); then
        printf '%s: %s\n' "$tool" "$path"
    else
        printf '%s: not on PATH\n' "$tool"
    fi
done

if [ "$#" -eq 0 ]; then
    set -- shared static executable
fi

status=0
for target in "$@"; do
    case "$target" in
        shared|static|executable) ;;
        *) printf 'Unknown target: %s\n' "$target" >&2; exit 2 ;;
    esac

    build_dir="build/$target"
    rm -rf "$build_dir"
    printf '\n=== Building %s ===\n' "$target"
    if cmake -S . -B "$build_dir" -G "Unix Makefiles" &&
        cmake --build "$build_dir" --target "example_$target" --verbose; then
        if [ "$target" = executable ] && ! "$build_dir/example_executable"; then
            printf 'FAIL: %s runtime check\n' "$target" >&2
            status=1
        else
            printf 'PASS: %s\n' "$target"
        fi
    else
        printf 'FAIL: %s build\n' "$target" >&2
        status=1
    fi
done
exit "$status"
