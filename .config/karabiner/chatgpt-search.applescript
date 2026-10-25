#!/usr/bin/osascript
use framework "Foundation"
use scripting additions

set searchQuery to ""
try
    set searchQuery to the clipboard as text
end try

try
    tell application "System Events" to keystroke "c" using {command down}
    delay 0.3
    set copiedText to the clipboard as text
    if copiedText is not "" then set searchQuery to copiedText
end try

if searchQuery is "" then
    display notification "Select text or copy a search query first." with title "ChatGPT Search"
    return
end if

set promptText to quote & searchQuery & quote & " what does this mean"
set allowedCharacters to current application's NSCharacterSet's characterSetWithCharactersInString:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
set encodedQuery to (current application's NSString's stringWithString:promptText)'s stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters
set searchURL to "https://chatgpt.com/?q=" & (encodedQuery as text)
open location searchURL
