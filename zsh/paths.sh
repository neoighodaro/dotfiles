#!/bin/bash

local IS_MACOS=$(uname -s | grep -i "darwin" | wc -l | tr -d '[:space:]')
local IS_LINUX=$(uname -s | grep -i "linux" | wc -l | tr -d '[:space:]')

# Bun
# ------------------------------------------------------------------------------
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Laravel Herd
# ------------------------------------------------------------------------------
if [[ $IS_MACOS -eq 1 ]]; then
    export HERD_PHP_83_INI_SCAN_DIR="/Users/neo/Library/Application Support/Herd/config/php/83/"
    export PATH="/Users/neo/Library/Application Support/Herd/bin/":$PATH
fi
