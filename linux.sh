#!/usr/bin/env sh
###############################################################################
### Author:       Valerio Casalino                                          ###
### Description:  Install basic software and workflow                       ###
###############################################################################

### Output messages
###################
errmsg() { printf "\e[31m==>\e[0m %s\\n" "$1"; }
insmsg() { printf "\e[32m==>\e[0m %s\\n" "$1"; }

### Global variables
####################
_popos="https://git.io/Jfu1P"
_ubuntu=""
_wsl=""
_arch=""

### Functions 
#############
check_settings() {
  [ "$USER" != "root" ] && errmsg "Please, run with sudo" && return 1
  [ -z "$SUDO_USER" ] && errmsg "Run with sudo, not logged as root" && return 1
  return 0
}

find_distro() {
  [ -f /etc/os-release ] && . /etc/os-release && OS="$NAME" && return 0
  command -v lsb_release >/dev/null && OS="$( lsb_release -si )" && return 0
  [ -f /etc/lsb-release ] && . /etc/lsb-release && OS="$DISTRIB_ID" && return 0
  [ -f /etc/debian_version ] && OS="Debian" && return 0
  grep -qi "Microsoft\|WSL" /proc/version >/dev/null && OS="WSL" && return 0
  errmsg "Can't determine your distro" && return 1
}

assign_pkglist() {
  case "$OS" in
    Ubuntu) _pkglink="$_ubuntu" && _pkgmanager="apt"    ;;
    Pop)    _pkglink="$_popos"  && _pkgmanager="apt"    ;;
    WSL)    _pkglink="$_wsl"    && _pkgmanager="apt"    ;;
    Arch)   _pkglink="$_arch"   && _pkgmanager="pacman" ;;
    *)      errmsg "Unsupported distro" && return 1     ;;
  esac
}
  
update() {
  [ "$_pkgmanager" = "apt" ] \
    && ( apt -y update && apt -y full-upgrade || return 1 ) 2>/dev/null
  [ "$_pkgmanager" = "pacman" ] \
      && ( pacman --noconfirm -Syyu || return 1 ) 2>/dev/null
}

updater() {
  update || { errmsg "Couldn't update" && return 1; }
}

clean() {
  [ "$_pkgmanager" = "apt" ] \
    && ( apt -y autoremove && apt -y autoclean || return 1 ) 2>/dev/null
  [ "$_pkgmanager" = "pacman" ] \
    && ( pacman --noconfirm -Sc || return 1 ) 2>/dev/null
}

cleaner() {
  clean || { errmsg "Couldn't clean" && return 1; }
}

installer() {
  [ "$_pkgmanager" = "apt" ] && apt -y install $@
  [ "$_pkgmanager" = "pacman" ] && pacman --noconfirm -S $@
} 

install_pkgs() {
  installer $( curl -sL "$_pkglink" | tr '\n' ' ' ) \
    || { errmsg "Error in installation" && return 1; } 
}

retrieve_ssh_keys() {
  _tempdir=$( mktemp -d )
  # Download keys
  wget "https://in1t5.xyz/keys.crypt" -O "$_tempdir/k" \
    || { errmsg "Couldn't download keys" && return 1; }
  # Decrypt with openssl
  openssl enc -aes-256-cbc -d -pbkdf2 -in "$_tempdir/k" -out "$_tempdir/k.zip"
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
  git --work-tree="/home/$SUDO_USER" --git-dir="/home/$SUDO_USER/.myhome" $@
}
  
myhome_setup() {
  retrieve_ssh_keys || return 1
  _myhome_ssh="github.com:casalinovalerio/.myhome"
  _myhome_usr="/home/$SUDO_USER"
  _myhome_pwd="$_myhome_usr/.myhome"
  git clone --bare --recurse-submodules "$_myhome_ssh" "$_myhome_pwd"
  chown "$SUDO_USER":"$SUDO_USER" -R "$_myhome_pwd"
  rm "${_myhome_usr}/.profile"
  git_myhome checkout master
  git_myhome submodule init
  git_myhome submodule update
}

### Actual script
#################
printf "Welcome to this installation!\\n" 

# Preparation of the installer
check_settings && find_distro && assign_pkglist || exit 1

# Acual modifications
insmsg "Updating [updater()]" && updater || exit 1
insmsg "Installing [install_pkgs()]" && install_pkgs || exit 1
insmsg "Setup home [myhome_setup()]" && myhome_setup
insmsg "Cleaning [cleaner()]" && apt_clean

printf "It is done!!"
