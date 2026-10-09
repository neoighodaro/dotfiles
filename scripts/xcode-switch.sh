#!/usr/bin/env bash
#
# Switches the active Xcode (xcode-select) between installed versions.
#
# Usage:
#   xcode-switch            Toggle between Xcode.app and Xcode-beta.app
#   xcode-switch stable     Use /Applications/Xcode.app
#   xcode-switch beta       Use /Applications/Xcode-beta.app
#   xcode-switch status     Show the active Xcode
#   xcode-switch list       List installed Xcode apps
#

set -euo pipefail

STABLE="/Applications/Xcode.app"
BETA="/Applications/Xcode-beta.app"

show_help() {
    sed -n '5,11p' "$0" | sed 's/^# \{0,1\}//'
}

active_app() {
    local dev
    dev=$(xcode-select -p 2>/dev/null || true)
    echo "${dev%/Contents/Developer}"
}

app_version() {
    local plist="$1/Contents/version.plist"
    local version build
    version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist" 2>/dev/null || echo "?")
    build=$(/usr/libexec/PlistBuddy -c "Print :ProductBuildVersion" "$plist" 2>/dev/null || echo "?")
    echo "$version ($build)"
}

show_status() {
    local app
    app=$(active_app)
    if [ -z "$app" ]; then
        echo "No active Xcode."
    elif [ -d "$app" ] && [[ "$app" == *.app ]]; then
        echo "Active: $app — $(app_version "$app")"
    else
        echo "Active: $app"
    fi
}

list_apps() {
    local active app marker
    active=$(active_app)
    shopt -s nullglob
    for app in /Applications/Xcode*.app; do
        marker="  "
        [ "$app" = "$active" ] && marker="* "
        echo "$marker$app — $(app_version "$app")"
    done
}

switch_to() {
    local app="$1"
    if [ ! -d "$app" ]; then
        echo "Error: $app not found." >&2
        exit 1
    fi
    if [ "$(active_app)" = "$app" ]; then
        echo "Already using $app — $(app_version "$app")"
        return
    fi
    echo "Switching to $app (requires sudo)..."
    sudo xcode-select -s "$app/Contents/Developer"
    show_status
}

case "${1:-toggle}" in
    toggle)
        if [ "$(active_app)" = "$BETA" ]; then
            switch_to "$STABLE"
        else
            switch_to "$BETA"
        fi
        ;;
    stable) switch_to "$STABLE" ;;
    beta) switch_to "$BETA" ;;
    status) show_status ;;
    list | ls) list_apps ;;
    -h | --help | help) show_help ;;
    *)
        echo "Error: unknown command '$1'" >&2
        echo "" >&2
        show_help >&2
        exit 1
        ;;
esac
