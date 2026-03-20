#!/bin/bash

# SSH into a Kubernetes Pod
kssh() {
    if [ -z "$1" ]; then
        echo "Usage: kssh <pod-name>"
        return 1
    fi

    kubectl exec -it "$1" -- /bin/bash
}

# SSH into a Docker Container
dssh() {
    USESHELL="${2:-bash}"
	docker exec -it "$1" "${USESHELL}"
}

# Launches PhpStorm
storm() { open -na "PhpStorm.app" --args "$@" }

# Find cd
fcd() { cd "$(find . -type d -not -path '*/.*' | fzf)" && eza -l --icons --git -a; }

# Brew Cask Uninstall
buc() { brew uninstall "$@" --cask --zap; }

# Nushell-powered ls
# Claude Code
cc() { claude "$@" }
ccx() { claude --permission-mode=bypassPermissions "$@" }

# Claude Code (floating zellij window)
fcc() {
  if [[ -n "$ZELLIJ" ]]; then
    zellij run -f -- claude "$@"
  else
    claude "$@"
  fi
}

fccx() {
  if [[ -n "$ZELLIJ" ]]; then
    zellij run -f -- claude --permission-mode=bypassPermissions "$@"
  else
    claude --permission-mode=bypassPermissions "$@"
  fi
}

# Nushell-powered ls
if type nu &>/dev/null; then
  l()  { nu -c "ls $*" }
  ls() { nu -c "ls $*" }
  ll() { nu -c "ls -l $*" }
  la() { nu -c "ls -la $*" }
fi
