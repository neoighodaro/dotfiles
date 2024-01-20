# ----------------------------------------------------------------------------------------
# @author  Neo Ighodaro <neo@creativitykills.co>
# @package .dotfiles
# ----------------------------------------------------------------------------------------

# Fix tmux 256 color
[[ ! -z $TMUX && $TERM == screen ]] && TERM=screen-256color

# ----------------------------------------------------------------------------------------
# KEY BINDINGS
# ----------------------------------------------------------------------------------------

bindkey "\e\e[C" forward-word
bindkey "\e\e[D" backward-word

# For these to work in iTerm. Go to preferences > Keys, set
# "Send escape sequence" to "a" and "e" for the desired key bindings.
bindkey "^[a" beginning-of-line
bindkey "^[e" end-of-line


# ----------------------------------------------------------------------------------------
# ZSH Configuration
# ----------------------------------------------------------------------------------------

# -- Path
export ZSH=$HOME/.oh-my-zsh

# -- Theme
ZSH_THEME=""

# -- Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-z)

DEFAULT_USER=neo
# ENABLE_CORRECTION=true


# ----------------------------------------------------------------------------------------
# Load ZSH
# ----------------------------------------------------------------------------------------

# -- Aliases
[ -f "$HOME/.dotfiles/.zsh_aliases.sh" ] && \. "$HOME/.dotfiles/.zsh_aliases.sh"

# -- Functions
[ -f "$HOME/.dotfiles/.zsh_functions.sh" ] && \. "$HOME/.dotfiles/.zsh_functions.sh"

# -- Custom scripts to be loaded before oh-my-zsh
[ -f "$HOME/.dotfiles/.zsh_preload.sh" ] && \. "$HOME/.dotfiles/.zsh_preload.sh"

# -- Load oh-my-zsh
source "$ZSH/oh-my-zsh.sh"

# -- Custom scripts to be loaded after oh-my-zsh
[ -f "$HOME/.dotfiles/.zsh_postload.sh" ] && \. "$HOME/.dotfiles/.zsh_postload.sh"

# -- Private
[ -f "$HOME/.dotfiles/.zsh_private.sh" ] && \. "$HOME/.dotfiles/.zsh_private.sh"


# ----------------------------------------------------------------------------------------
# PURE THEME: https://github.com/sindresorhus/pure
# ----------------------------------------------------------------------------------------

autoload -U promptinit; promptinit
prompt pure


# ----------------------------------------------------------------------------------------
# EXPORTS
# ----------------------------------------------------------------------------------------

# Prefer US English and UTF-8
export LANG=${LANG:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-$LANG}
export LC_ALL=${LC_ALL:-$LANG}

# Always enable colored `grep` output
export GREP_OPTIONS="--color=auto"
export GPG_TTY=$(tty)

# Link Homebrew casks in `/Applications` rather than `~/Applications`
export HOMEBREW_CASK_OPTS="--appdir=/Applications --caskroom=/etc/Caskroom"

# -- Node version manager
export NVM_DIR="$HOME/.nvm"

# -- Default Editor
if [[ ! -n $SSH_CONNECTION ]]; then
    export EDITOR="code -w"
fi

# -- Development Packages Flags
export XDEBUG_CONFIG="idekey=VSCODE"
# export PHP_CS_FIXER_IGNORE_ENV=1
# export THEOS_DEVICE_IP="Replace with device IP if needed"

# export HOMEBREW_GITHUB_API_TOKEN="STORE THIS IN .zsh_private.sh"

# -- Homebrew
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/usr/local/bin:$PATH"

# -- Composer
export PATH="$HOME/.composer/vendor/bin:$PATH"

# -- Ruby Version Manager
export PATH="$HOME/.rvm/bin:$PATH"

# -- Custom Exports
[ -f "$HOME/.dotfiles/.zsh_exports.sh" ] && \. "$HOME/.dotfiles/.zsh_exports.sh"

# -- Flutter (Move to ~/.dotfiles/.zsh_exports.sh)
# export PATH="$HOME/flutter/bin:$PATH"

# -- Android (Move to ~/.dotfiles/.zsh_exports.sh)
# export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"

# -- Golang (Move to ~/.dotfiles/.zsh_exports.sh)
# export GOBIN="$GOPATH/bin"
# export GOPATH="$HOME/Dev/Personal/Golang"
# export PATH="$PATH:$GOBIN"

# -- Theos (Move to ~/.dotfiles/.zsh_exports.sh)
# export THEOS="$HOME/theos"

# -- !! LEAVE AS LAST
export PATH="/usr/local/bin:/usr/local/sbin:$PATH"


# ----------------------------------------------------------------------------------------
# LOAD PACKAGES
# ----------------------------------------------------------------------------------------

# -- Custom Exports
[ -f "$HOME/.dotfiles/.zsh_packages.sh" ] && \. "$HOME/.dotfiles/.zsh_packages.sh"

# -- Node Version Manager
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# -- Ruby
[[ -f "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
[ -x "$(command -v rbenv)" ] && eval "$(rbenv init -)"
