# ----------------------------------------------------------
# made by beamyyl
# This is the UEFI Artix s6 installer.
# ----------------------------------------------------------
#!/bin/bash
set -e

echo "ParallelDownloads = 5" >> /etc/pacman.conf
basestrap /mnt base base-devel s6-base elogind-s6 linux linux-firmware
fstabgen -U /mnt >> /mnt/etc/fstab

artix-chroot /mnt /bin/bash <<'EOF'
export PS1="(artix-s6) ${PS1}"

ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "artix" > /etc/hostname

# Networking & Utilities
pacman -S --noconfirm networkmanager-s6 connman-s6 vim nano cronie-s6
touch /etc/s6/adminsv/default/contents.d/networkmanager
touch /etc/s6/adminsv/default/contents.d/cronie

pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg
EOF

artix-chroot /mnt /bin/bash -c 'passwd'
