#!/usr/bin/env sh
###############################################################################
### Author:       Valerio Casalino                                          ###
### Description:  Install basic software in Pop!_OS                         ###
###############################################################################

### Output messages
###################
errmsg() { printf "\e[31m%s\e[0m\\n" "$1"; }
insmsg() { printf "\e[32m==>\e[0m %s\\n" "$1"; }

### Global variables
####################
UBUNTU_CODENAME=$( lsb_release -cs )
PKG_LIST="./resources/wsl-packages.txt"

### Functions 
#############
check_settings() {
  [ $EUID -ne 0 ] && errmsg "Please, run with sudo" && return 1
  [ "$( lsb_release -is )" != "Pop" ] && errmsg "Not on Pop!_OS" && return 1
  [ -z "$SUDO_USER" ] && errmsg "Run with sudo, not logged as root" && return 1
}

apt_update() { 
  ( apt -y update && apt -y full-upgrade || return 1 ) 2>/dev/null 
}

apt_clean() {
  ( apt -y autoremove && apt -y autoclean || return 1 ) 2>/dev/null
}

install_pkgs() {
  [ ! -f "$PKG_LIST" ] && return 1
  _pkglist="$( cat $PKG_LIST | tr '\n' ' ' )"
  apt -y install $_pkglist
}

retrieve_ssh_keys() {
  _tempdir=$( mktemp -d )
  _flag=1

  # Download keys
  wget "https://in1t5.xyz/keys.crypt" -O "$_tempdir/k" \
    || { errmsg "Couldn't download keys" && return 1; }

  # Password input loop
  while [ $_flag -eq 1 ]; do
    openssl enc -aes-256-cbc -d -pbkdf2 -in "$_tempdir/k" -out "$_tempdir/k.zip"
    _openssl_retcode=$?
    if [ $_openssl_retcode -ne 0 ]; then 
      printf "Wanna retry? [y/N]\\n"
      read -r _choice
      [ "$_choice" != "y" ] && [ "$_choice" != "Y" ] || _flag=2
    fi
    [ $_openssl_retcode -eq 0 ] && _flag=0
  done
  
  # Check 
  [ "$_flag" -eq 2 ] && return 1

  # Getting your keys into .ssh
  unzip "$_tempdir/k.zip" -d "$_tempdir/keys"
  mkdir "$HOME/.ssh"
  cp "$_tempdir"/keys/ssh/* "$HOME/.ssh/"
  chown "$SUDO_USER":"$SUDO_USER" -R "$HOME/.ssh"
  chmod 600 "$HOME"/.ssh/*

  # Clean temp folder
  rm -rf "$_tempdir"
}

git_myhome() {
  _git_dir="$1"
  shift
  git --work-tree="/home/$SUDO_USER" --git-dir="$_git_dir" $@
}
  
myhome_setup() {
  _myhome_ssh="git@github.com:casalinovalerio/.myhome"
  _myhome_usr="/home/$SUDO_USER"
  _myhome_pwd="$_myhome_usr/.myhome"
  git clone --bare --recurse-submodules "$_myhome_ssh" "$_myhome_pwd"
  chown "$SUDO_USER":"$SUDO_USER" -R "$_myhome_pwd"

  for f in $( git_myhome "$_myhome_pwd" ls-tree -r master --name-only ); do
    [ -f "$_myhome_usr/$f" ] && rm "$_myhome_usr/$f"
  done

  git_myhome "$_myhome_pwd" submodule init
  git_myhome "$_myhome_pwd" checkout master
  git_myhome "$_myhome_pwd" submodule update
}

### Actual script
#################
check_settings || exit 1
# Greetings
printf "Welcome to this installation!\\n"
# Updates and install pkgs
insmsg "Updating system (apt_update())"
apt_update || errmsg "Something went wrong..."
insmsg "Installing packages from file (install_pkgs())"
install_pkgs || errmsg "Couldn't read pkg list"
# Getting ssh keys
insmsg "Get ssh keys and setup home"
retrieve_ssh_keys && myhome_setup
# Clean apt
insmsg "Cleaning apt (apt_clean())"
apt_clean || errmsg "Something went wrong..."
# Done!
printf "It is done!!"
