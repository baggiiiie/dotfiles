#!/bin/sh
set -eu
search_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
binary=$(mktemp "$search_dir/.search-selection.XXXXXX")
trap 'rm -f "$binary"' EXIT
/usr/bin/xcrun swiftc -O -whole-module-optimization "$search_dir/search-selection.swift" -o "$binary"
chmod 755 "$binary"
mv -f "$binary" "$search_dir/search-selection"
