#!/bin/bash
mv ~/.zshrc ~/.zshrc.bak
cd ..
mv dotfiles ~/.dotfiles
ln -fs ~/.zshrc ~/.dotfiles/.zshrc
