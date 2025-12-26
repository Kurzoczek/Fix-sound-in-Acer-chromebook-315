#!/bin/bash

# =====================================================================
# AUTOMATED TWO-PHASE RECOVERY (KERNEL 6.8 + FILE VERIFICATION)
# =====================================================================

set -e
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAG_FILE="$BASE_DIR/.recovery_in_progress"
TARGET_VERSION="6.8.0"

# 1. Root check
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: Please run this script with sudo (sudo ./restore_audio.sh)!" 
   exit 1
fi

# --- Helper Function: Copying with .backup support ---
smart_copy() {
    local src_path=$1    # Source path without .backup
    local dest_path=$2   # Full destination path
    local perms=$3       # Permissions (e.g., 644)
    
    if [ -f "$src_path" ]; then
        cp "$src_path" "$dest_path"
    elif [ -f "${src_path}.backup" ]; then
        cp "${src_path}.backup" "$dest_path"
    else
        echo "Warning: Could not find file $src_path or its .backup copy"
        return 1
    fi

    # Call verification after copying
    verify_copy "$dest_path" "$perms"
}

# --- Helper Function: File and Permissions Verification ---
verify_copy() {
    local file=$1
    local expected_perms=$2

    if [ -f "$file" ]; then
        # Set permissions and ownership
        chmod "$expected_perms" "$file"
        chown root:root "$file"
        
        # Get actual permissions for display
        local current_perms=$(stat -c "%a" "$file")
        echo "VERIFIED: $file [OK] (Permissions: $current_perms)"
    else
        echo "CRITICAL ERROR: File $file was not copied correctly!"
        exit 1
    fi
}

# PHASE 2: Logic after reboot
if [ -f "$FLAG_FILE" ]; then
    CURRENT_KERNEL=$(uname -r)
    echo "--- Phase 2: Kernel Verification & Final Configuration ---"
    
    if [[ "$CURRENT_KERNEL" == *"$TARGET_VERSION"* ]]; then
        echo "SUCCESS: Correct kernel detected ($CURRENT_KERNEL)."
        
        # [4/6] Restoring Kernel Parameters
        echo "Restoring alsa-base.conf..."
        smart_copy "$BASE_DIR/audio_backup_main/etc/modprobe.d/alsa-base.conf" "/etc/modprobe.d/alsa-base.conf" "644"

        # [5/6] Restoring UCM and Firmware resources
        echo "Restoring UCM and Firmware resources..."
        TARGET_UCM="/usr/share/alsa/ucm2/sofrt5650"
        mkdir -p "$TARGET_UCM" /lib/firmware/intel/sof /lib/firmware/intel/sof-tplg
        
        # UCM files
        smart_copy "$BASE_DIR/audio_backup_main/usr/share/alsa/ucm2/sofrt5650/HiFi.conf" "$TARGET_UCM/HiFi.conf" "644"
        
        # Logic for the main UCM configuration file
        if [ -f "$BASE_DIR/audio_backup_main/usr/share/alsa/ucm2/sofrt5650/sofrt5650.conf" ]; then
             cp "$BASE_DIR/audio_backup_main/usr/share/alsa/ucm2/sofrt5650/sofrt5650.conf" "$TARGET_UCM/"
        elif [ -f "$BASE_DIR/audio_backup_main/usr/share/alsa/ucm2/sofrt5650/sofrt5650.conf.backup" ]; then
             cp "$BASE_DIR/audio_backup_main/usr/share/alsa/ucm2/sofrt5650/sofrt5650.conf.backup" "$TARGET_UCM/sofrt5650.conf"
        else
             # Fallback to older naming convention if found
             cp "$BASE_DIR/audio_backup_main/usr/share/alsa/ucm2/sofrt5650/sof-rt5650.conf" "$TARGET_UCM/sofrt5650.conf" 2>/dev/null || true
        fi
        verify_copy "$TARGET_UCM/sofrt5650.conf" "644"
        
        # Internal naming correction within UCM configs
        find "$TARGET_UCM" -type f -name "*.conf" -exec sed -i 's/sof-rt5650/sofrt5650/g' {} +
        
        # Firmware and Topologies
        smart_copy "$BASE_DIR/system_audio_resources/sof-firmware/sof-jsl.ri" "/lib/firmware/intel/sof/sof-jsl.ri" "644"
        
        # Iterate and verify all .tplg files
        for tplg in "$BASE_DIR/system_audio_resources/sof-tplg/"*.tplg; do
            [ -e "$tplg" ] || continue
            dest="/lib/firmware/intel/sof-tplg/$(basename "$tplg")"
            cp "$tplg" "$dest"
            verify_copy "$dest" "644"
        done

        # [6/6] Final system configuration
        echo "Restoring Mixer state..."
        smart_copy "$BASE_DIR/audio_backup_main/var/lib/alsa/asound.state" "/var/lib/alsa/asound.state" "644"
        
        update-initramfs -u -k "$CURRENT_KERNEL"
        
        # Cleanup auto-start entry
        rm "$FLAG_FILE"
        sed -i '/restore_audio.sh/d' "/home/$SUDO_USER/.bashrc"
        
        echo "-------------------------------------------------------"
        echo "DONE! Audio configuration completed on Kernel $TARGET_VERSION."
        echo "On next reboot, the system will return to the default kernel."
        echo "-------------------------------------------------------"
        exit 0
    else
        echo "ERROR: System booted with kernel $CURRENT_KERNEL."
        echo "Please restart and select Kernel 6.8 in GRUB 'Advanced Options'."
        exit 1
    fi
fi

# PHASE 1: Kernel installation and one-time boot setup
echo "--- Phase 1: Preparing Kernel 6.8 ---"

if [ ! -d "$BASE_DIR/audio_backup_main" ] || [ ! -d "$BASE_DIR/system_audio_resources" ]; then
    echo "ERROR: Backup directories not found in $BASE_DIR!"
    exit 1
fi

apt update
apt install -y linux-image-6.8.0-generic linux-headers-6.8.0-generic linux-modules-extra-6.8.0-generic

# Try to identify GRUB menu entry for 6.8
MENU_ENTRY=$(grep -e "menuentry '.*6.8.0-generic" /boot/grub/grub.cfg | head -n 1 | cut -d"'" -f2)

if [ -n "$MENU_ENTRY" ]; then
    echo "Found GRUB entry: $MENU_ENTRY"
    grub-reboot "1>$MENU_ENTRY"
    echo "System set to boot Kernel 6.8 for the next restart only."
else
    echo "Warning: Kernel 6.8 not found in grub.cfg. Please select it manually during reboot."
fi

# Arm the script for Phase 2
touch "$FLAG_FILE"
if ! grep -q "restore_audio.sh" "/home/$SUDO_USER/.bashrc"; then
    echo "sudo $BASE_DIR/restore_audio.sh" >> "/home/$SUDO_USER/.bashrc"
fi

echo "-------------------------------------------------------"
echo "PHASE 1 COMPLETE."
echo "The system will now reboot into Kernel 6.8."
echo "-------------------------------------------------------"
read -p "Reboot now? (y/n) " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && reboot
