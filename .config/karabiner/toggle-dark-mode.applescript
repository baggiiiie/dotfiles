#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title search test
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🤖
tell application "System Events"
   tell appearance preferences
      set dark mode to not dark mode
   end tell
   display notification "Toggled dark mode"
end tell
