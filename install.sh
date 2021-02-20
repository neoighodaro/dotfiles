#!/bin/bash
SCRIPT_DIR=$(cd `dirname $0` && pwd)
DOTFILES_DIR="$HOME/.dotfiles"

# ------------------------------------------------------------------------------------------
# Link and Back up Helper
# ------------------------------------------------------------------------------------------

_link_and_backup() {
  DEFAULT_FILE="$HOME/$1"
  LINK_FILE="$SCRIPT_DIR/$1"

  if [[ -e "$DEFAULT_FILE" ]]; then
    mv "$DEFAULT_FILE" "$DEFAULT_FILE.backup"
  fi

  ln -s "$LINK_FILE" "$DEFAULT_FILE"
}


# ------------------------------------------------------------------------------------------
# Begin Script
# ------------------------------------------------------------------------------------------

cd $HOME

# Move the dotfiles directory to the HOME path if necessary...
[[ ! -d $DOTFILES_DIR ]] && mv $SCRIPT_DIR $DOTFILES_DIR

_link_and_backup ".curlrc"
_link_and_backup ".zshrc"
_link_and_backup ".hushlogin"
_link_and_backup ".gitconfig"
_link_and_backup ".gitconfig.work"

echo "Installation complete"
