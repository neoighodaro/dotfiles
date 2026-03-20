#!/bin/bash

if [[ -f "/usr/local/bin/lazygit" ]]; then
    echo -e "${GRAY}===> Lazygit is already installed. Skipping...${NC}"
else
    # Get the latest version
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')

    # Determine the architecture
    ARCH=$(uname -m)
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')

    if [[ $ARCH == "x86_64" ]]; then
        ARCH="x86_64"
    elif [[ $ARCH == "arm64" ]] || [[ $ARCH == "aarch64" ]]; then
        ARCH="arm64"
    elif [[ $ARCH == "armv6" ]]; then
        ARCH="armv6"
    elif [[ $ARCH == "i386" ]] || [[ $ARCH == "i686" ]]; then
        ARCH="32-bit"
    else
        echo -e "${RED}Unsupported architecture: ${ARCH}${NC}"
        exit 1
    fi

    # Construct download URL
    FILENAME="lazygit_${LAZYGIT_VERSION}_${OS}_${ARCH}.tar.gz"
    DOWNLOAD_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/${FILENAME}"

    # Download the Lazygit binary
    curl -Lo lazygit.tar.gz "${DOWNLOAD_URL}"

    # Unzip
    tar xf lazygit.tar.gz lazygit

    # Install
    sudo install lazygit -D -t /usr/local/bin/

    # Remove
    rm lazygit.tar.gz

    echo -e "${GREEN}==> Lazygit installed.${NC}"
fi
