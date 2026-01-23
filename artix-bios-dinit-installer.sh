#!/bin/bash
set -e

# ----------------------------------------------------------
# made by beamyyl
# This is the BIOS/MBR installer (dinit edition).
# ----------------------------------------------------------

echo ">>> Ensure your root partition is marked as 'Bootable' in fdisk/cfdisk and that its mounted to /mnt."
sleep 3

# ----------------------------------------------------------
# Install Base System
# ----------------------------------------------------------
echo ">>> Synchronizing system clock..."
rc-service ntpd start || true

# Enable parallel downloads for the Live ISO environment
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

echo ">>> Installing Artix base, base-devel, and dinit..."
basestrap /mnt base base-devel dinit elogind-dinit

echo ">>> Installing Kernel and Firmware..."
basestrap /mnt linux linux-firmware

cp --dereference /etc/resolv.conf /mnt/etc/

# ----------------------------------------------------------
# Pacman Configuration
# ----------------------------------------------------------
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
hwclock --systohc

pacman -Sy

# System Essentials
echo "artix" > /etc/hostname

# Install dinit service scripts
pacman -S --noconfirm dbus-dinit networkmanager-dinit cronie-dinit vim nano

# Enable services in dinit (creating symlinks into boot.d)
ln -s ../dbus /etc/dinit.d/boot.d/
ln -s ../elogind /etc/dinit.d/boot.d/
ln -s ../NetworkManager /etc/dinit.d/boot.d/
ln -s ../cronie /etc/dinit.d/boot.d/

# ----------------------------------------------------------
# GRUB for BIOS/MBR
# ----------------------------------------------------------
pacman -S --noconfirm grub
grub-install --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

EOF

# ----------------------------------------------------------
# Set Root Password
# ----------------------------------------------------------
echo ">>> Set root password"
artix-chroot /mnt /bin/bash -c 'passwd'

echo "=================================================="
echo " Artix installation complete (dinit/BIOS)!"
echo "=================================================="
