#!/bin/bash

# Function to check if a package is installed
install_apt_package() {
    local package_name=$1
    if ! dpkg -s $package_name > /dev/null 2>&1; then
        sudo apt-get install -y $package_name
        echo -e "===> ${GREEN}Installed $package_name${NC}"
    else
        echo -e "===> ${GRAY}Already installed $package_name. Skipping...${NC}"
    fi
}


# ---------------------------------------------------------------------------------------------------
# Install Packages
# ---------------------------------------------------------------------------------------------------

install_apt_package trash-cli
install_apt_package fzf
