# @author  Neo Ighodaro
# @package dotfiles

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

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Default user
DEFAULT_USER=neo

# Set name of the theme to load.
ZSH_THEME="pure"

# Which plugins would you like to load?
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)


# ----------------------------------------------------------------------------------------
# Load ZSH
# ----------------------------------------------------------------------------------------

source $ZSH/oh-my-zsh.sh

[[ -e ~/.dotfiles/init.sh ]] && emulate sh -c 'source ~/.dotfiles/init.sh'


# ----------------------------------------------------------------------------------------
# Exports
# ----------------------------------------------------------------------------------------

if [[ ! -n $SSH_CONNECTION ]]; then
    #export EDITOR="code -w"
fi

# export THEOS_DEVICE_IP=192.168.178.23
export XDEBUG_CONFIG="idekey=VSCODE"
export HOMEBREW_GITHUB_API_TOKEN="1400bbef88f096df6194a3e7245dd7f56e0fb5c3"
# export PHP_CS_FIXER_IGNORE_ENV=1

# ----------------------------------------------------------------------------------------
# LOAD THE PURE THEME: https://github.com/sindresorhus/pure
# ----------------------------------------------------------------------------------------

autoload -U promptinit; promptinit
prompt pure


# ----------------------------------------------------------------------------------------
# PATHS
# ----------------------------------------------------------------------------------------

export GOPATH="$HOME/Development/Go"
export GOBIN="$GOPATH/bin"
export THEOS="$HOME/theos"
export NVM_DIR="$HOME/.nvm"


export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/flutter/bin:$PATH"
export PATH="$HOME/.composer/vendor/bin:$PATH"
export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
export PATH="$PATH:$GOBIN"
export PATH="$HOME/.rvm/bin:$PATH"
export PATH="/usr/local/bin:/usr/local/sbin:$PATH"

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
[[ -f "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

eval "$(rbenv init -)"
