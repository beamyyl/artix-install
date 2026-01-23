#!/bin/bash
set -e

# ----------------------------------------------------------
# made by beamyyl
# This is the BIOS/MBR installer.
# ----------------------------------------------------------

echo ">>> Ensure your root partition is marked as 'Bootable' and that its mounted to /mnt."
sleep 3

# ----------------------------------------------------------
# Install Base System
# ----------------------------------------------------------
# Enable parallel downloads for the Live ISO environment
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

echo ">>> Installing Artix base and OpenRC..."
basestrap /mnt base base-devel openrc-devel

echo ">>> Installing Kernel and Firmware..."
basestrap /mnt linux linux-firmware

cp --dereference /etc/resolv.conf /mnt/etc/

# ----------------------------------------------------------
# Pacman Configuration
# ----------------------------------------------------------
# Enabling parallel downloads for the new installation
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /mnt/etc/pacman.conf

# ----------------------------------------------------------
# FSTAB Generation
# ----------------------------------------------------------
echo ">>> Generating fstab..."
fstabgen -U /mnt > /mnt/etc/fstab

# ----------------------------------------------------------
# Enter Chroot
# ----------------------------------------------------------
artix-chroot /mnt /bin/bash <<'EOF'
# Syncing
pacman -Sy

# System Essentials
echo "artix" > /etc/hostname
pacman -S --noconfirm elogind-openrc dbus-openrc
rc-update add elogind default
rc-update add dbus default

pacman -S --noconfirm networkmanager-openrc cronie-openrc vim nano
rc-update add NetworkManager default
rc-update add cronie default

# ----------------------------------------------------------
# GRUB for BIOS/MBR
# ----------------------------------------------------------
pacman -S --noconfirm grub

# Install to the Master Boot Record of the drive
# Ensure /dev/sda is your correct VM disk
grub-install --target=i386-pc /dev/sda

# Generate the config
grub-mkconfig -o /boot/grub/grub.cfg

EOF

# ----------------------------------------------------------
# Set Root Password
# ----------------------------------------------------------
echo ">>> Set root password"
artix-chroot /mnt /bin/bash -c 'passwd'

echo "=================================================="
echo " Artix installation complete!"
echo "=================================================="
