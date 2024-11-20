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
