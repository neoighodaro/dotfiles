#!/bin/bash

local IS_MACOS=$(uname -s | grep -i "darwin" | wc -l | tr -d '[:space:]')
local IS_LINUX=$(uname -s | grep -i "linux" | wc -l | tr -d '[:space:]')

# Misc
# ------------------------------------------------------------------------------
export DOTFILES_DIR="$HOME/Developer/dotfiles"
export CK_INFRA_DIR="$HOME/Developer/ck/infra"
export PATH="$HOME/.local/bin:$HOME/Developer/bin:$PATH"
export ANSIBLE_CONFIG="$HOME/.config/ansible/ansible.cfg"

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

# Kiro
# ------------------------------------------------------------------------------
if [[ $IS_MACOS -eq 1 ]]; then
    [[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
fi
