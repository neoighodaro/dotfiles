if [[ -f "$HOME/.dotfiles/.zshrc_custom" ]]; then
    source $HOME/.dotfiles/.zshrc_custom
fi

if [[ -f "$HOME/.dotfiles/private.sh" ]]; then
    source $HOME/.dotfiles/private.sh
fi

if [[ -f "$HOME/.dotfiles/aliases.sh" ]]; then
    source $HOME/.dotfiles/aliases.sh
fi

if [[ -f "$HOME/.dotfiles/functions.sh" ]]; then
    source $HOME/.dotfiles/functions.sh
fi
