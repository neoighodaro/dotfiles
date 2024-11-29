#!/bin/bash

# Helper functions
# ------------------------------------------------------------------------------
## Check if an app is running
is_app_running() {
    local app_name=$1
    ps aux | grep -v grep | grep -q "$app_name"
}

## Install an app from the cask if not installed
install_cask_app() {
  local app_name=$1
  local install_url=$2
  if ! brew list --cask | grep -q "$app_name"; then
    echo -e "$app_name not found. Installing..."

    # if url use that else use app name
    if [[ -n $install_url ]]; then
      curl -O "$install_url"
      brew install --cask "$(basename $install_url)"
      rm "$(basename $install_url)"
    else
      brew install --cask "$app_name"
    fi

    echo -e "${GREEN}==> Installed $app_name.${NC}"
  else
    echo -e "${GRAY}==> $app_name is already installed. Skipping...${NC}"
  fi
}

## Install an app from the App Store if not installed
install_appstore_app() {
  local app_name=$1
  local app_id=$2
  if ! /usr/bin/open -a "$app_name"; then
    echo -e "$app_name not found. Installing..."
    /usr/bin/open https://apps.apple.com/us/app/"$app_id"
  else
    echo -e "${GRAY}==> $app_name is already installed. Skipping...${NC}"
  fi
}

## Install a brew package if not installed
install_brew_package() {
  local package_name=$1
  local package_tap=$2
  local full_package_name=$([[ -z "$package_tap" ]] && echo "$package_name" || echo "$package_tap/$package_name")
  if ! brew list --formula | grep -q "$package_name"; then
    echo -e "${YELLOW}==> $full_package_name not found. Installing...${NC}"
    brew install "$full_package_name"
    echo -e "${GREEN}==> Installed $package_name.${NC}"
  else
    echo -e "${GRAY}==> $package_name is already installed. Skipping...${NC}"
  fi
}

## Create Mac specific directories
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

# Begin Script
# ------------------------------------------------------------------------------
## Create Mac specific directories
create_mac_directories

## Install Homebrew if not installed
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

# Mac Settings
# ------------------------------------------------------------------------------
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
defaults write com.apple.dock autohide-delay -float 1                              # Delay before auto-hiding or showing the dock
defaults write com.apple.dock autohide-time-modifier -float 0                      # Time modifier for auto-hiding or showing the dock
defaults write com.apple.dock launchanim -bool false                               # Animate opening applications
defaults write com.apple.dock tilesize -int 37                                     # Set size of the dock
defaults write com.apple.dock wvous-bl-corner -int 4                               # Hot-corner: bottom-left screen corner → Desktop
defaults write com.apple.dock wvous-bl-modifier -int 0                             # Hot-corner: bottom-left screen corner → Desktop
defaults write com.apple.dock show-recents -int 0                                  # Hide recents
defaults write com.apple.dock expose-group-apps -int 1                             # Group windows by apps when using expose

# Finder
defaults write com.apple.finder EmptyTrashSecurely -bool true                      # Empty Trash securely
defaults write com.apple.finder WarnOnEmptyTrash -bool false                       # Warn before emptying the Trash
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false         # Show warning when changing extensions
defaults write com.apple.finder ShowPathbar -bool true                             # Show path bar
defaults write com.apple.finder ShowStatusBar -bool true                           # Hide status bar
defaults write com.apple.finder QuitMenuItem -bool true                            # Show Quit menu item
defaults write com.apple.finder QLEnableTextSelection -bool true                   # Allow text selection in Quick Look
defaults write com.apple.finder "FXPreferredViewStyle" -string "clmv"              # Show columns view in Finder
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"                # Search current folder by default
defaults write com.apple.finder "_FXSortFoldersFirst" -bool true                   # Sort folders first
defaults write com.apple.finder ShowRecentTags -bool false                         # Hide recent tags
defaults write com.apple.Finder SidebarTagsSctionDisclosedState -bool false        # Don't show the sidebar tags section
defaults write com.apple.Finder SidebarDevicesSectionDisclosedState -bool false    # Don't show the sidebar devices section
defaults write com.apple.finder NewWindowTarget -string "PfHm"                     # Open new finder to home folder
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false        # Hide external hard drives
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false            # Hide removable media
defaults write com.apple.finder FinderSpawnTab -int 1                              # Open folders in new tabs

# Global Domain
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false     # Disable automatic correction
defaults write NSGlobalDomain AppleShowAllExtensions -bool true                    # Show all file extensions
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true        # Expand save panel by default

# Window Manager (Deskop & Stage manager)
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false  # Disable standard click to show desktop
defaults write com.apple.WindowManager StandardHideDesktopIcons -bool true           # Disable showing items in desktop (Standard)
defaults write com.apple.WindowManager HideDesktop -bool true                        # Disable showing items in desktop (Stage manager)
defaults write com.apple.WindowManager StageManagerHideWidgets -bool true           # Disable showing widgets in desktop (Stage manager)
defaults write com.apple.WindowManager StandardHideWidgets -bool true               # Disable showing widgets in desktop (Normal)

# https://zameermanji.com/blog/2021/6/8/applying-com-apple-symbolichotkeys-changes-instantaneously/
defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 64 "
  <dict>
    <key>enabled</key><false/>
    <key>value</key><dict>
      <key>type</key><string>standard</string>
      <key>parameters</key>
      <array>
        <integer>32</integer>
        <integer>49</integer>
        <integer>1048576</integer>
      </array>
    </dict>
  </dict>
"
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

# Others
defaults write com.apple.menuextra.battery ShowTime -string "YES"                  # Show battery time remaining
defaults write com.apple.screensaver askForPassword -int 1                         # Require password immediately when screensaver activates
defaults write com.apple.screensaver askForPasswordDelay -int 0                    # Require password immediately when screensaver activates
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true       # Avoid creating .DS_Store files on network volumes
defaults write com.apple.screencapture location -string "$HOME/Documents/• Screenshots" # Set location for screenshots
defaults write com.apple.Siri StatusMenuVisible -int 0                            # Hide Siri status menu
defaults write com.apple.Siri VoiceTriggerUserEnabled -int 0                       # Disable Siri voice trigger
defaults write com.apple.Siri ConfirmSiriInvokedViaEitherCmdTwice -int 0           # Disable Siri confirmation
defaults write com.apple.HIToolbox AppleFnUsageType -int 0                         # Disable globe key
defaults write com.apple.HIToolbox AppleDictationAutoEnable -int 0                 # Disable globe key auto dictation
defaults write com.apple.TextInputMenu visible -bool false                         # Disable text input menu

chflags nohidden ~/Library                                                         # Show the ~/Library folder
source "$DOTFILES_DIR/misc/init-mac-app-in-dock.sh"                                # Add applications folder to the dock

# Enable snap-to-grid for desktop icons
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist


# Set wallpaper
for ext in heic jpg png; do
  wallpaper="$HOME/Pictures/wallpaper.$ext"
  dotfiles_wallpaper="$DOTFILES_DIR/wallpapers/wallpaper.$ext"
  [ -f "$dotfiles_wallpaper" ] && [ ! -f "$wallpaper" ] && link_and_backup "wallpapers/wallpaper.$ext" "Pictures/wallpaper.$ext"
  [ -f "$wallpaper" ] && osascript -e "tell application \"System Events\" to set picture of every desktop to POSIX file \"$wallpaper\"" && break
done

# Kill affected applications
APPS=(Finder Dock SystemUIServer WindowManager cfprefsd)
for APP in "${APPS[@]}"; do
    killall "$APP" &>/dev/null
done

echo -e "${GREEN}==> Mac settings updated.${NC}"


# Install Packages
# ---------------------------------------------------------------------------------------------------
install_brew_package trash
install_brew_package gnupg
install_brew_package pinentry-mac
install_brew_package pinentry-touchid jorgelbg/tap
install_brew_package zsh-autosuggestions
install_brew_package zsh-syntax-highlighting
install_brew_package starship
install_brew_package eza
install_brew_package bat
install_brew_package zoxide
install_brew_package fzf
install_brew_package zellij
install_brew_package lazygit
install_brew_package git-delta
install_brew_package deno
install_brew_package bun oven-sh/bun
install_brew_package folderify

# Caveat for GPG
# ------------------------------------------------------------------------------
if [[ ! -f "$HOME/.gnupg/gpg-agent.conf" ]]; then
    mkdir -p "$HOME/.gnupg" && touch "$HOME/.gnupg/gpg-agent.conf"
    sudo chown -R $(whoami) "$HOME/.gnupg"
    sudo find "$HOME/.gnupg" -type d -exec chmod 700 {} \;
    sudo find "$HOME/.gnupg" -type f -exec chmod 600 {} \;
fi

# Caveat for pinentry-touchid
# ------------------------------------------------------------------------------
grep -Fxq "pinentry-program $(which pinentry-touchid)" "$HOME/.gnupg/gpg-agent.conf" || \
    echo "pinentry-program $(which pinentry-touchid)" >> "$HOME/.gnupg/gpg-agent.conf"                     # Fix pinentry-touchid
pinentry-touchid -fix > /dev/null 2>&1                                                                     # Fix pinentry-touchid
gpg-connect-agent reloadagent /bye > /dev/null 2>&1                                                        # Reload gpg-agent
defaults write org.gpgtools.common DisableKeychain -bool yes                                               # Disable saving to keychain


# Apps & their config
# ---------------------------------------------------------------------------------------------------
mkdir -p "$HOME/.config/aerospace"

## Link config files
link_and_backup "wezterm/wezterm.lua" .wezterm.lua                                              # Wezterm config
link_and_backup "aerospace/aerospace.toml" .config/aerospace/aerospace.toml                     # Aerospace config

## Tap some brew formulas
brew tap nikitabobko/tap

## Install Needed Apps using Homebrew Cask
install_cask_app wezterm
install_cask_app 1password
install_cask_app nordvpn
install_cask_app docker
install_cask_app arc
install_cask_app font-jetbrains-mono-nerd-font
install_cask_app visual-studio-code
install_cask_app phpstorm
install_cask_app hazel
install_cask_app jordanbaird-ice
install_cask_app herd
install_cask_app pika
install_cask_app raycast
install_cask_app aerospace
install_cask_app xbar
install_cask_app ray
install_cask_app boop
install_cask_app tableplus
install_cask_app coderunner
install_cask_app sensei
install_cask_app postman
install_cask_app tinkerwell
install_cask_app ray
install_cask_app gitkraken
install_cask_app sketch https://raw.githubusercontent.com/Homebrew/homebrew-cask/5c951dd3412c1ae1764924888f29058ed0991162/Casks/s/sketch.rb # Sketch 100.3
# install_cask_app mysides

## AppStore Apps
install_appstore_app "Dropover" "dropover/id1355679052" # DropOver

## Other Configs
mkdir -p "$HOME/Library/Application Support/xbar/plugins"
mkdir -p "$HOME/Library/Application Support/Code/User"
link_and_backup "xbar/dnsswitcher.sh" "Library/Application Support/xbar/plugins/dnsswitcher.sh" # Xbar plugin

## Ask if you want to customize VSCode
if [[ ! -f "/tmp/vscode-installed" ]]; then
    echo -e "${WHITE}==> Do you want to customize VSCode? [Y/n]${NC}"
    read -r answer
    if [[ $answer == "y" || $answer == "Y" ]]; then
        link_and_backup "vscode/keybindings.json" "Library/Application Support/Code/User/keybindings.json" # VSCode keybindings
        link_and_backup "vscode/settings.json" "Library/Application Support/Code/User/settings.json"       # VSCode config
        link_and_backup "vscode/custom.css" "Library/Application Support/Code/User/custom.css"             # VSCode custom CSS
        link_and_backup "vscode/custom.js" "Library/Application Support/Code/User/custom.js"               # VSCode custom JS
        echo -e "${GREEN}==> VSCode customization complete.${NC}"
    fi
    touch /tmp/vscode-installed
else
    echo -e "${GRAY}==> Skipping VSCode customization...${NC}"
fi

## Customize the CK folder
ck_dir="$HOME/Developer/ck"
if [[ ! -d "$ck_dir" ]]; then
    mkdir -p "$ck_dir"
    folderify --color-scheme dark "$DOTFILES_DIR/images/ck-mask.png" "$ck_dir"
fi

## Install Vivid
if [[ ! -d "/Applications/Vivid.app" ]]; then
    echo -e "${WHITE}==> Installing Vivid...${NC}"
    download_vivid_url="https://lumen-digital.com/apps/vivid/download_ref?ref=https://www.getvivid.app&_gl=1*ombh5l*_gcl_au*ODg0NDM4Mjg2LjE3MzE5MTcyMjE.*_ga*MTc3NDczMzM0MS4xNzMxOTE3MjIx*_ga_92N4EJGW2M*MTczMTkxNzIyMS4xLjAuMTczMTkxNzIyMS4wLjAuMA"
    curl -L "$download_vivid_url" -o ~/Downloads/Vivid.zip
    unzip ~/Downloads/Vivid.zip -d ~/Downloads
    mv ~/Downloads/Vivid.app /Applications
fi

## Set the default browser and remove the default browser package
if [[ ! -f "/tmp/default-browser-installed" ]]; then
    install_brew_package "defaultbrowser"
    defaultbrowser "browser"
    brew uninstall "defaultbrowser"
    touch /tmp/default-browser-installed
fi

## Open Some default apps if not already open
auto_open_apps=("xbar" "Raycast" "Ice" "AeroSpace")
for app in "${auto_open_apps[@]}"; do
    if ! is_app_running "$app"; then
        open -a "$app"
    fi
done

## CodeRunner is too presumptuous, it always tries to set itself as default for everything
open -a CodeRunner
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -u /Applications/CodeRunner.app
killall CodeRunner
