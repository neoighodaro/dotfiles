# DIRECTORIES
alias d='dirs -v | head -10'
alias 1='cd -'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'
alias www="cd ~/Development/Web"
alias phpserve="php -S localhost:8888"
alias sshconfig="code ~/.ssh/config"
alias cdnginx="cd /usr/local/etc/nginx"

# LARAVEL
alias a="php artisan"
alias artisan="php artisan"

# PHP UNIT
alias pf="./vendor/bin/phpunit --filter="

# XDEBUG
alias xoff="xdebug off"
alias xon="xdebug on"

# COMPOSER
alias cm="composer"
alias cmi="composer install"
alias cmu="composer update"
alias cmda="composer dump-autoload"

# MISCELLANY
alias rm="trash"
alias please='sudo $(fc -ln -1)'
alias json='python -m json.tool'
alias launch-simulator='open -n /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app'

# SYSTEM
alias untrustedenable="sudo spctl --master-disable"
alias untrusteddisable="sudo spctl --master-enable"
alias showFiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app'
alias hideFiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app'

# GIT
alias gi="git init && commit 'Initial commit.'"
alias gs="git status"
alias gc="git commit -m"
alias ga="git add"
alias gitnah="git reset --hard; git clean -df"
alias gr="git config --get remote.origin.url"
alias checkout="git checkout"
alias merge="git merge"

# DOCKER
alias dc="docker-compose"
alias drmi='docker rmi $(docker images --filter "dangling=true" -q --no-trunc)'
alias dssh="docker_ssh"
alias dip="docker inspect --format '{{ .NetworkSettings.IPAddress }}'"
alias drmc='docker rm $(docker ps -q -f status=exited)'
