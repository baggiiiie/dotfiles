#!/bin/sh
# @raycast.schemaVersion 1
# @raycast.title Quick Search
# @raycast.mode silent
exec "$(dirname "$0")/search-selection" duckduckgo "$@"
