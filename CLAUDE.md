# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository for automating macOS and Linux server setup. It includes shell configurations, application settings, and system preferences. The setup is opinionated and designed for the author's workflow.

## Installation & Setup

**Prerequisites:**
- Git must be installed (pre-installed on macOS, `sudo apt install -y git` on Linux)

**Initial Setup:**
```bash
git clone git@github.com:neoighodaro/dotfiles.git
chmod a+x init.sh
./init.sh
```

**Non-interactive mode** (for automation/ansible):
```bash
./init.sh --non-interactive
# Or set: NON_INTERACTIVE=true
```

**Mac-specific preparation:**
- Add wallpaper to `~/Pictures/wallpaper.(jpg|png|heic)` before running init.sh

## Key Scripts

- `init.sh` - Main entry point, handles symlink creation, SSH/GPG key generation, and delegates to platform-specific scripts
- `init-mac.sh` - macOS setup: Homebrew packages, casks, Mac App Store apps, system preferences
- `init-linux.sh` - Linux setup: apt packages, Docker, SSH hardening, swap file configuration

## Architecture

### Symlink System
The `link_and_backup()` function (in init.sh:68) creates symlinks from `$DOTFILES_DIR` to `$HOME`, backing up existing files with `.backup` or `.bak` extension. It supports:
- Standard home directory files
- Nested paths (e.g., `.config/lazygit`)
- Absolute paths with `--realpath` flag
- Sudo operations with `--sudo` flag

### Platform Detection
Scripts detect OS via `uname -s` and set `IS_MACOS`/`IS_LINUX` flags to conditionally execute platform-specific configuration.

### Configuration Structure

**Git Configuration:**
- `git/base.cfg` - Base config with user info, aliases, delta integration
- `git/mac.cfg` or `git/linux.cfg` - Platform-specific extensions (auto-included via `git/base.cfg:99`)
- `git/work.cfg` - Work-specific config (conditionally included for `~/Developer/pinktum` directory)
- `git/private.cfg` - Private config (optional, not in repo)

**ZSH Configuration (sourced from zsh/zshrc.sh):**
- `zsh/zshrc.sh` - Main ZSH config with plugin loading, tool initialization
- `zsh/aliases.sh` - Command aliases
- `zsh/functions.sh` - Custom shell functions
- `zsh/paths.sh` - PATH modifications
- `zsh/private.sh` - Private scripts and environment variables

**Application Configs:**
- `zellij/` - Terminal multiplexer config (requires zjstatus.wasm plugin, auto-downloaded by init-mac.sh:454)
- `aerospace/` - Window manager (macOS)
- `karabiner/` - Keyboard customization (macOS)
- `sketchybar/` - Status bar (macOS, auto-started via brew services)
- `ghostty/`, `wezterm/` - Terminal emulator configs
- `vscode/` - VS Code settings, keybindings, and optional custom CSS/JS
- `starship/` - Shell prompt configuration
- `lazygit/` - Git TUI configuration

### macOS Setup Details

**Package Management (init-mac.sh:18-86):**
- Homebrew packages defined in `BREW_PACKAGES_TO_INSTALL` array (format: `"package:tap"` or just `"package"`)
- Casks defined in `BREW_CASKS_TO_INSTALL` (supports custom URLs: `"app:url"`)
- Mac App Store apps via `mas` tool in `MAC_APPS_TO_INSTALL` (format: `"AppName:appid"`)

**System Preferences (init-mac.sh:287-377):**
- Extensive `defaults write` commands configure Dock, Finder, global settings
- Auto-hide menu bar and dock
- Desktop icons hidden
- Screenshots saved to `~/Documents/• Screenshots`
- Wallpaper auto-set if found in `~/Pictures/` or `wallpapers/` directory

**Special App Configurations:**
- Sketchybar: Auto-started via `brew services start sketchybar`
- GPG: pinentry-touchid configured for Touch ID authentication (init-mac.sh:424-439)
- VSCode: Custom CSS/JS optional, user prompted during setup

### Linux Setup Details

**System Hardening (init-linux.sh:33-56):**
- SSH configuration: Disables root login, password auth, PAM

**Swap File (init-linux.sh:59-102):**
- Auto-calculated based on RAM size
- 50% of RAM for systems with 2-32GB
- 25% of RAM for systems with 32GB+

**Package Installation:**
- Core utilities: eza, bat, zoxide, fzf, lazygit, git-delta
- Docker with optional Portainer installation
- Starship, Deno installed via direct downloads

## Directory Structure Conventions

**Created directories (macOS):**
- `~/Developer` - Development projects
- `~/Downloads/• Trashable` - Temporary downloads
- `~/Downloads/• Keep` - Permanent downloads
- `~/Documents/• Screenshots` - Screenshot location
- `~/Documents/• Unsorted` - Miscellaneous files

**Config directories:**
- `~/.config/` - XDG-compliant application configs
- `~/.gnupg/` - GPG configuration (permissions: 700 for dirs, 600 for files)
- `~/.ssh/` - SSH keys and config

## Important Variables

- `NEO_HOME_DIR` - Defaults to `$HOME`, can be overridden
- `DOTFILES_DIR` - `$NEO_HOME_DIR/Developer/dotfiles`
- `NVM_VERSION` - Currently `v0.40.1`
- `NON_INTERACTIVE` - Set to skip prompts for automation

## Helper Functions Reference

**init.sh:**
- `link_and_backup(source, target, [--realpath], [--sudo])` - Create symlink with backup

**init-mac.sh:**
- `install_brew_package(package, [tap])` - Install Homebrew formula
- `install_cask_app(app_name, [url])` - Install Homebrew cask
- `install_mac_app(app_info)` - Install via mas (format: "AppName:appid")
- `is_mac_app_installed(app_name)` - Check if app exists in /Applications
- `is_app_running(app_name)` - Check if app is currently running

**init-linux.sh:**
- `install_apt_package(package_name)` - Install apt package if not present

## Common Workflows

**Adding a new Homebrew package (macOS):**
1. Add to `BREW_PACKAGES_TO_INSTALL` array in init-mac.sh
2. Use format `"package"` or `"package:tap"` if custom tap needed
3. Run `./init.sh` or call `install_brew_packages` function

**Adding a new config symlink:**
1. Add `link_and_backup` call to appropriate script (init.sh for cross-platform, init-mac.sh/init-linux.sh for platform-specific)
2. Format: `link_and_backup "source/path" "target/path"` (relative to `$NEO_HOME_DIR` unless `--realpath` used)

**Modifying system preferences (macOS):**
1. Add `defaults write` commands to `update_mac_settings()` function in init-mac.sh
2. Add affected app to `APPS` array at init-mac.sh:417 to ensure it's restarted

## Tool Integrations

**ZSH Plugins:**
- zsh-autosuggestions
- zsh-syntax-highlighting
- Loaded from `/usr/share` (Linux) or `$HOMEBREW_PREFIX/share` (macOS)

**Key Tools:**
- **Starship** - Cross-shell prompt (config: `starship/starship.toml`)
- **Zellij** - Terminal multiplexer (auto-attaches via `zattach` function, skipped in VSCode/JetBrains terminals)
- **fzf** - Fuzzy finder (CTRL-R for history, CTRL-T for files, ALT-C for directories)
- **zoxide** - Smarter cd (replaces cd command via `--cmd cd` flag)
- **delta** - Git diff pager (theme: Nord, line numbers enabled)
- **NVM** - Node version manager (lazy-loaded)

**Zellij Behavior:**
- Auto-starts on new terminal sessions (except SSH, VSCode, JetBrains)
- `zattach [session]` - Helper to attach or create sessions
- Disabled terminals: vscode, JetBrains-JediTerm (see zsh/zshrc.sh:230)

## Git Configuration Notes

- Commits are GPG-signed via SSH using 1Password (gpg.ssh.program points to op-ssh-sign)
- Delta pager configured with Nord theme and line numbers
- Conflict style: zdiff3 (more detailed merge conflicts)
- Main branch: `main` (configured as default)
- Work directory conditional config: `~/Developer/pinktum` includes `~/.gitconfig.work`

## Special Files

- `/tmp/dotfiles__ssh-skip-check` - Marker to prevent re-prompting for SSH key generation
- `/tmp/dotfiles__gpg-skip-check` - Marker to prevent re-prompting for GPG key generation
- `/tmp/vscode-customized` - Marker for VSCode customization prompt
- `/tmp/default-browser-installed` - Marker for default browser setup
- `~/Pictures/wallpaper.skip` - Prevents wallpaper auto-setting on macOS

## Testing & Development

When modifying scripts:
- Test in non-interactive mode: `NON_INTERACTIVE=true ./init.sh`
- Check idempotency: Run script twice, second run should skip most operations
- Verify symlinks: `ls -la ~ | grep "->"`
- Platform detection: Scripts check `IS_MACOS`/`IS_LINUX` flags
