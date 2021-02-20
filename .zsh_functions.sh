#!/bin/bash

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
	docker exec -it $1 bash
}


# ----------------------------------------------------------------------------------------
# MISCELLANY
# ----------------------------------------------------------------------------------------

# Usage: bak path/to/file optional/path/to/save
bak() {
    if [[ -z ${1} ]]; then
        echo "Usage: bak /path/to/file.extension </path/to/save>"
        exit 1
    fi

    FILENAME=$(basename ${1})
    [[ -z ${2} ]] && SAVEBAKPATH="${1}.bak" || SAVEBAKPATH="${2}/${FILENAME}.bak"
    cp -R "${1}" "${SAVEBAKPATH}"
}

# Usage: wordpress_new [name]
wordrpess_new() {
	mkdir "$1"
	cd "$1"
	wget "http://wordpress.org/latest.zip"
	unzip latest.zip
	rm -rf __MACOSX latest.zip
	cp -rf ./wordpress/* ./
	rm -rf ./wordpress/ ./wp-content/plugins/hello.php ./readme.html
	mkdir ./wp-content/uploads/
	mv wp-config-sample.php wp-config.php
	touch htaccess.txt robots.txt
	nano wp-config.php
	open https://api.wordpress.org/secret-key/1.1/salt/
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
