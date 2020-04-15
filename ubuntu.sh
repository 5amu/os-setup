#!/usr/bin/env sh
###############################################################################
### Author:       Valerio Casalino                                          ###
### Description:  Install basic software in ubuntu-like systems             ###
###############################################################################

### Global variables
UBUNTU_CODENAME=$( lsb_release -cs )

### Output colors
CYA='\e[36m'
YEL='\e[1;33m'
RED='\e[31m'
NCL='\e[0m'

### Errors
errmsg() { printf "${RED}%s${NCL}\\n" "$1"; } 
err() { errmsg "$1"; return 1; }

### Check if root
[ $EUID -ne 0 ] && errmsg "Please, run as root" && exit 1

### Functions
# Installation wrapper
installpkg() { for i in $@; do command -v "$i" > /dev/null | apt -y install "$i"; done || err "Failed to install $@"; }

# Apt mirror:// method to get apt choose the best mirror
setMirrors() {
  printf "deb mirror://mirrors.ubuntu.com/mirrors.txt %s main restricted universe multiverse\\n" "$UBUNTU_CODENAME" | tee /etc/apt/sources.list
  printf "deb mirror://mirrors.ubuntu.com/mirrors.txt %s-updates main restricted universe multiverse\\n" "$UBUNTU_CODENAME" | tee -a /etc/apt/sources.list
  printf "deb mirror://mirrors.ubuntu.com/mirrors.txt %s-backports main restricted universe multiverse\\n" "$UBUNTU_CODENAME" | tee -a /etc/apt/sources.list
  printf "deb mirror://mirrors.ubuntu.com/mirrors.txt %s-security main restricted universe multiverse\\n" "$UBUNTU_CODENAME" | tee -a /etc/apt/sources.list
}

# Install nerd fonts... It will require a while
installNerdFonts() {
  out=$( mktemp -d )
  git clone https://github.com/ryanoasis/nerd-fonts.git "$out"
  bash -c "$out/install.sh --complete" || err "Fonts not installed correctly"
  rm -rf "$out"
}

# Zsh workflow
installZsh() {
  installpkg zsh zsh-syntax-highlighting zsh-autosuggestions zsh-theme-powerlevel9k || err "zsh workflow not installed"
  for i in /home/*; do cp ./resources/.zshrc "$i"; done
}

# Use alacritty.yml in the repository
installAlacritty() {
  add-apt-repository "ppa:mmstick76/alacritty" && installpkg alacritty || err "Unable to install alacritty"
  for i in /home/*; do mkdir -p "$i/.config/alacritty" && cp ./resources/alacritty.yml "$i/.config/alacritty"; done
}

# Use xterm as default?
installXterm() {
  installpkg xterm || err "Unable to install xterm"
  for i in /home/*; do cp ./resources/.Xresources "$i"; done && errmsg "Restart (or logout) required"
}

# Visual Studio Code installation
installVScode() {
  installpkg apt-transport-https
  curl -s "https://packages.microsoft.com/keys/microsoft.asc" | gpg --dearmor > /tmp/packages.microsoft.gpg
  install -o root -g root -m 644 /tmp/packages.microsoft.gpg /usr/share/keyrings/
  sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
  apt -y update && installpkg code || err "Unable to install VScode"
}

# xfce4 with some customizations
installXfce() {
  dpkg -l | grep xfce4-session || { installpkg xfce4 || err "Couldn't install xfce4"; }
  xfce4-panel-profiles load ./resources/xfce4/panel.tar.bz2
  for i in /home/*; do cp ./resources/xfce4/xfce4-keyboard-shortcuts.xml "$i/.config/xfce4/xfce-perchannel-xml/"; done
}

# Commands from https://brave-browser.readthedocs.io/en/latest/installing-brave.html#linux
installBrave() { 
  installpkg apt-transport-https curl || err "Failed to get pre-requisites for brave"
  curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add - || err "Failed to add brave gpg signature"
  echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-release.list || err "Failed to add brave to repository sources"
  apt -y update && installpkg brave-browser || err "Failed to apt install brave"
  # Enable hardware acceleration
  for i in /home/*; do cp ./resources/chromium-flags.conf "$i/.config/brave-flags.conf"; done
}

### Actual script

