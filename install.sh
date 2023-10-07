#!/bin/bash
#SCRIPT_DIR=$(cd `dirname $0` && pwd)
DOTFILES_DIR="$HOME/.dotfiles"

# ------------------------------------------------------------------------------------------
# Link and Back up Helper
# ------------------------------------------------------------------------------------------

_link_and_backup() {
  DEFAULT_FILE="$HOME/$1"
  LINK_FILE="$DOTFILES_DIR/$1"

  if [ ! -f "$LINK_FILE" ]; then
    if [[ "$LINK_FILE" == "$DOTFILES_DIR/.gitignore.work" ]]; then
      touch "$LINK_FILE"
      echo "> Created empty file for $LINK_FILE."
    else
      echo "> $LINK_FILE does not exist. Skipping!"
      return
    fi
  fi

  if [ -f "$DEFAULT_FILE" ] && [ ! -L "$DEFAULT_FILE" ]; then
    mv "$DEFAULT_FILE" "$DEFAULT_FILE.backup"
  else
    LINKING_TO=$(readlink "$DEFAULT_FILE")

    if [[ "$LINKING_TO" == "$LINK_FILE" ]]; then
      echo "> Symlink for $DEFAULT_FILE already exists. Skipping!"
      return
    elif [[ -f "$DEFAULT_FILE" ]]; then
      mv "$DEFAULT_FILE" "$DEFAULT_FILE.backup"
    fi
  fi

  ln -s "$LINK_FILE" "$DEFAULT_FILE"
  echo "> Created symlink for $DEFAULT_FILE."
}


# ------------------------------------------------------------------------------------------
# Begin Script
# ------------------------------------------------------------------------------------------

echo "======================================================================="
echo "Beginning installation"
echo "======================================================================="
echo ""

cd $HOME

# Move the dotfiles directory to the HOME path if necessary...
#[[ ! -d $DOTFILES_DIR ]] && mv $SCRIPT_DIR $DOTFILES_DIR

_link_and_backup ".curlrc"
_link_and_backup ".zshrc"
_link_and_backup ".wgetrc"
_link_and_backup ".hushlogin"
_link_and_backup ".screenrc"
_link_and_backup ".gitconfig"
_link_and_backup ".gitconfig.work"
_link_and_backup ".githooks"
_link_and_backup ".mackup.cfg"

# Vim customisations
_link_and_backup ".vimrc"
_link_and_backup ".vim"
$DOTFILES_DIR/.vim/install.sh


echo ""
echo "======================================================================="
echo "Installation complete"
echo "======================================================================="
