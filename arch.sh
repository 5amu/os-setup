#!/bin/sh
# shellcheck disable=SC2068
###############################################################################
### Author:       Valerio Casalino                                          ###
### Description:  Install my arch :)                                        ###
###############################################################################

### Output messages
###################
err() { printf "\e[31m==>\e[0m %s\\n" "$1"; exit 1; }
msg() { printf "\e[32m==>\e[0m %s\\n" "$1"; }
cmd() { printf "\e[32m[+]\e[0m %s\\n" "$1"; }

banner() {
    echo "\e[31m                          _ \e[0m"
    echo "\e[31m  ___  ___       ___  ___| |_ _   _ _ __ \e[0m"
    echo "\e[31m / _ \\/ __|_____/ __|/ _ \\ __| | | | '_ \\ \e[0m"
    echo "\e[31m| (_) \\__ \_____\\__ \\  __/ |_| |_| | |_) | \e[0m"
    echo "\e[31m \\___/|___/     |___/\___|\\__|\\__,_| .__/ \e[0m"
    echo "\e[31m                                   |_| \e[0m"
    echo "\e[31m       -by 5amu (github.com/5amu/os-setup) \e[0m"
}

banner && echo 

msg "Choose the disk to write..."
disks="$(find /dev/sd* /dev/nvme* /dev/hd* 2>/dev/null | grep -v "[0-9]")"
while [ ! -f $TGTDEV ]; do
    echo $disks | nl
    echo -n "Select disk to write: " && read -r _choice </dev/tty
    TGTDEV=$( echo $disks | sed -n "${_choice}p" )
done

msg "Creating partitions..."
# to create the partitions programatically (rather than manually)
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can 
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "defualt" will send a empty
# line terminated with a newline to take the fdisk default.
# https://superuser.com/a/984637
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${TGTDEV}
  o # clear the in memory partition table
  g # make GTP table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk 
  +512M # 512 MB boot partition
  t # tag this partition
    # default, select partition 1
  1 # choose EFI system
  n # new partition
  p # primary partition
  2 # partion number 2
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
  a # make a partition bootable
  1 # bootable partition is partition 1 -- /dev/sda1
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF

msg "Writing filesystem..."
mkfs.fat   "${TGTDEV}1"
mkfs.btrfs "${TGTDEV}2"

msg "Mounting new filesystem to /mnt"
mount "${TGTDEV}1" /mnt
mkdir -p /mnt/boot
mount "${TGTDEV}2" /mnt/boot

msg "Initializing base system..."
pacstrap /mnt base linux linux-firmware

genfstab -U /mnt >> /mnt/etc/fstab

cat > /mnt/steptwo.sh <<EOF
#!/bin/sh



EOF

arch-chroot /mnt '/bin/sh /steptwo.sh'
