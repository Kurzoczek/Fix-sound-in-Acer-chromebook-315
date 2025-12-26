#!/bin/bash

# =====================================================================
# TWO-PHASE RECOVERY (ONE-TIME BOOT INTO KERNEL 6.8)
# =====================================================================

set -e
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Using a flag file in the script directory to keep it contained
FLAG_FILE="$BASE_DIR/.recovery_in_progress"
TARGET_VERSION="6.8.0"

# 1. Root check
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: Please run with sudo (sudo ./restore_audio.sh)!"
   exit 1
fi

# PHASE 2: Logic after reboot
if [ -f "$FLAG_FILE" ]; then
    CURRENT_KERNEL=$(uname -r)
    echo "--- Phase 2: Verification & Final Setup ---"

    if [[ "$CURRENT_KERNEL" == *"$TARGET_VERSION"* ]]; then
        echo "SUCCESS: Correct kernel detected ($CURRENT_KERNEL)."

        echo "[4/6] Restoring alsa-base.conf..."
        cp "$BASE_DIR/audio_backup_main/etc/modprobe.d/alsa-base.conf" /etc/modprobe.d/

        echo "[5/6] Restoring UCM & JSL Resources..."
        TARGET_UCM="/usr/share/alsa/ucm2/sofrt5650"
        mkdir -p "$TARGET_UCM" /lib/firmware/intel/sof /lib/firmware/intel/sof-tplg

        # Copying UCM files
        cp -L "$BASE_DIR/audio_backup_main/usr/share/alsa/ucm2/sofrt5650/"* "$TARGET_UCM/"
        find "$TARGET_UCM" -type f -name "*.conf" -exec sed -i 's/sof-rt5650/sofrt5650/g' {} +

        # Copying Firmware and Topologies
        cp "$BASE_DIR/system_audio_resources/sof-firmware/sof-jsl.ri" /lib/firmware/intel/sof/
        cp "$BASE_DIR/system_audio_resources/sof-tplg/"*.tplg /lib/firmware/intel/sof-tplg/

        echo "[6/6] Finalizing System..."
        cp "$BASE_DIR/audio_backup_main/var/lib/alsa/asound.state" /var/lib/alsa/ 2>/dev/null || true
        update-initramfs -u -k "$CURRENT_KERNEL"

        # Cleanup
        rm "$FLAG_FILE"
        sed -i '/restore_audio.sh/d' "/home/$SUDO_USER/.bashrc"

        echo "-------------------------------------------------------"
        echo "DONE! Audio configuration applied on Kernel $TARGET_VERSION."
        echo "On your NEXT reboot, the system will return to its default kernel."
        echo "-------------------------------------------------------"
        exit 0
    else
        echo "CRITICAL: System booted with kernel $CURRENT_KERNEL."
        echo "Manual intervention required: Restart and select Kernel 6.8 in GRUB."
        exit 1
    fi
fi

# PHASE 1: Kernel installation & One-time Boot setup
echo "--- Phase 1: Preparing Kernel 6.8 ---"

apt update
apt install -y linux-image-6.8.0-generic linux-headers-6.8.0-generic linux-modules-extra-6.8.0-generic

# Find the menu entry string for Kernel 6.8
# We look for the "Advanced options" menu and the specific kernel line
MENU_ENTRY=$(grep -e "menuentry '.*6.8.0-generic" /boot/grub/grub.cfg | head -n 1 | cut -d"'" -f2)

if [ -n "$MENU_ENTRY" ]; then
    echo "Found GRUB entry: $MENU_ENTRY"
    # Set one-time boot for the next restart only
    # Note: We use the submenu syntax: "Advanced options for Ubuntu>Entry Name"
    # This varies slightly by distro, so we use the index if possible or the name
    grub-reboot "1>$MENU_ENTRY"
    echo "System is set to boot Kernel 6.8 ONCE."
else
    echo "Warning: Could not automatically find GRUB entry name. Please select 6.8 manually."
fi

# Set auto-resume
touch "$FLAG_FILE"
if ! grep -q "restore_audio.sh" "/home/$SUDO_USER/.bashrc"; then
    echo "sudo $BASE_DIR/restore_audio.sh" >> "/home/$SUDO_USER/.bashrc"
fi

echo "-------------------------------------------------------"
echo "PHASE 1 COMPLETE."
echo "The system will reboot into Kernel 6.8 for one session."
echo "After that, it will revert to your standard default."
echo "-------------------------------------------------------"
read -p "Reboot now? (y/n) " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && reboot
