#!/bin/bash
set -e

# ----------------------------------------------------------
# made by beamyyl
# This is the UEFI/GPT installer.
# ----------------------------------------------------------

echo ">>> Ensure your EFI partition is mounted to /mnt/boot/efi and root to /mnt."
sleep 3

# ----------------------------------------------------------
# Install Base System
# ----------------------------------------------------------
# Update the system clock to avoid SSL certificate errors
echo ">>> Synchronizing system clock..."
rc-service ntpd start || true

# Enable parallel downloads for the Live ISO environment
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

echo ">>> Installing Artix base, base-devel, and OpenRC..."
basestrap /mnt base base-devel openrc elogind-openrc

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
# Configure the system clock
hwclock --systohc

# Syncing
pacman -Sy

# System Essentials
echo "artix" > /etc/hostname
pacman -S --noconfirm dbus-openrc
rc-update add elogind default
rc-update add dbus default

pacman -S --noconfirm networkmanager-openrc cronie-openrc vim nano
rc-update add NetworkManager default
rc-update add cronie default

# ----------------------------------------------------------
# GRUB for UEFI
# ----------------------------------------------------------
# efibootmgr is required for UEFI systems
pacman -S --noconfirm grub efibootmgr

# Install GRUB to the EFI partition
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub

# Generate the config
grub-mkconfig -o /boot/grub/grub.cfg

EOF

# ----------------------------------------------------------
# Set Root Password
# ----------------------------------------------------------
echo ">>> Set root password"
artix-chroot /mnt /bin/bash -c 'passwd'

echo "=================================================="
echo " Artix installation complete! "
echo "=================================================="
