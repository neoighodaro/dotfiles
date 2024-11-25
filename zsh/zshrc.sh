# ------------------------------------------------------------------------------
# Neo Ighodaro <neo@creativitykills.co> 2024
# Released under the MIT License.
# ------------------------------------------------------------------------------

if [[ $___ALREADY_INITIALIZED_DOTFILES -eq 1 ]]; then
    return
fi

# Prevent from running this script multiple times
___ALREADY_INITIALIZED_DOTFILES=1

# General Options
# ------------------------------------------------------------------------------
## Fixes tmux 256 color issue
[[ ! -z $TMUX && $TERM == screen ]] && TERM=screen-256color

## Set the default user
DEFAULT_USER="$(whoami)"

# Set Up Command History
# ------------------------------------------------------------------------------
## Enable globally shared history (same history in every shell)
setopt SHARE_HISTORY

## When writing out the history file, older duplicate commands are omitted
setopt HIST_SAVE_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS

## Don't save commands prefixed with at least one space to history
setopt HIST_IGNORE_SPACE

## Don't directly execute commands when using history expansion
setopt HIST_VERIFY

## Max number of history lines in memory
HISTSIZE=25000

## Max number of history lines saved in history file
SAVEHIST=200000


# Set Up Line Editor
# ------------------------------------------------------------------------------
## Bind arrow keys to word cursor navigation
bindkey "\e\e[C" forward-word
bindkey "\e\e[D" backward-word
bindkey "^[a" beginning-of-line   # For iTerm. Preferences > Keys, set "Send escape sequence" to "a" and "e" for the desired key bindings.
bindkey "^[e" end-of-line         # For iTerm. Preferences > Keys, set "Send escape sequence" to "a" and "e" for the desired key bindings.


# ZSH Sprcific
# ------------------------------------------------------------------------------
## Load custom functions
[ -f "$HOME/.zshrc_functions" ] && \. "$HOME/.zshrc_functions"

## Load aliases
[ -f "$HOME/.zshrc_aliases" ]   && \. "$HOME/.zshrc_aliases"

## Load private
[ -f "$HOME/.zshrc_private" ]   && \. "$HOME/.zshrc_private"

## Load ZSH Plugins
ZSH_PLUGIN_FILES=(
    "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
)
for plugin_file in "${ZSH_PLUGIN_FILES[@]}"; do
    [ -f "$plugin_file" ] && source "$plugin_file"
done


# starship
# ------------------------------------------------------------------------------
if type starship &>/dev/null; then
    eval "$(starship init zsh)"   # Starship
fi


# fzf
# ------------------------------------------------------------------------------
if type fzf &>/dev/null; then
  source <(fzf --zsh)

  export FZF_CTRL_R_OPTS="
  --color header:italic
  --height=80%
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --header 'CTRL-Y: Copy command into clipboard, CTRL-/: Toggle line wrapping, CTRL-R: Toggle sorting by relevance'
  "

  export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --height=80%
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
  --header 'CTRL-/: Toggle preview window position'
  "

  # --preview 'tree -C {}'
  export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target
  --height=80%
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
  --header 'CTRL-/: Toggle preview window position'
  "
fi


# zoxide (better `cd`)
# ------------------------------------------------------------------------------
if type zoxide &>/dev/null; then
  eval "$(zoxide init zsh --cmd cd)"
fi


# zellij
# ------------------------------------------------------------------------------
if type zellij &>/dev/null; then
  DISABLED_TERMINAL_PROGRAMS=(vscode JetBrains-JediTerm)  # Add more as needed
  if [[ ! " ${DISABLED_TERMINAL_PROGRAMS[@]} " =~ " $TERM_PROGRAM " ]] && [[ ! " ${DISABLED_TERMINAL_PROGRAMS[@]} " =~ " $TERMINAL_EMULATOR " ]]; then
    eval "$(zellij setup --generate-auto-start zsh)"
  fi
fi


# ----------------------------------------------------------------------------------------
# EXPORTS
# ----------------------------------------------------------------------------------------

export LANG=${LANG:-en_US.UTF-8}                        # Prefer US English and UTF-8
export LC_CTYPE=${LC_CTYPE:-$LANG}                      # Prefer US English and UTF-8
export LC_ALL=${LC_ALL:-$LANG}                          # Prefer US English and UTF-8
export GREP_OPTIONS="--color=auto"                      # Always enable colored `grep` output
export GPG_TTY=$(tty)                                   # Fix GPG prompt
export HOMEBREW_CASK_OPTS="--appdir=/Applications"      # Link Homebrew casks in `/Applications` rather than `~/Applications`
export XDG_CONFIG_HOME="$HOME/.config"                  # XDG config directory

# NVM
# ----------------------------------------------------------------------------------------
NVM_POTENTIAL_PATH="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
if [[ -d "$NVM_POTENTIAL_PATH" ]] && [[ -f "$NVM_POTENTIAL_PATH/nvm.sh" ]]; then
    export NVM_DIR="$NVM_POTENTIAL_PATH"
fi

[ -d "$HOME/.composer/vendor/bin" ] && export PATH="$HOME/.composer/vendor/bin:$PATH"      # Add Composer to PATH
export PATH="/opt/homebrew/bin:$PATH"                   # Add Homebrew to PATH

[ ! -n $SSH_CONNECTION ] && export EDITOR="code -w"     # Use VSCode as default editor when not connected to a remote machine

# Load custom paths
[ -f "$HOME/.zshrc_paths" ] && \. "$HOME/.zshrc_paths"

export PATH="/usr/local/bin:/usr/local/sbin:$PATH"      # Add /usr/local/bin to PATH, LEAVE AS LAST!

# ----------------------------------------------------------------------------------------
# LOAD PACKAGES
# ----------------------------------------------------------------------------------------

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                    # Node Version Manager
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # Node Version Manager

# ----------------------------------------------------------------------------------------
# LOAD CUSTOM SCRIPTS
# ----------------------------------------------------------------------------------------

[ -f "$HOME/.zshrc_scripts" ] && \. "$HOME/.zshrc_scripts"
