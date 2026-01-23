#!/bin/bash
set -e

# ----------------------------------------------------------
# made by beamyyl
# This is the UEFI/GPT installer (runit edition).
# ----------------------------------------------------------

echo ">>> Ensure your EFI partition is mounted to /mnt/boot/efi and root to /mnt."
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
# GRUB for UEFI
# ----------------------------------------------------------
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg

EOF

# ----------------------------------------------------------
# Set Root Password
# ----------------------------------------------------------
echo ">>> Set root password"
artix-chroot /mnt /bin/bash -c 'passwd'

echo "=================================================="
echo " Artix installation complete (runit/UEFI)!"
echo "=================================================="
