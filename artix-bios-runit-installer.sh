# ----------------------------------------------------------
# made by beamyyl
# This is the BIOS Artix Runit installer.
# ----------------------------------------------------------
#!/bin/bash
set -e

echo ">>> Ensure root is mounted to /mnt."
sleep 3

basestrap /mnt base base-devel runit elogind-runit linux linux-firmware
fstabgen -U /mnt >> /mnt/etc/fstab

artix-chroot /mnt /bin/bash <<'EOF'
export PS1="(artix-runit) ${PS1}"

ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "artix" > /etc/hostname

# Networking & Utilities
pacman -S --noconfirm networkmanager-runit connman-runit vim nano cronie-runit
# Runit service linking as per Wiki
ln -s /etc/runit/sv/NetworkManager /etc/runit/runsvdir/default
ln -s /etc/runit/sv/cronie /etc/runit/runsvdir/default

pacman -S --noconfirm grub
grub-install --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
EOF

artix-chroot /mnt /bin/bash -c 'passwd'
