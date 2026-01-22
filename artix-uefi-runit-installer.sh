# ----------------------------------------------------------
# made by beamyyl
# This is the UEFI Artix Runit installer.
# ----------------------------------------------------------
#!/bin/bash
set -e

echo ">>> Ensure disks are mounted to /mnt and /mnt/boot."
sleep 3

# 1. Install Base System
echo ">>> Installing base system with basestrap..."
basestrap /mnt base base-devel runit linux linux-firmware

# 2. Generating FSTAB
echo ">>> Generating fstab..."
fstabgen -U /mnt >> /mnt/etc/fstab

# 3. Enter chroot
artix-chroot /mnt /bin/bash <<'EOF'
export PS1="(artix-runit) ${PS1}"

# Localization
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "artix" > /etc/hostname

# Networking & Utilities
pacman -S --noconfirm networkmanager-runit connman-runit vim nano cronie-runit

# Enabling services in Runit (symlinking to /etc/runit/runsvdir/default)
ln -s /etc/runit/sv/NetworkManager /etc/runit/runsvdir/default/
ln -s /etc/runit/sv/cronie /etc/runit/runsvdir/default/

# ----------------------------------------------------------
# Bootloader
# ----------------------------------------------------------
pacman -S --noconfirm grub efibootmgr

grub-install \
  --target=x86_64-efi \
  --efi-directory=/boot \
  --bootloader-id=Artix

grub-mkconfig -o /boot/grub/grub.cfg
EOF

# 4. Root password
echo ">>> Set root password"
artix-chroot /mnt /bin/bash -c 'passwd'

echo "=================================================="
echo " Artix Runit UEFI installation complete!"
echo "=================================================="
