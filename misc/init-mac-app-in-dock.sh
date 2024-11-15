#!/bin/bash

# ---------------------------------------------------------------------------------------------------
# Adds the applications folder to the dock
# ---------------------------------------------------------------------------------------------------

# Define the Dock plist path
DOCK_PLIST=~/Library/Preferences/com.apple.dock.plist

# Check if persistent-others array exists
/usr/libexec/PlistBuddy -c "Print persistent-others" "$DOCK_PLIST" &>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add persistent-others array" "$DOCK_PLIST"

if ! /usr/libexec/PlistBuddy -c "Print persistent-others" "$DOCK_PLIST" | grep -q "file:///Applications/"; then
  /usr/libexec/PlistBuddy -c "Add :persistent-others:0 dict" ~/Library/Preferences/com.apple.dock.plist
  /usr/libexec/PlistBuddy -c "Add :persistent-others:0:tile-data dict" ~/Library/Preferences/com.apple.dock.plist
  /usr/libexec/PlistBuddy -c "Add :persistent-others:0:tile-data:arrangement integer 1" ~/Library/Preferences/com.apple.dock.plist
  /usr/libexec/PlistBuddy -c "Add :persistent-others:0:tile-data:displayas integer 1" ~/Library/Preferences/com.apple.dock.plist
  /usr/libexec/PlistBuddy -c "Add :persistent-others:0:tile-data:file-data dict" ~/Library/Preferences/com.apple.dock.plist
  /usr/libexec/PlistBuddy -c "Add :persistent-others:0:tile-data:file-data:_CFURLString string file:///Applications/" ~/Library/Preferences/com.apple.dock.plist
  /usr/libexec/PlistBuddy -c "Add :persistent-others:0:tile-data:file-data:_CFURLStringType integer 15" ~/Library/Preferences/com.apple.dock.plist
  /usr/libexec/PlistBuddy -c "Add :persistent-others:0:tile-data:file-type integer 2" ~/Library/Preferences/com.apple.dock.plist
  /usr/libexec/PlistBuddy -c "Add :persistent-others:0:tile-data:showas integer 2" ~/Library/Preferences/com.apple.dock.plist
  /usr/libexec/PlistBuddy -c "Add :persistent-others:0:tile-type string directory-tile" ~/Library/Preferences/com.apple.dock.plist
fi
