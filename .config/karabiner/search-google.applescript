#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title search test
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🤖

set searchQuery to ""
try
	tell application "System Events"
		keystroke "c" using command down -- Copy selected text
		delay 0.2 -- Small delay to allow clipboard to update
		set searchQuery to the clipboard
	end tell
on error
	display dialog "Error copying selected text: " & errorMessage buttons {"OK"} default button "OK"
	
end try

if searchQuery is "" then
	set searchQuery to the clipboard -- If nothing was selected, use clipboard content
end if

if searchQuery is not "" then
	-- Properly escape the search query for a URL
	set encodedQuery to do shell script "python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' " & quoted form of searchQuery
	set searchURL to "https://www.google.com/search?q=" & encodedQuery
	open location searchURL
end if
