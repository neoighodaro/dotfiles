# Build

```sh
cd cli && go build -o cli/strap .
```

# Install

Copy the built binary to the scripts directory (symlinked from `~/Developer/bin`):

```sh
cp cli/strap $DOTFILES_DIR/scripts/strap
```
