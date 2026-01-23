#!/bin/bash
set -e

# ----------------------------------------------------------
# made by beamyyl
# This is the BIOS/MBR installer (runit edition).
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

echo ">>> Installing Artix base, base-devel, and runit..."
basestrap /mnt base base-devel runit elogind-runit

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

# Install runit service scripts
pacman -S --noconfirm dbus-runit networkmanager-runit cronie-runit vim nano

# Enable services in runit (creating symlinks)
ln -s /etc/runit/sv/dbus /etc/runit/runsvdir/default/
ln -s /etc/runit/sv/elogind /etc/runit/runsvdir/default/
ln -s /etc/runit/sv/NetworkManager /etc/runit/runsvdir/default/
ln -s /etc/runit/sv/cronie /etc/runit/runsvdir/default/

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
echo " Artix installation complete (runit/BIOS)!"
echo "=================================================="
