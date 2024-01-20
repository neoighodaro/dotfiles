#!/bin/bash

#SCRIPT_DIR=$(cd `dirname $0` && pwd)
DOTFILES_DIR="$HOME/.dotfiles"

set -e

WHITE="\033[1;37m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m"

IS_MACOS=$(uname -s | grep -i "darwin" | wc -l | tr -d '[:space:]')
IS_LINUX=$(uname -s | grep -i "linux" | wc -l | tr -d '[:space:]')

# ------------------------------------------------------------------------------------------
# Check if zsh is installed
# ------------------------------------------------------------------------------------------

if [[ -z $(which git) ]]; then
    echo -e "${RED}===> Git is not installed. Please install git first.${NC}"
    exit 1
fi

if [[ ! -f "/bin/zsh" ]]; then
    echo -e "${RED}===> Zsh is not installed. Please install zsh first.${NC}"
    exit 1
fi

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo -e "${YELLOW}===> Oh-my-zsh is not installed. Would you like to install it? (y/n)${NC}"
    read -p "" -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${WHITE}===> Installing Oh-my-zsh...${NC}"
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
        echo -e "${GREEN}===> Oh-my-zsh installed.${NC}"
    else
        echo -e "${RED}===> Oh-my-zsh is required. Please install it first.${NC}"
        exit 1
    fi
fi

# ------------------------------------------------------------------------------------------
# Install zsh specific packages
# ------------------------------------------------------------------------------------------

if [[ ! -d "$HOME/.zsh/pure" ]]; then
    echo -e "${WHITE}===> Do you want to install Pure? (y/n) ${NC}"
    read -p "" -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p "$HOME/.zsh"
        git clone https://github.com/sindresorhus/pure.git "$HOME/.zsh/pure"
        echo "fpath+=($HOME/.zsh/pure)" >> "$DOTFILES_DIR/.zsh_postload.sh"
        echo -e "${GREEN}===> Pure installed.${NC}"
    fi
fi

if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    echo -e "${GREEN}===> zsh-autosuggestions installed.${NC}"
fi

if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    echo -e "${GREEN}===> zsh-syntax-highlighting installed.${NC}"
fi

if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-z ]]; then
    git clone https://github.com/agkozak/zsh-z ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-z
    echo -e "${GREEN}===> zsh-z installed.${NC}"
fi

if [[ $IS_LINUX -eq 1 ]]; then
    if [[ -z $(which trash) ]]; then
        echo -e "${WHITE}===> Do you want to install trash-cli? (y/n) ${NC}"
        read -p "" -n 1 -r
        echo ""

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo apt-get install trash-cli
            echo -e "${GREEN}===> Installed trash.${NC}"
        else
            echo -e "${YELLOW}===> Removing rm to trash alias for Linux.${NC}"
            echo "alias rm='rm'" | sudo tee -a ~/.dotfiles/.zsh_private.sh
            echo -e "${GREEN}===> Removed rm to trash alias for Linux.${NC}"
        fi
    fi
fi

if [[ $IS_MACOS -eq 1 ]]; then
    if [[ -z $(which trash) ]]; then
        echo -e "${WHITE}===> Do you want to install trash? (y/n) ${NC}"
        read -p "" -n 1 -r
        echo ""

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            brew install trash
            echo -e "${GREEN}===> Installed trash.${NC}"
        fi
    fi
fi



# ------------------------------------------------------------------------------------------
# Link and Back up Helper
# ------------------------------------------------------------------------------------------

_link_and_backup() {
    SKIP_LINKING=0
    DEFAULT_FILE="$HOME/${2:-$1}"
    LINK_FILE="$DOTFILES_DIR/$1"

    if [ ! -f "$LINK_FILE" ] && [ ! -d "$LINK_FILE" ]; then
        echo -e "${RED}===> $LINK_FILE does not exist. Skipping!${NC}"
        return
    fi

    if [[ "$LINK_FILE" == "$DOTFILES_DIR/.gitignore.work" ]] && [ ! -f "$LINK_FILE" ]; then
        touch "$LINK_FILE"
        echo -e "${GREEN}===> Created empty file for $LINK_FILE.${NC}"
    fi

    if [ -f "$DEFAULT_FILE" ] && [ ! -L "$DEFAULT_FILE" ]; then
        mv "$DEFAULT_FILE" "$DEFAULT_FILE.backup"
        echo -e "${GREEN}===> Created backup for $DEFAULT_FILE.${NC}"
    else
        if [[ -L $DEFAULT_FILE ]] && [[ $LINK_FILE == $(readlink "$DEFAULT_FILE") ]]; then
            SKIP_LINKING=1
        elif [[ -f "$DEFAULT_FILE" ]]; then
            mv "$DEFAULT_FILE" "$DEFAULT_FILE.backup"
            echo -e "${GREEN}===> Created backup for $DEFAULT_FILE.${NC}"
        fi
    fi

    if [[ $SKIP_LINKING -eq 0 ]]; then
        ln -s "$LINK_FILE" "$DEFAULT_FILE"
        echo -e "${GREEN}===> Created symlink for $DEFAULT_FILE from $LINK_FILE.${NC}"
    else
        DEFAULT_FILE_BASENAME=$(basename "$DEFAULT_FILE")
        echo -e "${YELLOW}===> Symlink already exists for $DEFAULT_FILE_BASENAME. Skipping!${NC}"
    fi
}


# ------------------------------------------------------------------------------------------
# Begin Script
# ------------------------------------------------------------------------------------------

echo -e "${WHITE}===> Beginning installation...${NC}"

cd $HOME

# Move the dotfiles directory to the HOME path if necessary...
#[[ ! -d $DOTFILES_DIR ]] && mv $SCRIPT_DIR $DOTFILES_DIR

GITCONFIG_OS_FILE=""
if [[ $IS_LINUX -eq 1 ]]; then
    GITCONFIG_OS_FILE=".gitcfg/.gitconfig-linux"
elif [[ $IS_MACOS -eq 1 ]]; then
    GITCONFIG_OS_FILE=".gitcfg/.gitconfig-macos"
fi

_link_and_backup ".curlrc"
_link_and_backup ".zshrc"
_link_and_backup ".wgetrc"
_link_and_backup ".hushlogin"
_link_and_backup ".screenrc"
_link_and_backup ".githooks"
_link_and_backup "$GITCONFIG_OS_FILE" ".gitconfig"
_link_and_backup ".gitconfig.work"

if [[ IS_MACOS -eq 1 ]]; then
    _link_and_backup ".mackup.cfg"
fi

# remove gitconfig if it exists and symlink the file to .gitcfg/.gitconfig-linux or .gitconfig-macos depending on the OS
# if [[ -f "$HOME/.gitconfig" ]]; then
#     if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
#         mv "$HOME/.gitconfig" "$HOME/.gitconfig.backup"
#     else if [[ $(readlink "$HOME/.gitconfig") != "$GITCONFIG_OS_FILE" ]]; then
#         mv "$HOME/.gitconfig" "$HOME/.gitconfig.backup"
#         echo -e "${GREEN}===> Gitconfig backup created.${NC}"
#     fi
# fi

# if [[ $(readlink "$HOME/.gitconfig") == "$GITCONFIG_OS_FILE" ]]; then
#     echo -e "${YELLOW}===> Gitconfig symlink already exists. Skipping!${NC}"
# else
#     ln -s "$DOTFILES_DIR/$GITCONFIG_OS_FILE" "$HOME/.gitconfig"
#     echo -e "${GREEN}===> Gitconfig symlinked.${NC}"
# fi

# Vim customisations if vim is installed
if [[ -f "/usr/bin/vim" ]]; then
    _link_and_backup ".vimrc"
    _link_and_backup ".vim"
    $DOTFILES_DIR/.vim/install.sh
else
    echo -e "${YELLOW}===> Vim is not installed. Skipping vim customisations.${NC}"
fi

echo -e "${GREEN}===> Installation complete. Restart your shell.${NC}"
