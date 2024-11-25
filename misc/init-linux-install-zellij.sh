#!/bin/bash

if [[ -f "/usr/local/bin/zellij" ]]; then
    echo -e "${GRAY}===> Zellij is already installed. Skipping...${NC}"
    exit 0
fi

# Get the architecture of the machine
arch=$(uname -m)
os=$(uname -s)

# Download the Zellij binary
if [ "$os" == "Darwin" ]; then
  filename="zellij-${arch}-apple-darwin.tar.gz"
  url="https://github.com/zellij-org/zellij/releases/latest/download/$filename"
  echo "Downloading Zellij binary for macOS..."
  curl -LO "$url"
else
  if [ "$os" == "Linux" ]; then
    filename="zellij-${arch}-unknown-linux-musl.tar.gz"
    url="https://github.com/zellij-org/zellij/releases/latest/download/$filename"
    echo "Downloading Zellij binary for Linux..."
    curl -LO "$url"
  else
    echo "Unsupported OS: $os"
  fi
fi

# Uncompress the Zellij binary
tar -xf "$filename"

# Move the Zellij binary to the /bin directory
sudo mv "./zellij" /usr/local/bin/zellij

# Remove the .tar.gz file
rm "$filename"

echo -e "${GREEN}==> Zellij installed.${NC}"
