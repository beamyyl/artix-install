#!/bin/bash
# =============================================================================
# YAAIS (Yet Another Artix Install Script)
# Supports: UEFI / BIOS + OpenRC, runit, dinit, s6
# =============================================================================

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
die()   { echo -e "${RED}[FAIL]${NC}  $*"; exit 1; }
ask()   { echo -e "${CYAN}[INPUT]${NC} $*"; }

for cmd in basestrap fstabgen artix-chroot; do
    command -v "$cmd" &>/dev/null \
        || die "'$cmd' not found. Are you booted from the Artix live ISO?"
done

clear
echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}=                    ARTIX INSTALLER                       =${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""
info "This script will install Artix to /mnt/"
info "Your partitions must be formatted and mounted BEFORE continuing."
echo ""
echo "Here are some partition examples:"
echo "  Mount commands (UEFI):"
echo ""
echo "    mount /dev/sda2 /mnt/gentoo --mkdir"
echo "    mount /dev/sda1 /mnt/gentoo/efi --mkdir"
echo ""
echo "  For BIOS/GPT, you MUST have a 1MB BIOS BOOT partition."
echo "  Do NOT format or mount it."
echo ""
echo "  Mount commands (BIOS):"
echo ""
echo "    mount /dev/sda1 /mnt/gentoo --mkdir"
echo ""
warn "If your partitions are NOT yet mounted, press Ctrl+C now,"
warn "mount them, then re-run this script."
echo ""
read -rp "  Press ENTER once your partitions are mounted..."
echo ""

mountpoint -q /mnt || die "/mnt is not mounted."
info "Root mount point verified."
echo ""

info "============================================================"
info " BOOT MODE, INIT SYSTEM"
info "============================================================"
echo ""

ask "Boot mode — UEFI or BIOS?"
ask "  1) UEFI  (modern systems, GPT disk)"
ask "  2) BIOS  (legacy / older systems, MBR or GPT disk)"
read -rp "  Choice [1/2]: " BOOT_CHOICE
case "$BOOT_CHOICE" in
    1) BOOT_MODE="uefi" ;;
    2) BOOT_MODE="bios" ;;
    *) die "Invalid choice. Enter 1 or 2." ;;
esac
echo ""

if [ "$BOOT_MODE" = "uefi" ]; then
    mountpoint -q /mnt/boot/efi \
        || die "/mnt/boot/efi is not mounted. Mount your EFI partition and re-run."
    info "UEFI mode selected. EFI mount verified."
else
    info "BIOS mode selected."
    echo ""
    ask "Enter the disk to install GRUB to (e.g. /dev/sda, /dev/vda)."
    ask "Whole disk, NOT a partition."
    read -rp "  Install disk: " GRUB_DISK
    [ -z "$GRUB_DISK" ] && die "Disk cannot be empty."
    [ -b "$GRUB_DISK" ] || die "'$GRUB_DISK' is not a valid block device."
    info "GRUB will be installed to: $GRUB_DISK"
fi
echo ""

ask "Init system?"
ask "  1) OpenRC"
ask "  2) runit"
ask "  3) dinit"
ask "  4) s6"
read -rp "  Choice [1-4]: " INIT_CHOICE
case "$INIT_CHOICE" in
    1) INIT_SYSTEM="openrc" ;;
    2) INIT_SYSTEM="runit"  ;;
    3) INIT_SYSTEM="dinit"  ;;
    4) INIT_SYSTEM="s6"     ;;
    *) die "Invalid choice. Enter 1, 2, 3, or 4." ;;
esac
echo ""
info "Selected: boot=$BOOT_MODE  init=$INIT_SYSTEM"
echo ""

info "============================================================"
info " SYSTEM CONFIGURATION"
info "============================================================"
echo ""

ask "Enter a hostname for your new system."
read -rp "  Hostname: " NEW_HOSTNAME
[ -z "$NEW_HOSTNAME" ] && die "Hostname cannot be empty."
echo ""

info "Configuration summary:"
echo "   Boot mode : $BOOT_MODE"
echo "   Init      : $INIT_SYSTEM"
echo "   Hostname  : $NEW_HOSTNAME"
echo ""
read -rp "  Press ENTER to continue..."
echo ""

info "============================================================"
info " BASE INSTALL"
info "============================================================"
echo ""

info "Installing the kernel, base, and $INIT_SYSTEM..."
basestrap /mnt linux linux-firmware sof-firmware base base-devel "${INIT_SYSTEM}" "elogind-${INIT_SYSTEM}"

info "============================================================"
info " FSTAB"
info "============================================================"

info "Generating /etc/fstab..."
fstabgen -U /mnt > /mnt/etc/fstab
info "fstab contents:"
cat /mnt/etc/fstab
echo ""

info "============================================================"
info " WRITING IN-CHROOT SCRIPT"
info "============================================================"

cat > /mnt/root/chroot-install.sh <<CHROOT_EOF
#!/bin/bash
set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "\${GREEN}[CHROOT]\${NC}  \$*"; }
warn()  { echo -e "\${YELLOW}[CHROOT]\${NC}  \$*"; }

BOOT_MODE="${BOOT_MODE}"
INIT_SYSTEM="${INIT_SYSTEM}"
NEW_HOSTNAME="${NEW_HOSTNAME}"
GRUB_DISK="${GRUB_DISK}"

hwclock --systohc
pacman -Sy --noconfirm

echo "\${NEW_HOSTNAME}" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   \${NEW_HOSTNAME}.localdomain \${NEW_HOSTNAME}
EOF

case "\${INIT_SYSTEM}" in
    openrc)
        pacman -S --noconfirm dbus-openrc networkmanager-openrc cronie-openrc vim nano
        rc-update add elogind default
        rc-update add dbus default
        rc-update add NetworkManager default
        rc-update add cronie default
        ;;
    runit)
        pacman -S --noconfirm dbus-runit networkmanager-runit cronie-runit vim nano
        ln -s /etc/runit/sv/dbus          /etc/runit/runsvdir/default/
        ln -s /etc/runit/sv/elogind       /etc/runit/runsvdir/default/
        ln -s /etc/runit/sv/NetworkManager /etc/runit/runsvdir/default/
        ln -s /etc/runit/sv/cronie        /etc/runit/runsvdir/default/
        ;;
    dinit)
        pacman -S --noconfirm dbus-dinit networkmanager-dinit cronie-dinit vim nano
        ln -s ../dbus           /etc/dinit.d/boot.d/
        ln -s ../elogind        /etc/dinit.d/boot.d/
        ln -s ../NetworkManager /etc/dinit.d/boot.d/
        ln -s ../cronie         /etc/dinit.d/boot.d/
        ;;
    s6)
        pacman -S --noconfirm dbus-s6 networkmanager-s6 cronie-s6 vim nano
        touch /etc/s6/adminsv/default/contents.d/dbus
        touch /etc/s6/adminsv/default/contents.d/elogind
        touch /etc/s6/adminsv/default/contents.d/NetworkManager
        touch /etc/s6/adminsv/default/contents.d/cronie
        s6-db-reload && s6-rc -u change dbus
        s6-db-reload && s6-rc -u change elogind
        s6-db-reload && s6-rc -u change NetworkManager
        s6-db-reload && s6-rc -u change cronie
        ;;
esac

# Generate the locales
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

info "Installing GRUB..."

if [ "\${BOOT_MODE}" = "uefi" ]; then
    pacman -S --noconfirm grub efibootmgr
    grub-install --target=x86_64-efi --efi-directory=/boot/efi
else
    pacman -S --noconfirm grub
    grub-install --recheck "\${GRUB_DISK}"
fi

grub-mkconfig -o /boot/grub/grub.cfg

echo ""
info "============================================================"
info " Set the ROOT password:"
info "============================================================"
passwd

echo ""
echo -e "\${CYAN}[INPUT]\${NC} Would you like to create a new user? (y/n)"
read -rp "  Choice: " CREATE_USER

if [ "\${CREATE_USER}" = "y" ]; then
    echo -e "\${CYAN}[INPUT]\${NC} Enter the new username:"
    read -rp "  Username: " NEW_USER
    if [ -z "\${NEW_USER}" ]; then
        warn "No username entered — skipping user creation."
    else
        useradd -m -G wheel,audio,video,input -s /bin/bash "\${NEW_USER}"
        info "User '\${NEW_USER}' created and added to: wheel, audio, video, input"
        info "Set a password for '\${NEW_USER}':"
        passwd "\${NEW_USER}"
        info "User setup complete."
    fi
else
    info "Skipping user creation."
fi

echo ""
info "============================================================"
info " Installation complete!"
info "============================================================"
info " Exit the chroot and reboot:"
info ""
info "   exit"
info "   umount -R /mnt"
info "   reboot"
info "============================================================"
CHROOT_EOF

chmod +x /mnt/root/chroot-install.sh
info "In-chroot script written."
echo ""

info "============================================================"
info " ENTERING CHROOT"
info "============================================================"
echo ""

artix-chroot /mnt /bin/bash /root/chroot-install.sh

info "============================================================"
info " CLEANUP"
info "============================================================"

rm -f /mnt/root/chroot-install.sh

info "Unmounting filesystems..."
umount -R /mnt 2>/dev/null

echo ""
info "============================================================"
info " All done! Remove your installation media and reboot."
info "============================================================"
