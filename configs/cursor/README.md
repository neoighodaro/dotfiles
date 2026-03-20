# Cursor Configuration

This directory tracks Cursor editor configuration.

## Extensions

### Export Extensions
To save your current extensions:
```bash
cursor --list-extensions > ~/Developer/dotfiles/cursor/extensions.txt
```

### Import Extensions
To install extensions from the tracked list:
```bash
cat ~/Developer/dotfiles/cursor/extensions.txt | xargs -I {} cursor --install-extension {}
```

## Settings & Keybindings

Settings and keybindings are symlinked from the `vscode/` directory:
- `settings.json` → `vscode/settings.json`
- `keybindings.json` → `vscode/keybindings.json`

**Note**: Due to Cursor using atomic file writes, these symlinks may break when Cursor saves changes. If that happens, you'll need to manually copy changes back to the dotfiles directory.
