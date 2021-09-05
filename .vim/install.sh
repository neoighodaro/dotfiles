#!/bin/bash
CURR_DIR=$(cd `dirname $0` && pwd)

# Install Theme(s)
if [[ ! -f "${CURR_DIR}/colors/atom-dark-256.vim" ]]; then
    git clone https://github.com/gosukiwi/vim-atom-dark.git "${CURR_DIR}/colors/temp_theme"
    mv "${CURR_DIR}/colors/temp_theme/colors/atom-dark-256.vim" "${CURR_DIR}/colors/atom-dark-256.vim"
    sudo rm -R "${CURR_DIR}/colors/temp_theme"
fi

# Install VundleVim
if [[ ! -d "${CURR_DIR}/bundle/Vundle.vim" ]]; then
    git clone https://github.com/VundleVim/Vundle.vim.git "${CURR_DIR}/bundle/Vundle.vim"
    vim +PluginInstall +qall
fi
