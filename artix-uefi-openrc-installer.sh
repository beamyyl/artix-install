# ----------------------------------------------------------
# made by beamyyl
# This is the UEFI Artix OpenRC installer.
# ----------------------------------------------------------
#!/bin/bash
set -e

echo ">>> Ensure disks are mounted to /mnt and /mnt/boot/efi."
sleep 3

# 1. Install Base System
echo ">>> Installing base system with basestrap..."
basestrap /mnt base base-devel openrc elogind-openrc linux linux-firmware

# 2. Generating FSTAB
echo ">>> Generating fstab..."
fstabgen -U /mnt >> /mnt/etc/fstab

# 3. Enter chroot
artix-chroot /mnt /bin/bash <<'EOF'
export PS1="(artix-uefi) ${PS1}"

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
# Bootloader (UEFI)
# ----------------------------------------------------------
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# 4. Root password
echo ">>> Set root password"
artix-chroot /mnt /bin/bash -c 'passwd'

echo "=================================================="
echo " Artix OpenRC UEFI installation complete!"
echo "=================================================="
