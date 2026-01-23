#!/bin/bash
set -e

# ----------------------------------------------------------
# made by beamyyl
# This is the UEFI/GPT installer (s6 edition).
# ----------------------------------------------------------

echo ">>> Ensure your EFI partition is mounted to /mnt/boot/efi and root to /mnt."
sleep 3

# ----------------------------------------------------------
# Install Base System
# ----------------------------------------------------------
# Update the system clock (s6-rc command for the live environment if applicable)
echo ">>> Synchronizing system clock..."
s6-rc -u change ntpd || rc-service ntpd start || true

# Enable parallel downloads for the Live ISO environment
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

echo ">>> Installing Artix base, base-devel, and s6..."
# Using s6-base and elogind-s6 as per Artix guide
basestrap /mnt base base-devel s6-base elogind-s6

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

# Install s6 service scripts for system essentials
pacman -S --noconfirm dbus-s6 networkmanager-s6 cronie-s6 vim nano

# Enable services in s6
touch /etc/s6/adminsv/default/contents.d/dbus
touch /etc/s6/adminsv/default/contents.d/elogind
touch /etc/s6/adminsv/default/contents.d/NetworkManager
touch /etc/s6/adminsv/default/contents.d/cronie

# ----------------------------------------------------------
# GRUB for UEFI
# ----------------------------------------------------------
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
