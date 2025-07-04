#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title search test
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🤖
set searchQuery to ""

-- Store clipboard content before trying to copy
set originalClipboard to the clipboard

try
    tell application "System Events"
        keystroke "c" using {command down} -- Try copying selection
        delay 0.3 -- Allow clipboard time to update
        display notification "Copied text"
    end tell
    set searchQuery to the clipboard
on error errorMessage
    display dialog "Error copying selected text: " & errorMessage buttons {"OK"} default button "OK"
    set searchQuery to originalClipboard -- Fallback to clipboard content
end try

-- Ensure query is non-empty
if searchQuery is "" then
    set searchQuery to originalClipboard
end if

-- If still empty, show an error
if searchQuery is "" then
    display dialog "Error: No selected text and clipboard is empty." buttons {"OK"} default button "OK"
    return
end if

-- Encode query properly
try
    set encodedQuery to do shell script "python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' " & quoted form of searchQuery
on error errorMessage
    display dialog "Error encoding search query: " & errorMessage buttons {"OK"} default button "OK"
    return
end try

-- Construct Google search URL
set searchURL to "https://www.google.com/search?q=" & encodedQuery

-- Open in default browser
try
    tell application "Finder" to open location searchURL
on error errorMessage
    display dialog "Error opening browser: " & errorMessage buttons {"OK"} default button "OK"
end try
