#!/usr/bin/env bash
#
# Downloads the latest icon_map.sh from sketchybar-app-font and updates
# the local icon_map_fn.sh used by sketchybar.
#

set -euo pipefail

REPO="kvndrsslr/sketchybar-app-font"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Developer/dotfiles}"
TARGET="$DOTFILES_DIR/configs/sketchybar/plugins/icon_map_fn.sh"

echo "Fetching latest icon_map.sh from $REPO..."

TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

gh release download --repo "$REPO" --pattern "icon_map.sh" --output "$TMPFILE" --clobber

cat "$TMPFILE" > "$TARGET"

# Only append caller lines if the release lacks its own direct-execution block.
if ! grep -q 'BASH_SOURCE' "$TARGET"; then
    echo '__icon_map "$1"' >> "$TARGET"
    echo 'echo "$icon_result"' >> "$TARGET"
fi

chmod +x "$TARGET"

VERSION=$(gh release view --repo "$REPO" --json tagName -q '.tagName')
echo "Updated icon_map_fn.sh to $VERSION"
