# Build

```sh
cd cli && go build -o strap .
```

# Install

Copy the built binary to the scripts directory (symlinked from `~/Developer/bin`):

```sh
cp strap $DOTFILES_DIR/scripts/strap
```
