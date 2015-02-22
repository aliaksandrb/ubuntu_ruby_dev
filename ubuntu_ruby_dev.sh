#!/bin/bash

DEPENDANCIES=(bash awk sed grep ls cp tar curl gunzip bunzip2 git vim)
INSTALLED_BY_SCRIPT=()
REVERT_FILE="ubuntu_ruby_dev_revert.txt"
LOG_FILE="ubuntu_ruby_dev.log"
PATTERN="^[yY](es)?$"
VERBOSE=0
INSTALL_RVM=0
INSTALL_MYSQL=0
INSTALL_POSTGRE=0
INSTALL_REDIS=0
INSTALL_NODE=0
RUBY_VERSION_TO_INSTALL="0"

usage () {
  echo "Usage: $0 [-h|--help|-i|--install|-r|--revert] [-v|--verbose]"
  echo "Default: -i"
  echo ""
  echo "  -h | --help     print this help"
  echo "  -i | --install  start installation process"
  echo "  -r | --revert   revert installation by uninstalling"
  echo "  -v | --verbose  print logs to STDOUT additionally to the log file"
}

print_the_greeting () {
  echo -e "\e[33m+-----------------------------------+\e[m"
  echo -e "\e[33m|\e[m\e[100m           This script             \e[m\e[33m|\e[m"
  echo -e "\e[33m|\e[m\e[100m     allow selectively install:    \e[m\e[33m|\e[m"
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
  echo -e "\e[33m|\e[m\e[100m       Continue ? [Y]es/No         \e[m\e[33m|\e[m"
  echo -e "\e[33m+-----------------------------------+\e[m"

  read GO

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

p () {
  if [ "$VERBOSE" -eq 1 ]; then
    eval "$1" |& tee -a "$LOG_FILE"
  else
    eval "$1" |& tee -a "$LOG_FILE" > /dev/null
  fi
}

check_if_running () {
  pgrep "$1" > /dev/null
  echo $?
}

apt_install () {
  local PACKAGE="$1"
  if ! which "$PACKAGE" > /dev/null; then
    logger "Installing: " "$PACKAGE"
    p "sudo apt-get install -y $PACKAGE"
    INSTALLED_BY_SCRIPT+=($PACKAGE)
  else
    logger "Already installed: " "$PACKAGE"
  fi
}

apt_remove () {
  local PACKAGE="$1"
  if [ "$2" != "--silent" ];then
    logger "Removing: " "$PACKAGE"
  fi
  p "sudo apt-get remove -y $PACKAGE"
}

install_dependencies () {
  logger "Starting installing required dependencies.."
  p "sudo apt-get update"
  for NAME in "${DEPENDANCIES[@]}"
  do
    apt_install "$NAME"
  done
}

rvm_signed_ok () {
  if [ "$RUBY_VERSION_TO_INSTALL" != "0" ];then
    curl -sSL https://get.rvm.io | bash -s stable --ruby=$RUBY_VERSION_TO_INSTALL &>> "$LOG_FILE"
  else
    curl -sSL https://get.rvm.io | bash -s stable --ruby &>> "$LOG_FILE"
  fi
  source "$HOME/.rvm/scripts/rvm"

  local RVM_VERSION=$(rvm --version)
  local RUBY_VERSION=$(ruby --version)
  INSTALLED_BY_SCRIPT+=( rvm )
  logger "RVM installed: " "v${RVM_VERSION:4:6}"
  logger "With Ruby on board: " "v${RUBY_VERSION:5:5}"

  logger "Reopen your shell or run: " "\`source $HOME/.rvm/scripts/rvm\`"
}

install_rvm () {
  if [ "$INSTALL_RVM" -eq 1 ]; then
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
  fi
}

uninstall_rvm () {
  logger "Uninstalling RVM.."
  rm -rf "$HOME"/.rvm

  for CONFIG in {.bashrc,.bash_profile,.profile,.zshrc,.mkshrc,.zlogin}
  do
    sed --in-place "/.*\$HOME\/\.rvm\/.*/d" "$CONFIG"
  done

  gpg --batch --quiet --delete-key --yes D39DC0E3 &>> "$LOG_FILE"

  if [ "$?" -ne 0 ]; then
    logger "Failed to uninstall RVM!"
    exit 1
  else
    logger "RVM uninstalled"
  fi
}

ask_for_permission () {
  read ANSWER

  if [[ ("$ANSWER" != "" && ( $ANSWER  =~ $PATTERN )) || ( "$ANSWER" == "" ) ]]; then
    echo "1"
  fi
}

install_node () {
  if [ "$INSTALL_NODE" -eq 1 ]; then
    apt_remove "nodejs" --silent
    p "curl -sL https://deb.nodesource.com/setup | sudo bash -"
    p "sudo apt-get -y update"
    apt_install "nodejs" # UPGRADE IF IT IS INSTALLED
  fi
}

install_mysql () {
  if [ "$INSTALL_MYSQL" -eq 1 ]; then
    INSTALLED_BY_SCRIPT+=(mysql-server mysql-client libmysqlclient-dev)
    logger "Installing: " "MySQL"
    p "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q mysql-server mysql-client libmysqlclient-dev"
    logger "Do not forget to set MySQL root password: " "\`mysqladmin -u root password your_password\`"
    if [ "$(check_if_running "mysql")" == 0 ]; then
      p "sudo service mysql stop"
    fi
    logger "And start the MySQL server with: " "\`sudo service mysql start\`"
    unset DEBIAN_FRONTEND
  fi
}

install_postgre () {
  if [ "$INSTALL_POSTGRE" -eq 1 ]; then
    apt_install "postgresql"
    apt_install "postgresql-contrib"
    if [ "$(check_if_running "postgresql")" == 0 ]; then
      p "sudo service postgresql stop"
    fi
    logger "Start the Postgresql server with: " "\`sudo service postgresql start\`"
  fi
}

install_redis () {
  if [ "$INSTALL_REDIS" -eq 1 ]; then
    logger "Installing latest stable Redis"
    curl -qo redis.tar.gz http://download.redis.io/redis-stable.tar.gz &>> "$LOG_FILE" && tar xzf redis.tar.gz && cd redis-stable
    make &>> "$LOG_FILE"
    local RESULT=$(sudo make install 2>&1)
    if [ "$?" -eq 0 ]; then
      cd utils
      printf "\n\n\n\n\n" | sudo ./install_server.sh | tee -a "$LOG_FILE" > /dev/null
      cd ../..
      rm -rf redis-stable redis.tar.gz

      local REDIS_VERSION=$(redis-server --version)
      INSTALLED_BY_SCRIPT+=( redis )
      logger "Redis installed: " "v${REDIS_VERSION:15:6}"
      logger "Start the Redis server with: " "\`sudo service redis_6379 start\`"
    else
      cd ..
      logger "Failed to install Redis: " "$RESULT"
    fi
  fi
}

install_dev_packages () {
  install_node
  install_mysql
  install_postgre
  install_redis

  if [ "$INSTALL_RVM" -eq 1 ]; then
    local CPU_CORES=$(grep --count '^processor' /proc/cpuinfo)
    if [ "$CPU_CORES" -gt 1 ]; then
      logger "Set up Bundler to run on machine with $CPU_CORES cores"
      bundle config --global jobs $((CPU_CORES - 1)) >> "$LOG_FILE"
    fi

    logger "Updating system gems.."
    gem update --system >> "$LOG_FILE"
  fi

  apt_install "imagemagick"
  apt_install "silversearcher-ag"
  apt_install "exuberant-ctags"
}

remove_node () {
  apt_remove "nodejs"
  p "sudo rm -f /etc/apt/sources.list.d/nodesource.list"
}

remove_redis () {
  logger "Removing Redis"
  p "sudo service redis_6379 stop"
  p "sudo rm /usr/local/bin/redis-*"
  p "sudo rm -r /etc/redis/"
  p "sudo rm /var/log/redis_*"
  p "sudo rm -r /var/lib/redis/"
  p "sudo rm /var/run/redis_*"
}

start_install_process () {
  logger "Install latest stable RVM and Ruby? [Y]es/No"
  if [ "$(ask_for_permission)" == 1 ]; then
    logger "Any specific Ruby version? [stable by default]"
    read RUBY_VERSION_TO_INSTALL
    INSTALL_RVM=1
  fi

  logger "Install latest NodeJs ? [Y]es/No"
  if [ "$(ask_for_permission)" == 1 ]; then
    INSTALL_NODE=1
  fi

  logger "Install latest MySQL ? [Y]es/No"
  if [ "$(ask_for_permission)" == 1 ]; then
    INSTALL_MYSQL=1
  fi

  logger "Install latest Postgresql ? [Y]es/No"
  if [ "$(ask_for_permission)" == 1 ]; then
    INSTALL_POSTGRE=1
  fi

  logger "Install latest Redis ? [Y]es/No"
  if [ "$(ask_for_permission)" == 1 ]; then
    INSTALL_REDIS=1
  fi

  echo -e "\n\n------- INSTALL --------" >> "$LOG_FILE"
  install_dependencies
  install_rvm
  install_dev_packages
  for NAME in "${INSTALLED_BY_SCRIPT[@]}"
  do
    echo -e "$NAME\n" >> "$REVERT_FILE"
  done
  finish
}

revert () {
  logger "Reverting installation.."
  if [ -f $REVERT_FILE ]; then
    echo -e "\n\n------- REVERT --------" >> "$LOG_FILE"
    IFS=$'\n' INSTALLED_DEPENDANCIES=($(cat "$REVERT_FILE"))
    for NAME in "${INSTALLED_DEPENDANCIES[@]}"
    do
      case "$NAME" in
        "redis")
          remove_redis
          ;;
        "nodejs")
          remove_node
          ;;
        "rvm")
          uninstall_rvm
          ;;
        *)
          apt_remove "$NAME"
          ;;
      esac
      sed --in-place "/$NAME/d" "$REVERT_FILE"
    done
    rm -rf "$REVERT_FILE"

    p "sudo apt-get autoremove -y"
    p "sudo apt-get autoclean -y"
    p "sudo apt-get clean -y"
    p "sudo apt-get update -y"

    logger "Revert finished successfully!"
    exit 0
  else
    logger "Could not find the revert file: " "Aborted!"
    exit 1
  fi
}

check_root_and_print_greeting () {
  check_root "$*"
  print_the_greeting
}

if [ "$1" != "" ]; then
  if [ "$2" != "" -a \( "$2" == "-v" -o "$2" == "--verbose" \) ]; then
    VERBOSE=1
  fi

  case "$1" in
    "-h"|"--help")
      usage
      ;;
    "-i"|"--install")
      check_root_and_print_greeting "$*"
      ;;
    "-r"|"--revert")
      check_root "$*"
      revert
      ;;
    "-v"|"--verbose")
      VERBOSE=1
      check_root_and_print_greeting "$*"
      ;;
    *)
      logger "UNKNOWN OPTION: " "$1"
      usage
      exit 1
      ;;
  esac
else
  check_root_and_print_greeting "$*"
fi

