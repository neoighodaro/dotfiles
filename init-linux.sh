#!/bin/bash

# Helper functions
# ------------------------------------------------------------------------------
##  Install an apt package if not installed
install_apt_package() {
    local package_name=$1
    if ! dpkg -s $package_name > /dev/null 2>&1; then
        sudo apt-get install -y $package_name
        echo -e "===> ${GREEN}Installed $package_name${NC}"
    else
        echo -e "===> ${GRAY}Already installed $package_name. Skipping...${NC}"
    fi
}


# Linux Settings
# ------------------------------------------------------------------------------
echo -e "${WHITE}==> Configuring Linux...${NC}"

## Locale
if grep -q "en_US.UTF-8" /etc/locale.gen; then
    echo -e "${GRAY}==> Locale already set. Skipping...${NC}"
else
    echo -e "${WHITE}==> Setting locale...${NC}"
    export LC_ALL="en_US.UTF-8"
    sudo locale-gen "en_US.UTF-8"
    sudo dpkg-reconfigure locales
    echo -e "${GREEN}==> Locale set.${NC}"
fi

# SSH
# ---------------------------------------------------------------------------------------------------
CONFIGURED_AT_LEAST_ONCE=false
if grep -q "UsePAM yes" /etc/ssh/sshd_config; then
    CONFIGURED_AT_LEAST_ONCE=true
    sudo sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
fi

if grep -q "PermitRootLogin yes" /etc/ssh/sshd_config; then
    CONFIGURED_AT_LEAST_ONCE=true
    sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
fi

if grep -q "PasswordAuthentication yes" /etc/ssh/sshd_config; then
    CONFIGURED_AT_LEAST_ONCE=true
    sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
fi

if [ "$CONFIGURED_AT_LEAST_ONCE" = true ]; then
    echo -e "${WHITE}==> Configuring SSH...${NC}"
    sudo systemctl restart ssh
    echo -e "${GREEN}==> Configured SSH.${NC}"
else
    echo -e "${GRAY}==> SSH is already configured. Skipping...${NC}"
fi


# Swap Memory
# ---------------------------------------------------------------------------------------------------
SWAP_FILE_ALREADY_ALLOCATED=$(free | awk '/^Swap:/ {exit !$2}' && echo 1 || echo 0)
if [[ "$SWAP_FILE_ALREADY_ALLOCATED" -eq 0 ]]; then
    echo -e "${WHITE}==> Allocating swap file...${NC}"
    SWAPSIZE=0
    RAMSIZE=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    RAMSIZE_GB=$((RAMSIZE / 1024 / 1024))

    if [ $RAMSIZE_GB -ge 2 ] && [ $RAMSIZE_GB -lt 32 ]; then
        SWAPSIZE=$((RAMSIZE_GB / 2))
    elif [ $RAMSIZE_GB -ge 32 ]; then
        SWAPSIZE=$((RAMSIZE_GB / 4))
    fi

    if [ $SWAPSIZE -gt 0 ]; then
        echo -e "${WHITE}==> Creating swap file with size ${SWAPSIZE}GB. Do you want to proceed? [y/N]${NC}"
        read -r answer
        if [[ $answer == "y" || $answer == "Y" ]]; then
            sudo fallocate -l ${SWAPSIZE}G /swapfile
            sudo chmod 600 /swapfile
            sudo mkswap /swapfile
            sudo swapon /swapfile
            sudo echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
            echo -e "${GREEN}==> Created swap file.${NC}"
        else
            echo -e "${RED}===> Not creating swap file. Skipping...${NC}"
        fi
    else
        echo -e "${RED}===> Not enough RAM to create swap file. Skipping...${NC}"
    fi
else
    echo -e "${GRAY}==> Swap file already allocated. Skipping...${NC}"
fi

echo -e "${GREEN}==> Linux settings updated.${NC}"


# Install Packages
# ---------------------------------------------------------------------------------------------------
install_apt_package gnupg
install_apt_package zsh-autosuggestions
install_apt_package zsh-syntax-highlighting
install_apt_package eza
install_apt_package bat
install_apt_package zoxide
install_apt_package fzf
install_apt_package unzip
source "$DOTFILES_DIR/misc/init-linux-install-zellij.sh"          # Zellij
source "$DOTFILES_DIR/misc/init-linux-install-lazygit.sh"         # Lazygit
install_apt_package git-delta

## Starship
if ! command -v starship &> /dev/null; then
    echo -e "${WHITE}==> Installing Starship...${NC}"
    curl -sS https://starship.rs/install.sh | sh
    echo -e "${GREEN}==> Installed Starship.${NC}"
else
    echo -e "${GRAY}==> Already installed Starship. Skipping...${NC}"
fi

## Deno
if [ ! -s "$HOME.deno/env" ]; then
    echo -e "${WHITE}==> Installing Deno...${NC}"
    curl -fsSL https://deno.land/x/install/install.sh | sh        # Deno
    echo -e "${GREEN}==> Installed Deno.${NC}"
else
    echo -e "${GRAY}==> Already installed Deno. Skipping...${NC}"
fi


# Caveat for GPG
# ------------------------------------------------------------------------------
if [[ ! -f "$HOME/.gnupg/gpg-agent.conf" ]]; then
    mkdir -p "$HOME/.gnupg" && touch "$HOME/.gnupg/gpg-agent.conf"
    sudo chown -R $(whoami) "$HOME/.gnupg"
    sudo find "$HOME/.gnupg" -type d -exec chmod 700 {} \;
    sudo find "$HOME/.gnupg" -type f -exec chmod 600 {} \;
fi
