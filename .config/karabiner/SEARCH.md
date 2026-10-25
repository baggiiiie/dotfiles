Build the native search helper with `./build-search.sh` after changing `search-selection.swift`.

`quick-search.sh` searches DuckDuckGo. `chatgpt-search.sh` opens ChatGPT with `"selected text" what does this mean`.

The helper reads selected text through Accessibility. If the app does not expose it, it tries Command-C and waits for the clipboard to change, for at most 250 ms. It restores the previous clipboard unless another change occurred. Clipboard snapshots are limited to 1 MiB; larger or unreadable clipboards skip the copy fallback. If copying produces no text, the existing clipboard text is used.

The helper needs Accessibility permission through its launching app or its own executable. It runs only when triggered, with no background service. For a safe URL-format check, run `./search-selection chatgpt --print-url 'example text'`.
