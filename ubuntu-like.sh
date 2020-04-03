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
err() { printf "${RED}%s${NCL}" "$1"; exit 1; }

# Everybody like faster updates
rankMirrors() {
  url=$( curl -s http://mirrors.ubuntu.com/mirrors.txt \
    | xargs -n1 -I {} sh -c 'echo $(curl -r 0-102400 -s -w %{speed_download} -o /dev/null {}/ls-lR.gz) {}' \
    | sort -gr \
    | head -1 \
    | cut -d" " -f2 )
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
installFonts() {
  out=$( mktemp -d )
  git clone https://github.com/ryanoasis/nerd-fonts.git "$out"
  /usr/bin/env bash -c "$out/install.sh --complete" && rm -rf "$out" || war "Fonts not installed correctly"
}

# Use the .zshrc in the repository
setupZsh() {
  sudo apt -y install zsh zsh-syntax-highlighting zsh-theme-powerlevel9k || err "zsh not installed"
  # wget "https://..." -O "$HOME/.zshrc" || war "Config for zsh not downloaed properly"
}

# Use alacritty.yml in the repository
setupTerminalEmulatorAlacritty() {
  sudo apt -y install alacritty || err "Unable to install alacritty"
  mkdir -p "$HOME/.config/alacritty"
  # wget "https://raw.githubusercontent...." -O "$HOME/.config/alacritty/alacritty.yml" || war "Config for alacritty not downloaed properly"
}

setupTerminalEmulatorXterm() {
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

removeUseless() {
  sudo apt -y purge \
    transmission* \
    libreoffice* \
    gnome-software \
    gimp \
    gnome-terminal \
    xfce4-terminal \
    firefox
    # It is a long list, but can't remember now...
  sudo apt -y autoremove && sudo apt -y autoclean
}




sudo apt -y update && sudo apt -y install curl
rankMirrors && sudo apt -y update
