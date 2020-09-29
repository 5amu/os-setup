#!/usr/bin/env sh
###############################################################################
### Author:       Valerio Casalino                                          ###
### Description:  Install basic software and workflow with Ansible          ###
###############################################################################

### Output messages
###################
errmsg() { printf "\e[31m==>\e[0m %s\\n" "$1"; }
insmsg() { printf "\e[32m==>\e[0m %s\\n" "$1"; }

### Global variables
####################
_keylink="https://strap.casalinovalerio.com/keys.crypt"
_anslink="https://strap.casalinovalerio.com/playbook.yml"

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

assign_pkgmanager() {
  case "$( printf "%s" "$OS" | sed "s/ //g" )" in
    Ubuntu)             _pkgmanager="apt"    ;;
    Pop)                _pkgmanager="apt"    ;;
    WSL)                _pkgmanager="apt"    ;;
    Arch|ManjaroLinux)  _pkgmanager="pac"    ;;
    *)                  errmsg "Unsupported distro" && return 1 ;;
  esac
}

retrieve_ssh_keys() {
  sudo -u "$SUDO_USER" \
      rsync keys@ssh.casalinovalerio.com:"~/.ssh/*" "/home/$SUDO_USER/.ssh"
}

apt_routine() {
  apt -y update && apt -y install ansible || return 1
}

pacman_routine() {
  pacman --noconfirm -Sy && pacman --noconfirm -S ansible || return 1
  ansible-galaxy collection install community.general
}

install_base() {
  [ "$_pkgmanager" = "apt" ] && apt_routine || { errmsg "Error" && return 1; }
  [ "$_pkgmanager" = "pac" ] && pac_routine || { errmsg "Error" && return 1; }
}

aur_helper() {
  git clone "https://aur.archlinux.org/yay" /opt/yay
  chown "$SUDO_USER":"$SUDO_USER" -R /opt/yay
  cd /opt/yay
  sudo -u "$SUDO_USER" makepkg -si --noconfirm
}

launch_ansible() {
  _playbook="/tmp/post-install.yml"
  sudo -u "$SUDO_USER" wget "$_anslink" -O "$_playbook"
  sed -i "s/<user>/$SUDO_USER/g;s/<pkgman>/$_pkgmanager/g" "$_playbook"
  sudo -u "$SUDO_USER" ansible-playbook -K "$_playbook"
}
  
### Actual script
#################
insmsg "Welcome to this installation!" 

check_settings && find_distro && assign_pkmanager || exit 1
insmsg "Installing base software" && install_base || exit 1
insmsg "Getting SSH keys" && retrieve_ssh_keys || exit 1
[ "$_pkgmanager" = "pac" ] && insmsg "Getting AUR helper" && aur_helper
insmsg "Launching Ansible Playbook on localhost" && launch_ansible

insmsg "It is done!!"
