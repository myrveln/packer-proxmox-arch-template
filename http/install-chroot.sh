#!/bin/bash

set -e
set -x

# Set the timezone to Europe/Stockholm
ln -sf /usr/share/zoneinfo/Europe/Stockholm /etc/localtime

# Set a default hostname
echo 'template' > /etc/hostname

# Set the keyboard layout to Swedish (Latin-1)
cat <<EOF > /etc/vconsole.conf
KEYMAP=sv-latin1
FONT=lat9w-16
FONT_MAP=8859-1
EOF

# Enabling and generate desired locales
cat <<EOF > /etc/locale.gen
sv_SE.UTF-8 UTF-8
en_GB.UTF-8 UTF-8
EOF

# Generate the locales
locale-gen

# Set the default locale to en_GB.UTF-8
echo 'LANG=en_GB.UTF-8' > /etc/locale.conf

# Set the hardware clock to UTC
hwclock --systohc --utc

# Revert to traditional interface names (eth0, etc.)
mkdir -p /etc/systemd/network/99-default.link.d
cat <<EOF > /etc/systemd/network/99-default.link.d/traditional-naming.conf
[Link]
NamePolicy=keep kernel
EOF

# Create a simple DHCP profile for eth0
cat <<EOF > /etc/netctl/eth0-dhcp
Description='A basic dhcp ethernet connection'
Interface=eth0
Connection=ethernet
IP=dhcp
EOF

# Enable for template use (will be removed when cloning to real VM)
netctl enable eth0-dhcp

# Create user, group and set up sudo permissions
echo -e 'template\ntemplate' | passwd
useradd -m -g users -G wheel,storage,power -s /bin/bash kim
echo -e 'template\ntemplate' | passwd kim
cat <<EOF > /etc/sudoers.d/allow-group-wheel
# Allow kim to run sudo without a password and without requiring a tty
# This file must be removed when cloning to a real VM
Defaults:kim !requiretty
kim ALL=(ALL) NOPASSWD: ALL
EOF
chmod 440 /etc/sudoers.d/allow-group-wheel

# Enable SSH service
systemctl enable sshd

# Fix mkinitcpio.conf with lvm2 and rebuild hooks
sed -i -E 's/(HOOKS=.*[[:space:]])filesystems/\1lvm2 filesystems/' /etc/mkinitcpio.conf
mkinitcpio -P linux

# Install GRUB bootloader
grub-install --target=i386-pc "${device}"

# Configure GRUB
sed -i -e 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
