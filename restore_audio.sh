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
