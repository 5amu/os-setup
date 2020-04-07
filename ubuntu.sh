#!/usr/bin/env sh
###############################################################################
### Author:       Valerio Casalino                                          ###
### Description:  Install basic software in ubuntu-like systems             ###
###############################################################################

# Colors
CYA='\e[36m'
YEL='\e[1;33m'
RED='\e[31m'
NCL='\e[0m'

# Outputs
mss() { printf "${CYA}%s${NCL}" "$1"; }
war() { printf "${YEL}%s${NCL}" "$1"; }
errmsg() { printf "${RED}%s${NCL}" "$1"; } 
err() { errmsg "$1"; return 1; }

# Everybody like faster updates
rankMirrors() {
  sudo apt -y update && sudo apt -y install curl || err "Unable to install curl, mirrors not updated"
  url=$( curl -s http://mirrors.ubuntu.com/mirrors.txt | xargs -n1 -I {} sh -c 'echo $(curl -r 0-102400 -s -w %{speed_download} -o /dev/null {}/ls-lR.gz) {}' | sort -gr | head -1 | cut -d" " -f2 )
  codename=$( lsb_release -cs )
  printf "Backing up source list to /etc/apt/sources.list.bak\\nNew source list:"
  sudo mv /etc/apt/sources.list /etc/apt/sources.list.bak || err "Failed to copy source list" 
  printf "deb %s %s main restricted\\n" "$url" "$codename" | sudo tee /etc/apt/sources.list
  printf "deb %s %s-updates main restricted\\n" "$url" "$codename" | sudo tee -a /etc/apt/sources.list
  printf "deb %s %s universe\\n" "$url" "$codename" | sudo tee -a /etc/apt/sources.list
  printf "deb %s %s-updates universe\\n" "$url" "$codename" | sudo tee -a /etc/apt/sources.list
  printf "deb %s %s multiverse\\n" "$url" "$codename" | sudo tee -a /etc/apt/sources.list
  printf "deb %s %s-updates multiverse\\n" "$url" "$codename" | sudo tee -a /etc/apt/sources.list
  printf "deb %s %s-backports main restricted universe multiverse\\n" "$url" "$codename" | sudo tee -a /etc/apt/sources.list
  printf "deb %s %s-security main restricted\\n" "$url" "$codename" | sudo tee -a /etc/apt/sources.list
  printf "deb %s %s-security universe\\n" "$url" "$codename" | sudo tee -a /etc/apt/sources.list
  printf "deb %s %s-security multiverse\\n" "$url" "$codename" | sudo tee -a /etc/apt/sources.list
}

# Install nerd fonts... It will require a while
installNerdFonts() {
  out=$( mktemp -d )
  git clone https://github.com/ryanoasis/nerd-fonts.git "$out"
  /usr/bin/env bash -c "$out/install.sh --complete" && rm -rf "$out" || war "Fonts not installed correctly"
}

# Use the .zshrc in the repository
installZsh() {
  sudo apt -y install zsh zsh-syntax-highlighting zsh-autosuggestions zsh-theme-powerlevel9k || err "zsh not installed"
  cp ./resources/.zshrc "$HOME"
}

# Use alacritty.yml in the repository
installAlacritty() {
  sudo apt -y install alacritty || err "Unable to install alacritty"
  mkdir -p "$HOME/.config/alacritty"
  cp ./resources/alacritty.yml "$HOME/.config/alacritty"
}

# Use xterm as default?
installXterm() {
  sudo apt -y install xterm || err "Unable to install xterm"
  cp ./resources/.Xresources "$HOME" && printf "Restart (or logout) required"
}

installVScode() {
  sudo apt -y install apt-transport-https
  curl -s "https://packages.microsoft.com/keys/microsoft.asc" | gpg --dearmor > /tmp/packages.microsoft.gpg
  sudo install -o root -g root -m 644 /tmp/packages.microsoft.gpg /usr/share/keyrings/
  sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
  sudo apt -y update && sudo apt -y install code || war "Unable to install VScode"
}

installXfce() {
  dpkg -l | grep xfce4-session || { sudo apt -y install xfce4 || err "Couldn't install xfce4"; }
  xfce4-panel-profiles load ./resources/xfce4/panel.tar.bz2
  cp ./resources/xfce4/xfce4-keyboard-shortcuts.xml "$HOME/.config/xfce4/xfce-perchannel-xml/"
}

# Commands from https://brave-browser.readthedocs.io/en/latest/installing-brave.html#linux
installBrave() { 
  sudo apt -y install apt-transport-https curl || err "Failed to get pre-requisites for brave"
  curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add - || err "Failed to add brave gpg signature"
  echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list || err "Failed to add brave to repository sources"
  sudo apt -y update && sudo apt -y install brave-browser || err "Failed to apt install brave"
  # Enable hardware acceleration
  cp ./resources/chromium-flags.conf "$HOME/.config/brave-flags.conf"
}

# Install dialog to choose some stuff
command -v dialog || { errmsg "Cannot go on without dialog"; exit 1; }

# Welcome screen
dialog --backtitle "os-setup" --title "Welcome!" --msgbox "Welcome to this wizard-ish installer.\\nThis script will guide you, so just relax and let me guide you.\\n\\n\\nValerio Casalino" 10 70

# Prompt to update mirrors
dialog --backtitle "os-setup" --title "Mirrors update" --yesno "Do you wish to automatically update your mirrors?" 15 70 && clear && rankMirrors && sudo apt -y update && printf "\\n\\nMirrors Updated!\n" && sleep 2

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
  "firefox") clear; sudo apt -y install firefox ;;
  "chromium") clear; sudo apt -y install chromium; cp ./resources/chromium-flags.conf "$HOME/.config/" ;;
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
