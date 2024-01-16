#!/bin/bash

kubebash() {
    if [ -z "$1" ]; then
        echo "Usage: kubebash <pod-name>"
        return 1
    fi

    kubectl exec -it "$1" -- /bin/bash
}


# ----------------------------------------------------------------------------------------
# vscode remote
# ----------------------------------------------------------------------------------------

function code-remote {
  p=$(printf "%s" "$1" | xxd -p) && code --folder-uri "vscode-remote://dev-container+${p//[[:space:]]/}/$2"
}

# ----------------------------------------------------------------------------------------
# PHP Storm
# ----------------------------------------------------------------------------------------

storm() {
  open -na "PhpStorm.app" --args "$@"
}


# ----------------------------------------------------------------------------------------
# ARM M1
# ----------------------------------------------------------------------------------------

arm() {
  arch -x86_64 $@
}


# ----------------------------------------------------------------------------------------
# GIT
# ----------------------------------------------------------------------------------------

# Usage: commit "message"
c() {
  git add --all

  if (($# > 1)); then
    params=''
    for i in $*; do
        params=" $params $i"
    done
    git commit -m "$params"
  else
    git commit -m "$1"
  fi
}

# Usage: push "optional commit message"
p() {
  br=`git branch | grep "*"`
  git add --all

  if (($# > 1)); then
    params=''
    for i in $*; do
        params=" $params $i"
    done
    git commit -m "$params"
  else
    git commit -m "$1"
  fi

  git push origin ${br/* /}
}


# ----------------------------------------------------------------------------------------
# PHP
# ----------------------------------------------------------------------------------------

# Usage: xdebug [on|off]
xd() {
  [[ -z $1 ]] && { echo "${FUNCNAME}(): intent not defined. Specify on or off"; exit 1; }

  PHP_VERSION=$(php -v | tail -r | tail -n 1 | cut -d " " -f 2 | cut -c 1-3)
  INI_FILE="/usr/local/etc/php/${PHP_VERSION}/php.ini"
  XDEB=$(php -v | grep Xdebug)

  if [[ $1 == "on" ]]; then
    if [[ -z $XDEB ]]; then
      sed -i '' 's/;zend_extension=\"xdebug.so\"/zend_extension=\"xdebug.so\"/g' $INI_FILE
    fi
  else
    if [[ ! -z $XDEB ]]; then
      sed -i '' 's/zend_extension=\"xdebug.so\"/;zend_extension=\"xdebug.so\"/g' $INI_FILE
    fi
  fi

  RESTART=$(brew services restart php)
  XDEB=$(php -v | grep Xdebug)

  if [[ -z $XDEB ]]; then
    if [[ $1 == "on" ]]; then
      echo "Error turning on Xdebug"
    else
      echo "Turned off successfully"
    fi
  else
    if [[ $1 == "on" ]]; then
      echo "Turned on sucessfully"
    else
      echo "Failed to turn Xdebug on"
    fi
  fi
}


# ----------------------------------------------------------------------------------------
# DOCKER
# ----------------------------------------------------------------------------------------

# Usage: docker_ssh container
docker_ssh() {
    USESHELL="${2:-bash}"
	docker exec -it "$1" "${USESHELL}"
}


# ----------------------------------------------------------------------------------------
# MISCELLANY
# ----------------------------------------------------------------------------------------

# Usage: bak thing/to/backup
bak() {
    if [[ -e "$1" ]]; then
        echo "Found: $1"
        mv "${1%.*}"{,.bak}
    elif [[ -e "$1.bak" ]]; then
        echo "Found: $1.bak"
        mv "$1"{.bak,}
    fi
}


# ----------------------------------------------------------------------------------------
# iOS
# ----------------------------------------------------------------------------------------

# Usage: ios_ssh [ip]
ios_ssh() {
    if [[ -z ${1} ]]; then
        echo "Usage: ios_ssh [ip]"
        exit 1
    fi

    ssh -i ~/.ssh/id_rsa_cydia "root@${1}"
}

# Usage: ios_copy_tweak [name] [ip]
ios_copy_tweak() {
    if [[ -z ${2} ]]; then
        echo "Usage: ios_copy_tweak [name] [ip]"
        exit 1
    fi

    scp -i $HOME/.ssh/id_rsa_cydia $HOME/Development/Jailbreak/${1}/.theos/_/Library/MobileSubstrate/DynamicLibraries/${1}.* root@${2}:/Library/MobileSubstrate/DynamicLibraries
}
