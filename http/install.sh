#!/bin/bash

set -euo pipefail
set -x

# Determine disk device
if [ -e /dev/sda ]; then
  export device=/dev/sda
elif [ -e /dev/vda ]; then
  export device=/dev/vda
else
  echo "ERROR: No supported disk found." >&2
  exit 1
fi

# Abort early if disk is too small (<8 GiB)
disk_size_gb=$(($(blockdev --getsize64 "${device}") / 1024 / 1024 / 1024))
echo "Disk size: ${disk_size_gb} GiB"

if [ "${disk_size_gb}" -lt 8 ]; then
  echo "ERROR: Disk is smaller than 8 GiB, aborting installation." >&2
  exit 1
fi

# Set keyboard layout to Swedish
loadkeys sv-latin1

# Calculate swap size = 2x system memory (in KiB)
memory_size_kib=$(free | awk '/^Mem:/ { print $2 }')
swap_size_kib=$((memory_size_kib * 2))

# Partition for MBR (label: dos)
cat <<EOF | sfdisk "${device}"
label: dos

# Bootable root partition
,1GiB,83,*

# Swap partition
,${swap_size_kib}KiB,82

# LVM
,,83
EOF

# Show resulting partitions
lsblk -o NAME,SIZE,TYPE,FSTYPE "${device}"

# Determine home LV size based on total disk size
if [ "${disk_size_gb}" -gt 20 ]; then
  export home_lv_size=6G
else
  export home_lv_size=2G
fi

# Create LVM
pvcreate "${device}3"
vgcreate main "${device}3"
lvcreate -L "${home_lv_size}" -n home main
lvcreate -l 100%FREE -n root main

# Format partitions
mkfs.fat -F32 "${device}1"
mkswap "${device}2"
swapon "${device}2"
mkfs.ext4 -F -L root /dev/main/root
mkfs.ext4 -F -L home /dev/main/home

# Mount filesystems
mount /dev/main/root /mnt
mkdir /mnt/home
mount /dev/main/home /mnt/home
mkdir /mnt/boot
mount "${device}1" /mnt/boot

# Configure pacman with a custom mirror
echo 'Server = https://ftp.myrveln.se/pub/linux/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist

# Initialize and populate the pacman keyring
pacman-key --init
pacman-key --populate archlinux

# Install essential packages
pacstrap /mnt base linux qemu-guest-agent lvm2 grub sudo openssh netctl dhcpcd emacs-nox python

# Generate fstab
genfstab -p -U /mnt >> /mnt/etc/fstab
# Show the generated fstab
cat /mnt/etc/fstab

# Turn off swap before chrooting
swapoff "${device}2"

# chroot into the new system
arch-chroot /mnt /bin/bash
