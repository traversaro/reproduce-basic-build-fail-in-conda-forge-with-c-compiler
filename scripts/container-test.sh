#!/bin/sh
set -eu

for package in binutils binutils-common binutils-x86-64-linux-gnu; do
    state=$(dpkg-query -W -f='${Status}' "$package" 2>/dev/null) || state=absent
    if [ "$state" = "install ok installed" ]; then
        printf 'Unexpected system package: %s\n' "$package" >&2
        exit 1
    fi
done

for tool in ar ranlib ld as nm objcopy objdump strip readelf; do
    if path=$(command -v "$tool"); then
        printf 'Unexpected system tool: %s (%s)\n' "$tool" "$path" >&2
        exit 1
    fi
done
printf 'Confirmed: no system binutils packages or commands.\n'

exec pixi run --locked "$@"
