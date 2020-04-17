#!/usr/bin/env sh
###############################################################################
### Author:       Valerio Casalino                                          ###
### Description:  Install basic software in arch systems                    ###
###############################################################################

[ $EUID -ne 0 ] && printf "Please run as root\\n" && exit 1


# TODO: Implement mirror ranking

pacman -S git discord virtualbox code zsh zsh-autosuggestions \
  zsh-syntax-highlighting docker alacritty 

# Import ssh keys before doing it
for user in $( users ); do
  sudo -u "$user" git clone git@github.com:casalinovalerio/.myhome "/home/$user/.myhome"
  sudo -u "$user" chsh -s /usr/bin/zsh
  YAYOUT="/home/$user/Downloads/yay-git"
  git clone https://aur.archlinux.org/yay-git.git "$YAYOUT"
  chown -R "$user":"$user" "$YAYOUT"
  cd "$YAYOUT" && sudo -u "$user" makepkg -si
  sudo -u "$user" yay -S brave-bin spotify virtualbox-ext-oracle starship debtap
done
