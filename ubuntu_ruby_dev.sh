#!/bin/bash

DEPENDANCIES=(bash awk sed grep ls cp tar curl gunzip bunzip2 git vim)
INSTALLED_BY_SCRIPT=()
REVERT_FILE="ubuntu_ruby_dev_revert.txt"
LOG_FILE="ubuntu_ruby_dev.log"

usage () {
  echo "Usage: $0 [-h|--help|-i|--install|-r|--revert]"
  echo "Default: -i"
  echo ""
  echo "  -h | --help     print this help"
  echo "  -i | --install  start installation process"
  echo "  -r | --revert   revert installation by uninstalling"
}

print_the_greeting () {
  echo -e "\e[33m+-----------------------------------+\e[m"
  echo -e "\e[33m|\e[m\e[100m    This script will install:      \e[m\e[33m|\e[m"
  echo -e "\e[33m|\e[m                                   \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - bash                        \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - awk                         \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - sed                         \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - grep                        \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - ls                          \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - cp                          \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - tar                         \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - curl                        \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - gunzip                      \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - bunzip2                     \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - git                         \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - vim                         \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - imagemagick                 \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - RVM                         \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - Ruby                        \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - NodeJs                      \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - MySQL                       \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - Postgresql                  \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - Redis                       \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - Ag                          \e[33m|\e[m"
  echo -e "\e[33m|\e[m     - Ctags                       \e[33m|\e[m"
  echo -e "\e[33m|\e[m                                   \e[33m|\e[m"
  echo -e "\e[33m|\e[m\e[100m    Continue ? [Y]es/No            \e[m\e[33m|\e[m"
  echo -e "\e[33m+-----------------------------------+\e[m"

  read GO
  local PATTERN="^[yY](es)?$"

  if [ "$GO" != "" ]; then
    if [[ $GO =~ $PATTERN ]]; then
      start_install_process
    else
      exit 1;
    fi
  else
    start_install_process
  fi
}

logger() {
  local MESSAGE="$1"; shift
  printf "\e[1;33m%s\e[m%s\n" "$MESSAGE" "$@"
}

finish () {
  logger "Done! You may need to relogin to apply all changes."
  exit 0
}

check_root () {
  if [ "$UID" -eq 0 ]; then
    logger "Please run this script without sudo: " "$0 $*"
    exit 1
  else
    sudo -v
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
  fi
}

check_if_running () {
  local UTIL=$1
  ps aux | grep "[${UTIL:0:1}]${UTIL:1:${#UTIL}}" > /dev/null

  echo $?
}

apt_install () {
  local PACKAGE="$1"
  if ! which $PACKAGE > /dev/null; then
    logger "Installing: " "$PACKAGE"
    sudo apt-get install -y "$PACKAGE" &>> "$LOG_FILE"
    INSTALLED_BY_SCRIPT+=($PACKAGE)
  else
    logger "Already installed: " "$PACKAGE"
  fi
}

apt_remove () {
  local PACKAGE="$1"
  logger "Removing: " "$PACKAGE"
  sudo apt-get remove -y "$PACKAGE" &>> "$LOG_FILE"
}

install_dependencies () {
  sudo apt-get update &>> "$LOG_FILE"
  for NAME in ${DEPENDANCIES[@]}
  do
    apt_install "$NAME"
  done
}

rvm_signed_ok () {
  \curl -sSL https://get.rvm.io | bash -s stable --ruby &>> "$LOG_FILE"
  source "$HOME/.rvm/scripts/rvm"

  local RVM_VERSION=$(rvm --version)
  local RUBY_VERSION=$(ruby --version)
  logger "RVM installed: " "v${RVM_VERSION:4:6}"
  logger "With Ruby on board: " "v${RUBY_VERSION:5:5}"

  logger "Reopen your shell or run: " "\`source $HOME/.rvm/scripts/rvm\`"
}

install_rvm () {
  logger "Installing RVM and Ruby." " Took a while.."
  local RESULT=$(gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3 2>&1)

  if [ "$?" -ne 0 ]; then
    logger "Problem with gpg keyserver, trying another way: " "$RESULT"
    local RESULT=$(curl -sSL https://rvm.io/mpapis.asc | gpg --import -)

    if [ "$?" -ne 0 ]; then
      logger "Failed to install RVM: " "$RESULT"
      exit 1
    else
      rvm_signed_ok
    fi
  else
    rvm_signed_ok
  fi
}

uninstall_rvm () {
  logger "Uninstalling RVM.."
  rm -rf "$HOME"/.rvm

  for CONFIG in {.bashrc,.bash_profile,.profile,.zshrc,.mkshrc,.zlogin}
  do
    sed --in-place '/.*$HOME\/\.rvm\/.*/d' "$CONFIG"
  done

  gpg --batch --quiet --delete-key --yes D39DC0E3 &>> "$LOG_FILE"

  if [ "$?" -ne 0 ]; then
    logger "Failed to uninstall RVM!"
    exit 1
  else
    logger "RVM uninstalled"
  fi
}

install_dev_packages () {
  apt_remove "nodejs"
  curl -sL https://deb.nodesource.com/setup | sudo bash - &>> "$LOG_FILE"
  sudo apt-get -y update &>> "$LOG_FILE"
  apt_install "nodejs" # UPGRADE IF IT IS INSTALLED
  apt_install "imagemagick"

  logger "Installing: " "MySQL"
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q mysql-server mysql-client libmysqlclient-dev &>> "$LOG_FILE"
  logger "Do not forget to set MySQL root password: " "\`mysqladmin -u root password your_password\`"
  if [ "$(check_if_running "mysql")" == 0 ]; then
    sudo service mysql stop &>> "$LOG_FILE"
  fi
  logger "And start the MySQL server with: " "\`sudo service mysql start\`"
  unset DEBIAN_FRONTEND

  apt_install "postgresql"
  apt_install "postgresql-contrib"
  if [ "$(check_if_running "postgresql")" == 0 ]; then
    sudo service postgresql stop &>> "$LOG_FILE"
  fi
  logger "Start the Postgresql server with: " "\`sudo service postgresql start\`"

  logger "Installing latest stable Redis"
  curl -qo redis.tar.gz http://download.redis.io/redis-stable.tar.gz &>> "$LOG_FILE" && tar xzf redis.tar.gz && cd redis-stable
  make &>> "$LOG_FILE"
  local RESULT=$(sudo make install 2>&1)
  if [ "$?" -eq 0 ]; then
    cd utils
    printf "\n\n\n\n\n" | sudo ./install_server.sh >> "$LOG_FILE"
    cd ../..
    rm -rf redis-stable redis.tar.gz

    local REDIS_VERSION=$(redis-server --version)
    logger "Redis installed: " "v${REDIS_VERSION:15:6}"
    logger "Start the Redis server with: " "\`sudo service redis_6379 start\`"
  else
    cd ..
    logger "Failed to install Redis: " "$RESULT"
  fi

  local CPU_CORES=$(grep --count '^processor' /proc/cpuinfo)
  if [ $CPU_CORES -gt 1 ]; then
    logger "Set up Bundler to run on machine with $CPU_CORES cores"
    bundle config --global jobs $((CPU_CORES - 1)) >> "$LOG_FILE"
  fi

  logger "Updating system gems.."
  gem update --system >> "$LOG_FILE"

  apt_install "silversearcher-ag"
  apt_install "exuberant-ctags"
}

uninstall_dev_packages () {
  logger "Removing NodeJs"
  sudo rm -f /etc/apt/sources.list.d/nodesource.list &>> "$LOG_FILE"
  apt_remove "nodejs"

  logger "Removing MySQL"
  sudo service mysql stop &>> "$LOG_FILE"
  sudo apt-get remove -y mysql-server mysql-client libmysqlclient-dev &>> "$LOG_FILE"
  sudo apt-get remove -y mysql-* &>> "$LOG_FILE"

  logger "Removing Postgresql"
  sudo service postgresql stop &>> "$LOG_FILE"
  sudo apt-get remove -y postgresql postgresql-contrib &>> "$LOG_FILE"

  logger "Removing Redis"
  sudo service redis_6379 stop &>> "$LOG_FILE"
  sudo rm /usr/local/bin/redis-* &>> "$LOG_FILE"
  sudo rm -r /etc/redis/ &>> "$LOG_FILE"
  sudo rm /var/log/redis_* &>> "$LOG_FILE"
  sudo rm -r /var/lib/redis/ &>> "$LOG_FILE"
  sudo rm /var/run/redis_* &>> "$LOG_FILE"
}

start_install_process () {
  logger "Starting installing required dependencies.."
  echo -e "\n\n------- INSTALL --------" >> "$LOG_FILE"
  install_dependencies
  echo ${INSTALLED_BY_SCRIPT[@]} >> "$REVERT_FILE"
  install_rvm
  install_dev_packages
  finish
}

revert () {
  logger "Reverting installation.."
  if [ -f $REVERT_FILE ]; then
    echo -e "\n\n------- REVERT --------" >> "$LOG_FILE"
    readarray DEPENDANCIES < "$REVERT_FILE"
    for NAME in ${DEPENDANCIES[@]}
    do
      apt_remove "$NAME"
      sed --in-place "/"$NAME"/d" "$REVERT_FILE"
    done
    uninstall_rvm
    rm -rf "$REVERT_FILE"
    uninstall_dev_packages

    sudo apt-get autoremove -y &>> "$LOG_FILE"
    sudo apt-get autoclean -y &>> "$LOG_FILE"
    sudo apt-get clean -y &>> "$LOG_FILE"
    sudo apt-get update -y &>> "$LOG_FILE"

    logger "Revert finished successfully!"
    exit 0
  else
    logger "Could not find the revert file: " "Aborted!"
    exit 1
  fi
}

if [ "$1" != "" ]; then
  case "$1" in
    "-h"|"--help")
      usage
      ;;
    "-i"|"--install")
      check_root
      print_the_greeting
      ;;
    "-r"|"--revert")
      check_root
      revert
      ;;
    *)
      logger "UNKNOWN OPTION: " "$1"
      usage
      exit 1
      ;;
  esac
else
  check_root
  print_the_greeting
fi

