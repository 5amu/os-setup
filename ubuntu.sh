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

### Outputs functions
mss() { printf "${CYA}%s${NCL}\\n" "$1"; }
war() { printf "${YEL}%s${NCL}\\n" "$1"; }
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
  /usr/bin/env bash -c "$out/install.sh --complete" || err "Fonts not installed correctly"
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
  for i in /home/*; do cp ./resources/.Xresources "$i"; done && mss "Restart (or logout) required"
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
# Install dialog to choose some stuff
command -v dialog || { errmsg "Cannot go on without dialog"; exit 1; }

# Welcome screen
dialog --backtitle "os-setup" --title "Welcome!" --msgbox "Welcome to this wizard-ish installer.\\nThis script will guide you, so just relax and let me guide you.\\n\\n\\nValerio Casalino" 10 70

# Prompt to update mirrors
dialog --backtitle "os-setup" --title "Mirrors update" --yesno "Do you wish to automatically update your mirrors?" 15 70 && clear && setMirrors && sudo apt -y update && printf "\\n\\nMirrors Updated!\n" && sleep 2

# Choices
desktopEnv=$(dialog --clear --backtitle "os-setup" --title "Desktop Environment" --menu "Choose one of the following:" 15 70 4 current "Do not install any" xfce4 "For now I support just this" gnome3 "Don't pick this (yet)" i3 "Don't pick this (yet)" 3>&1 1>&2 2>&3 3>&1)
termEmulat=$(dialog --clear --backtitle "os-setup" --title "Terminal Emulator" --menu "Choose one of the following:" 15 70 4 current "Do not install" xterm "Minimal terminal for the X system, with custom settings" alacritty "Blazing fast terminal emulator written in Rust" xfce4-terminal "Default for the xfce desktop environment" 3>&1 1>&2 2>&3 3>&1 )
webBrowser=$(dialog --clear --backtitle "os-setup" --title "Web Browser" --menu "Choose one of the following:" 15 70 4 brave "Chromium-based, privacy focused browser" firefox "It's a classic, preinstalled" chromium "The open source browser de-facto standard" 3>&1 1>&2 2>&3 3>&1)
programLst=$(dialog --clear --backtitle "os-setup" --title "Software" --checklist "Press space to mark a program for installation" 15 70 4 zsh+fonts "Install zsh and NerdFonts" vscode "Install Visual Studio Code (oss if possible)"   )

# Actual changes (draft)
dialog --clear --backtitle "os-setup" --infobox "Setting up desktop environment" 15 70 && sleep 2
case "$desktopEnv" in
  "current") ;;
  "xfce") installXfce ;;
  "gnome3") ;;
  "i3") ;;
  *) ;;
esac

dialog --clear --backtitle "os-setup" --infobox "Setting up terminal emulator" 15 70 && sleep 2
case "$termEmulat" in
  "current") ;;
  "alacritty") installAlacritty ;;
  "xterm") installXterm ;;
  "xfce4-terminal") ;; # installXfceTerminal ;;
  *) ;;
esac

dialog --clear --backtitle "os-setup" --infobox "Setting up web browser" 15 70 && sleep 2
case "$webBrowser" in
  "brave") clear; installBrave ;;
  "firefox") clear; installpkg firefox ;;
  "chromium") clear; installpkg chromium; for i in /home/*; do cp ./resources/chromium-flags.conf "$i/.config/"; done ;;
  *) ;;
esac

dialog --clear --backtitle "os-setup" --infobox "Installing additional software" 15 70 && sleep 2
for soft in $programLst; do case "$soft" in
  "zsh+fonts") clear; installZsh && installNerdFonts ;;
  "vscode") clear; installVScode ;;
  *) ;;
esac done

# Greetings and goodbye!
dialog --backtitle "os-setup" --title "Congratulation!" --msgbox "I hope you didn't have any problem,\\ncontact me for feature requests if you want\\n\\nEnjoy your system!" 10 70
dialog --backtitle "os-setup" --title "Reboot?" --yesno "Do you wish to Reboot?\\n(some programs may need it)" 15 70 && systemctl reboot && clear || clear
