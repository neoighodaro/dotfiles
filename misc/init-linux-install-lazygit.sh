#!/bin/bash

if [[ -f "/usr/local/bin/lazygit" ]]; then
    echo -e "${GRAY}===> Lazygit is already installed. Skipping...${NC}"
    exit 0
fi

# get latest version
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')

# download...
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"

# Unzip
tar xf lazygit.tar.gz lazygit

# Install
sudo install lazygit -D -t /usr/local/bin/

# Remove
rm lazygit.tar.gz

echo -e "${GREEN}==> Lazygit installed.${NC}"
