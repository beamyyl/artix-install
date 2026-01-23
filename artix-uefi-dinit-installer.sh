# ----------------------------------------------------------
# made by beamyyl
# This is the UEFI Artix dinit installer.
# ----------------------------------------------------------
#!/bin/bash
set -e

echo "ParallelDownloads = 5" >> /etc/pacman.conf
basestrap /mnt base base-devel dinit elogind-dinit linux linux-firmware
fstabgen -U /mnt >> /mnt/etc/fstab

artix-chroot /mnt /bin/bash <<'EOF'
export PS1="(artix-dinit) ${PS1}"

ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "artix" > /etc/hostname

# Networking & Utilities
pacman -S --noconfirm networkmanager-dinit connman-dinit vim nano cronie-dinit
ln -s ../networkmanager /etc/dinit.d/boot.d/
ln -s ../cronie /etc/dinit.d/boot.d/

pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg
EOF

artix-chroot /mnt /bin/bash -c 'passwd'
