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

### Functions 
#############
check_settings() {
  [ "$USER" != "root" ] && errmsg "Please, run with sudo" && return 1
  [ -z "$SUDO_USER" ] && errmsg "Run with sudo, not logged as root" && return 1
  return 0
}
