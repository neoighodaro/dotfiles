#!/bin/bash

# Function to check if a cask app is installed, and install it if not
install_cask_app() {
  local app_name=$1
  if ! brew list --cask | grep -q "$app_name"; then
    echo -e "$app_name not found. Installing..."
    brew install --cask "$app_name"
    echo -e "${GREEN}==> Installed $app_name.${NC}"
  else
    echo -e "${GRAY}==> $app_name is already installed. Skipping...${NC}"
  fi
}

# Function to check if a brew package is installed, and install it if not
install_brew_package() {
  local package_name=$1
  if ! brew list --formula | grep -q "$package_name"; then
    echo -e "${YELLOW}==> $package_name not found. Installing...${NC}"
    brew install "$package_name"
    echo -e "${GREEN}==> Installed $package_name.${NC}"
  else
    echo -e "${GRAY}==> $package_name is already installed. Skipping...${NC}"
  fi
}


create_mac_directories() {
    local CREATE_DIRS=(
        "$HOME/Developer"
        "$HOME/Downloads/• Trashable"
        "$HOME/Downloads/• Keep"
        "$HOME/Documents/• Screenshots"
        "$HOME/Documents/• Unsorted"
    )
    for dir in "${CREATE_DIRS[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo -e "${GREEN}==> Created $dir directory.${NC}"
        fi
    done
}

create_mac_directories

# Install Homebrew if not installed
if ! command -v brew &> /dev/null; then
  echo -e "${WHITE}==> Homebrew not found. Installing...${NC}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo >> "$HOME/.zprofile"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  brew analytics off
  echo -e "${GREEN}==> Homebrew installed.${NC}"
else
  echo -e "${WHITE}==> Homebrew is already installed. Updating...${NC}"
  brew update
  echo -e "${GREEN}==> Homebrew updated.${NC}"
fi


# ---------------------------------------------------------------------------------------------------
# Mac Settings
# Sources:
#   - https://macos-defaults.com/finder/fxpreferredviewstyle.html
#   - https://github.com/kevinSuttle/macOS-Defaults/blob/master/.macos
#   - https://mosen.github.io/profiledocs/payloads/mac/dock.html#com.apple.dock-minimize-to-application-auto
# ---------------------------------------------------------------------------------------------------

echo -e "${WHITE}==> Configuring Mac Settings...${NC}"

# Dock
defaults write com.apple.dock persistent-apps -array                               # Keep apps open when dock is hidden
defaults write com.apple.dock minimize-to-application -bool true                   # Minimize windows into application icon
defaults write com.apple.dock magnification -bool false                            # Magnify icons when hovering over them
defaults write com.apple.dock mineffect -string scale                              # Minimizing windows effect
defaults write com.apple.dock autohide -bool true                                  # Automatically hide and show the dock
defaults write com.apple.dock autohide-delay -float 0                              # Delay before auto-hiding or showing the dock
defaults write com.apple.dock autohide-time-modifier -float 0                      # Time modifier for auto-hiding or showing the dock
defaults write com.apple.dock launchanim -bool false                               # Animate opening applications
defaults write com.apple.dock tilesize -int 47                                     # Set size of the dock
defaults write com.apple.dock wvous-bl-corner -int 4                               # Hot-corner: bottom-left screen corner → Desktop
defaults write com.apple.dock wvous-bl-modifier -int 0                             # Hot-corner: bottom-left screen corner → Desktop

# Finder
defaults write com.apple.finder EmptyTrashSecurely -bool true                      # Empty Trash securely
defaults write com.apple.finder WarnOnEmptyTrash -bool false                       # Warn before emptying the Trash
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false         # Show warning when changing extensions
defaults write com.apple.finder ShowStatusBar -bool true                           # Show status bar
defaults write com.apple.finder QuitMenuItem -bool true                            # Show Quit menu item
defaults write com.apple.finder QLEnableTextSelection -bool true                   # Allow text selection in Quick Look
defaults write com.apple.finder "FXPreferredViewStyle" -string "clmv"              # Show columns view in Finder
defaults write com.apple.finder "_FXSortFoldersFirst" -bool true                   # Sort folders first
defaults write com.apple.finder ShowRecentTags -bool false                         # Hide recent tags
defaults write com.apple.Finder SidebarTagsSctionDisclosedState -bool false        # Don't show the sidebar tags section
defaults write com.apple.Finder SidebarDevicesSectionDisclosedState -bool false    # Don't show the sidebar devices section
defaults write com.apple.finder NewWindowTarget -string "PfDo"                     # Open new finder to documents folder

# Global Domain
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false     # Disable automatic correction
defaults write NSGlobalDomain AppleShowAllExtensions -bool true                    # Show all file extensions
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true        # Expand save panel by default

# Others
defaults write com.apple.menuextra.battery ShowTime -string "YES"                  # Show battery time remaining
defaults write com.apple.screensaver askForPassword -int 1                         # Require password immediately when screensaver activates
defaults write com.apple.screensaver askForPasswordDelay -int 0                    # Require password immediately when screensaver activates
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true       # Avoid creating .DS_Store files on network volumes
defaults write com.apple.screencapture location -string "$HOME/Documents/• Screenshots" # Set location for screenshots

chflags nohidden ~/Library                                                         # Show the ~/Library folder
source "$DOTFILES_DIR/misc/init-mac-app-in-dock.sh"                                # Add applications folder to the dock

# Enable snap-to-grid for desktop icons
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist

# Set wallpaper
for ext in heic jpg png; do
  wallpaper="$HOME/Pictures/wallpaper.$ext"
  [ -f "$wallpaper" ] && osascript -e "tell application \"System Events\" to set picture of every desktop to POSIX file \"$wallpaper\"" && break
done

# Kill affected applications
APPS=(Finder Dock SystemUIServer cfprefsd)
for APP in "${APPS[@]}"; do
    killall "$APP" &>/dev/null
done

echo -e "${GREEN}==> Mac settings updated.${NC}"

# ---------------------------------------------------------------------------------------------------
# Install Packages
# ---------------------------------------------------------------------------------------------------

brew tap jorgelbg/tap                                                          # Tap jorgelbg/tap

install_brew_package trash
install_brew_package gnupg
install_brew_package pinentry-mac
install_brew_package pinentry-touchid
install_brew_package zsh-autosuggestions
install_brew_package zsh-syntax-highlighting
install_brew_package starship
install_brew_package eza
install_brew_package bat
install_brew_package zoxide
install_brew_package fzf
install_brew_package zellij
install_brew_package lazygit

# Set the default browser and remove the default browser package
if [[ ! -f "/tmp/default-browser-installed" ]]; then
    install_brew_package defaultbrowser
    defaultbrowser browser
    brew uninstall defaultbrowser
    touch /tmp/default-browser-installed
fi

# Caveat for GPG
if [[ ! -f "$HOME/.gnupg/gpg-agent.conf" ]]; then
    mkdir -p "$HOME/.gnupg" && touch "$HOME/.gnupg/gpg-agent.conf"
    sudo chown -R $(whoami) "$HOME/.gnupg"
    sudo find "$HOME/.gnupg" -type d -exec chmod 700 {} \;
    sudo find "$HOME/.gnupg" -type f -exec chmod 600 {} \;
fi

# Caveat for pinentry-touchid
grep -Fxq "pinentry-program $(which pinentry-touchid)" "$HOME/.gnupg/gpg-agent.conf" || \
    echo "pinentry-program $(which pinentry-touchid)" >> "$HOME/.gnupg/gpg-agent.conf"                     # Fix pinentry-touchid
pinentry-touchid -fix > /dev/null 2>&1                                                                     # Fix pinentry-touchid
gpg-connect-agent reloadagent /bye > /dev/null 2>&1                                                        # Reload gpg-agent
defaults write org.gpgtools.common DisableKeychain -bool yes                                               # Disable saving to keychain

# ---------------------------------------------------------------------------------------------------
# Apps & their config
# ---------------------------------------------------------------------------------------------------

# Wezterm config
link_and_backup "wezterm/.config/wezterm/wezterm.lua" .wezterm.lua

# Install Needed Apps using Homebrew Cask
install_cask_app wezterm
install_cask_app 1password
install_cask_app font-jetbrains-mono-nerd-font
install_cask_app arc
install_cask_app docker
install_cask_app visual-studio-code
install_cask_app phpstorm
install_cask_app hazel
install_cask_app jordanbaird-ice
install_cask_app herd

# @todo: Disable spotlight and get alternative
# sudo mdutil -a -i off
# @todo: https://github.com/yihou/alfred-zoxide
