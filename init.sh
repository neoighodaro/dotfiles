#!/bin/bash

set -e

# Variables
# ----------------------------------------------------------------------------------------
## Directories
DOTFILES_DIR="$HOME/Developer/dotfiles"
NVM_VERSION="v0.40.1"

## Colors
WHITE="\033[1;37m"
GRAY="\033[0;90m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
INDIGO="\033[0;94m"
RED="\033[0;31m"
NC="\033[0m"

## OS checks
IS_MACOS=$(uname -s | grep -i "darwin" | wc -l | tr -d '[:space:]')
IS_LINUX=$(uname -s | grep -i "linux" | wc -l | tr -d '[:space:]')


# Safety checks
# ----------------------------------------------------------------------------------------
## Prevent running script as root...
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}===> Please don't run as root.${NC}"
  exit 1
fi

## Make sure ZSH is installed
if [[ ! -f "/bin/zsh" ]]; then
    if [[ $IS_LINUX -eq 1 ]]; then
        echo -e "${YELLOW}===> Installing ZSH...${NC}"
        sudo apt install zsh
        chsh -s $(which zsh)
    else
        echo -e "${RED}===> ZSH is not installed. Please install ZSH first.${NC}"
        exit 1
    fi
fi


# Helper functions
# ----------------------------------------------------------------------------------------
## Link and backup files
link_and_backup() {
    local SKIP_LINKING=0
    local DEFAULT_FILE="$HOME/${2:-$1}"
    local LINK_FILE="$DOTFILES_DIR/$1"

    if [ ! -f "$LINK_FILE" ] && [ ! -d "$LINK_FILE" ]; then
        echo -e "${RED}==> $LINK_FILE does not exist. Skipping!${NC}"
        return
    fi

    if [[ "$LINK_FILE" == "$DOTFILES_DIR/.gitignore.work" ]] && [ ! -f "$LINK_FILE" ]; then
        touch "$LINK_FILE"
        echo -e "${GREEN}==> Created empty file for $LINK_FILE.${NC}"
    fi

    if [ -f "$DEFAULT_FILE" ] && [ ! -L "$DEFAULT_FILE" ]; then
        mv "$DEFAULT_FILE" "$DEFAULT_FILE.backup"
        echo -e "${GREEN}==> Created backup for $DEFAULT_FILE.${NC}"
    else
        if [[ -L $DEFAULT_FILE ]] && [[ $LINK_FILE == $(readlink "$DEFAULT_FILE") ]]; then
            SKIP_LINKING=1
        elif [[ -f "$DEFAULT_FILE" ]]; then
            mv "$DEFAULT_FILE" "$DEFAULT_FILE.bak"
            echo -e "${GREEN}==> Created backup for $DEFAULT_FILE.${NC}"
        fi
    fi

    if [[ $SKIP_LINKING -eq 0 ]]; then
        ln -s "$LINK_FILE" "$DEFAULT_FILE"
        echo -e "${GREEN}==> Created symlink for $DEFAULT_FILE from $LINK_FILE.${NC}"
    else
        DEFAULT_FILE_BASENAME=$(basename "$DEFAULT_FILE")
        echo -e "${GRAY}==> Symlink already exists for $DEFAULT_FILE_BASENAME. Skipping!${NC}"
    fi
}


# Begin Script
# ---------------------------------------------------------------------------------------------------

cd $HOME
echo -e "${WHITE}==> Initializing...${NC}"


# Prepare & link dotfiles
# ---------------------------------------------------------------------------------------------------
## Make necessary directories
mkdir -p ~/.config ~/.config/lazygit

## Link the dotfiles...
link_and_backup "zellij" ".config/zellij"
link_and_backup "zsh/zshrc.sh" ".zshrc"
link_and_backup "zsh/aliases.sh" ".zshrc_aliases"
link_and_backup "zsh/functions.sh" ".zshrc_functions"
link_and_backup "zsh/paths.sh" ".zshrc_paths"
link_and_backup "zsh/private.sh" ".zshrc_scripts"
link_and_backup "starship/starship.toml" ".config/starship.toml"
link_and_backup "configs/curlrc" ".curlrc"
link_and_backup "configs/hushlogin" ".hushlogin"
link_and_backup "configs/wgetrc" ".wgetrc"
link_and_backup "configs/screenrc" ".screenrc"
link_and_backup "lazygit/lazygit.yml" ".config/lazygit/config.yml"
link_and_backup "git/global-gitignore" ".global-gitignore"
link_and_backup "git/githooks" ".githooks"
link_and_backup "git/base.cfg" ".gitconfig"
[[ $IS_LINUX -eq 1 ]] && link_and_backup "git/linux.cfg" ".gitconfig.extended"
[[ $IS_MACOS -eq 1 ]] && link_and_backup "git/mac.cfg" ".gitconfig.extended"
[[ $IS_MACOS -eq 1 ]] && link_and_backup "configs/mackup.cfg" ".mackup.cfg"
[[ -f "$DOTFILES_DIR/git/private.cfg" ]] && link_and_backup "git/private.cfg" ".gitconfig.private"
[[ -f "$DOTFILES_DIR/git/personal.cfg" ]] && link_and_backup "git/personal.cfg" ".gitconfig.personal"
[[ -f "$DOTFILES_DIR/git/work.cfg" ]] && link_and_backup "git/work.cfg" ".gitconfig.work"


# Install NVM
# ---------------------------------------------------------------------------------------------------
if [ -f "$NVM_DIR/nvm.sh" ]; then
    echo -e "${GRAY}==> NVM is already installed. Skipping...${NC}"
else
    echo -e "${WHITE}==> Installing NVM...${NC}"
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
fi


# Run platform specific scripts...
# ------------------------------------------------------------------------------
if [[ $IS_MACOS -eq 1 ]]; then
    export HOMEBREW_CASK_OPTS="--appdir=/Applications"
    source "$DOTFILES_DIR/init-mac.sh"
elif [[ $IS_LINUX -eq 1 ]]; then
    source "$DOTFILES_DIR/init-linux.sh"
fi

# Generate SSH Keys
# ------------------------------------------------------------------------------
SSH_CHECK_RUN_FILE="/tmp/dotfiles__ssh-skip-check"
if [[ ! -f "$HOME/.ssh/id_ed25519.pub" ]] && [[ ! -f "$SSH_CHECK_RUN_FILE" ]]; then
    touch "$SSH_CHECK_RUN_FILE"
    echo -e "${WHITE}==> Would you like to generate an SSH key? [y/N]${NC}"
    read -r answer

    if [[ $answer == "y" || $answer == "Y" ]]; then
        echo -e "${WHITE}==> Generating SSH key...${NC}"
        ssh-keygen -t ed25519 -C "public@neoi.sh" -f $HOME/.ssh/id_ed25519
    else
        echo -e "${WHITE}==> Skipping SSH key generation...${NC}"
    fi
fi

## Additional set up for SSH
if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
    link_and_backup "ssh/ssh-config" ".ssh/config"
    link_and_backup "ssh/config.d" ".ssh/config.d"
fi

## Add SSH key to keychain
if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
    [[ $IS_MACOS -eq 1 ]] && ssh-add -K ~/.ssh/id_ed25519 > /dev/null 2>&1
    [[ $IS_LINUX -eq 1 ]] && ssh-add -k ~/.ssh/id_ed25519 > /dev/null 2>&1
fi


# Generate GPG key
# ------------------------------------------------------------------------------
GPG_CHECK_RUN_FILE="/tmp/dotfiles__gpg-skip-check"
if [[ -z "$(gpg --list-keys 2>/dev/null)" ]] && [[ ! -f "$GPG_CHECK_RUN_FILE" ]]; then
    touch "$GPG_CHECK_RUN_FILE"
    echo -e "${WHITE}==> Would you like to generate a GPG key? [y/N]${NC}"
    read -r answer

    if [[ $answer == "y" || $answer == "Y" ]]; then
        echo -e "${WHITE}==> Generating GPG key...${NC}"
        gpg --full-generate-key
    else
        echo -e "${WHITE}==> Skipping GPG key generation...${NC}"
    fi
fi

# Vim customisations...
# if [[ -f "/usr/bin/vim" ]]; then
#     _link_and_backup ".vimrc"
#     _link_and_backup ".vim"
#     $DOTFILES_DIR/.vim/install.sh
# else
#     echo -e "${YELLOW}===> Vim is not installed. Skipping.${NC}"
# fi

echo -e "${GREEN}==> Initialization complete.${NC}"
