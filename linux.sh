#!/bin/sh
# shellcheck disable=SC2068
###############################################################################
### Author:       Valerio Casalino                                          ###
### Description:  Install basic software and workflow                       ###
###############################################################################

### Output messages
###################
errmsg() { printf "\e[31m==>\e[0m %s\\n" "$1"; }
insmsg() { printf "\e[32m==>\e[0m %s\\n" "$1"; }

### Functions 
#############
check_settings() {
    [ "$USER" != "root" ] && errmsg "Please, run with sudo" && return 1
    [ -z "$SUDO_USER" ] && errmsg "Run with sudo, not as root" && return 1
}

# Regular User DO
rudo() { sudo -u "$SUDO_USER" $@; }

assign_pkglist() {
    command -v apt >/dev/null    && _pkgmanager="apt"
    command -v pacman >/dev/null && _pkgmanager="pacman"
    
    case "$_pkgmanager" in
        "apt")
            grep -h -P -o "^Package: \K.*" \
                /var/lib/apt/lists/ppa.launchpad.net_*_Packages \
                | sort -u | fzf -m --layout reverse | tr '\n' ' '
            ;;
        "pacman")
            pacman -Slq core extra community multilib \
                | fzf -m --layout reverse | tr '\n' ' '
            ;;
        *)
            return 1
            ;;
    esac
}
  
update() {
    case "$_pkgmanager" in
        "apt")
            apt -y update && apt -y full-upgrade || return 1 
            ;;
        "pacman")
            pacman --noconfirm -Syyu || return 1
            ;;
        *)
            return 1
            ;;
    esac
}
updater() { update 2>/dev/null || { errmsg "Couldn't update" && return 1; }; }

clean() {
    case "$_pkgmanager" in
        "apt")
            apt -y autoremove && apt -y autoclean || return 1 
            ;;
        "pacman")
            pacman --noconfirm -Sc || return 1 
            ;;
        *)
            return 1
            ;;
    esac
}
cleaner() { clean 2>/dev/null || { errmsg "Couldn't clean" && return 1; }; }

aur_helper() {
    git clone "https://aur.archlinux.org/yay" /opt/yay
    chown "$SUDO_USER":"$SUDO_USER" -R /opt/yay
    cd /opt/yay || return 1
    rudo makepkg -si --noconfirm
}

install() {
    case "$_pkgmanager" in
        "apt")
            apt -y install $@
            ;;
        "pacman")
            pacman --noconfirm --needed -S $@
            ;;
        *)
            return 1
            ;;
    esac
} 

installer() {
    install "$_pkglink" || { errmsg "Error in installation" && return 1; } 
    if [ "$_pkgmanager" = "pacman" ]; then
        aur_helper || { errmsg "Error installing yay" && return 1; }
        insmsg "Want blackarch?"
        blackarch || { errmsg "Error installing blackarch" && return 1; }
    fi
}

myhome() { 
    git --work-tree="/home/$SUDO_USER" --git-dir="/home/$SUDO_USER/.myhome" $@
}

myhome_setup() {
    _myhome_ssh="github.com:casalinovalerio/.myhome"
    _myhome_usr="/home/$SUDO_USER"
    _myhome_pwd="$_myhome_usr/.myhome"
    rudo git clone --bare --recurse-submodules "$_myhome_ssh" "$_myhome_pwd"
    rudo myhome checkout -f master
    rudo myhome submodule update --init --recursive
    chsh "$SUDO_USER" -s /bin/zsh
}

blackarch() {
    printf "[n/Y]: " && read -r _choice < /dev/tty && printf "\n"
    [ "$_choice" != "y" ] && [ "$_choice" != "Y" ] && return 0
    curl -sSLf "https://blackarch.org/strap.sh" | sh || return 1
}

### Actual script
#################
insmsg "Welcome to this installation!" 

insmsg "Checking settings [check_settings()]" && check_settings || exit 1
insmsg "Assigning packages [assign_pkglist()]" && assign_pkglist || exit 1
insmsg "Updating [updater()]" && updater || exit 1
insmsg "Installing [installer()]" && installer || exit 1
insmsg "Setup home [myhome_setup()]" && myhome_setup || exit 1
insmsg "Cleaning [cleaner()]" && cleaner || exit 1

insmsg "It is done!!"
