#!/bin/bash

local IS_MACOS=$(uname -s | grep -i "darwin" | wc -l | tr -d '[:space:]')
local IS_LINUX=$(uname -s | grep -i "linux" | wc -l | tr -d '[:space:]')

# General Aliases
# ------------------------------------------------------------------------------
alias clr="clear"
alias k="kubectl"
alias lg="lazygit"
alias nano="vi"
[[ $IS_MACOS -eq 1 ]] && alias cat="bat"
[[ $IS_LINUX -eq 1 ]] && alias cat="batcat"
[[ $IS_MACOS -eq 1 ]] && alias rm="trash"
alias refresh='source ~/.zshrc; echo "Reloaded .zshrc."'
alias reload='source ~/.zshrc; echo "Reloaded .zshrc."'
alias sshconfig="code ~/.ssh/config"
alias please='sudo $(fc -ln -1)'
alias flushdns="dscacheutil -flushcache && killall -HUP mDNSResponder"
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app'
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app'
alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"

# eza (better `ls`)
# ------------------------------------------------------------------------------
if type eza &>/dev/null; then
  alias l="eza --icons"
  alias ls="eza --icons"
  alias ll="eza -lg --icons"
  alias la="eza -lag --icons"
  alias lt="eza -lTg --icons"
  alias lt1="eza -lTg --level=1 --icons"
  alias lt2="eza -lTg --level=2 --icons"
  alias lt3="eza -lTg --level=3 --icons"
  alias lta="eza -lTag --icons"
  alias lta1="eza -lTag --level=1 --icons"
  alias lta2="eza -lTag --level=2 --icons"
  alias lta3="eza -lTag --level=3 --icons"
fi

# PHP & Laravel specific
# ------------------------------------------------------------------------------
alias a="php artisan"
alias sa="sail artisan"
alias sail='[ -f sail ] && sh sail || sh vendor/bin/sail'
alias phpunit="./vendor/bin/phpunit"

# Mac Specific
# ------------------------------------------------------------------------------
if [[ $IS_MACOS -eq 1 ]]; then
    alias pinentry="pinentry-mac"
    alias spotlighton="sudo mdutil -a -i on"
    alias spotlightoff="sudo mdutil -a -i off"
fi

# Docker Specific
# ------------------------------------------------------------------------------
alias di="docker images"
alias dpsa="docker ps -a"
alias dps="docker ps --format 'table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}'"
alias dcu="docker compose up -d"
alias drmi='docker rmi $(docker images --filter "dangling=true" -q --no-trunc)'
alias drmc='docker rm $(docker ps -q -f status=exited)'

# Kubernetes Specific
# ------------------------------------------------------------------------------
alias k="kubectl"
alias kscale="kubectl scale deploy"

# Others
# ------------------------------------------------------------------------------
alias claude="~/.claude/local/claude"
