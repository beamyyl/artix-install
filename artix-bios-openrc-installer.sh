# ----------------------------------------------------------
# made by beamyyl
# This is the BIOS Artix OpenRC installer.
# ----------------------------------------------------------
#!/bin/bash
set -e

echo ">>> Ensure root is mounted to /mnt and marked bootable."
sleep 3

# 1. Install Base System (Explicitly avoiding dinit conflict)
echo ">>> Installing base system with basestrap..."
echo "ParallelDownloads = 5" >> /etc/pacman.conf
basestrap /mnt base base-devel openrc elogind-openrc linux linux-firmware

# 2. Generating FSTAB
echo ">>> Generating fstab..."
fstabgen -U /mnt >> /mnt/etc/fstab

# 3. Enter chroot
artix-chroot /mnt /bin/bash <<'EOF'
export PS1="(artix-bios) ${PS1}"

pacman -Syy

# Localization & Clock
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "artix" > /etc/hostname
echo "hostname='artix'" > /etc/conf.d/hostname

# Networking & Utilities
pacman -S --noconfirm networkmanager-openrc connman-openrc vim nano cronie-openrc
rc-update add NetworkManager default
rc-update add cronie default

# ----------------------------------------------------------
# Bootloader (BIOS)
# ----------------------------------------------------------
pacman -S --noconfirm grub
# Targeting the disk (e.g., /dev/sda) as per Wiki
grub-install --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# 4. Root password
echo ">>> Set root password"
artix-chroot /mnt /bin/bash -c 'passwd'

echo "=================================================="
echo " Artix OpenRC BIOS installation complete!"
echo "=================================================="
