# ----------------------------------------------------------
# made by beamyyl
# This is the BIOS Artix OpenRC installer.
# ----------------------------------------------------------
#!/bin/bash
set -e

# Fix the clock first to avoid SSL errors
echo ">>> Syncing time..."
# Using standard date sync if ntpdate isn't there
ntpdate -u pool.ntp.org || echo "Time sync failed, check manually"

echo ">>> Ensure your root partition is marked as 'Bootable' and mounted to /mnt."
sleep 3

# 1. Install Base System
# We explicitly add elogind-openrc and netifrc to prevent the dinit conflict
echo ">>> Installing base system with basestrap..."
basestrap /mnt base base-devel openrc elogind-openrc netifrc linux linux-firmware

# 2. Generating FSTAB
echo ">>> Generating fstab..."
fstabgen -U /mnt >> /mnt/etc/fstab

# 3. Enter chroot
artix-chroot /mnt /bin/bash <<'EOF'
export PS1="(artix) ${PS1}"

# Localization
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "artix" > /etc/hostname

# Networking & Utilities
# Added netifrc which is required for OpenRC networking
pacman -S --noconfirm networkmanager-openrc connman-openrc vim nano cronie-openrc
rc-update add NetworkManager default
rc-update add cronie default

# ----------------------------------------------------------
# Bootloader
# ----------------------------------------------------------
pacman -S --noconfirm grub

grub-install \
  --target=i386-pc \
  /dev/sda

grub-mkconfig -o /boot/grub/grub.cfg
EOF

# 4. Root password
echo ">>> Set root password"
artix-chroot /mnt /bin/bash -c 'passwd'

echo "=================================================="
echo " Artix OpenRC BIOS installation complete!"
echo "=================================================="
