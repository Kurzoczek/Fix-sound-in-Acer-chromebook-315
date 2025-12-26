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
   echo "BŁĄD: Uruchom skrypt przez sudo (sudo ./restore_audio.sh)!"
   exit 1
fi

# --- Funkcja pomocnicza: Kopiowanie z obsługą .backup ---
smart_copy() {
    local src_path=$1    # Ścieżka źródłowa bez .backup
    local dest_path=$2   # Pełna ścieżka docelowa
    local perms=$3       # Uprawnienia (np. 644)

    if [ -f "$src_path" ]; then
        cp "$src_path" "$dest_path"
    elif [ -f "${src_path}.backup" ]; then
        cp "${src_path}.backup" "$dest_path"
    else
        echo "Ostrzeżenie: Nie znaleziono pliku $src_path ani jego kopii .backup"
        return 1
    fi

    # Wywołanie weryfikacji po kopiowaniu
    verify_copy "$dest_path" "$perms"
}

# --- Funkcja pomocnicza: Weryfikacja pliku i uprawnień ---
verify_copy() {
    local file=$1
    local expected_perms=$2

    if [ -f "$file" ]; then
        # Ustawienie uprawnień
        chmod "$expected_perms" "$file"
        chown root:root "$file"

        # Pobranie aktualnych uprawnień do wyświetlenia
        local current_perms=$(stat -c "%a" "$file")
        echo "ZWERYFIKOWANO: $file [OK] (Uprawnienia: $current_perms)"
    else
        echo "BŁĄD KRYTYCZNY: Plik $file nie został prawidłowo skopiowany!"
        exit 1
    fi
}

# PHASE 2: Logika po restarcie
if [ -f "$FLAG_FILE" ]; then
    CURRENT_KERNEL=$(uname -r)
    echo "--- Faza 2: Weryfikacja jądra i końcowa konfiguracja ---"

    if [[ "$CURRENT_KERNEL" == *"$TARGET_VERSION"* ]]; then
        echo "SUKCES: Wykryto poprawne jądro ($CURRENT_KERNEL)."

        # [4/6] Przywracanie parametrów jądra
        echo "Przywracanie alsa-base.conf..."
        smart_copy "$BASE_DIR/audio_backup_main/etc/modprobe.d/alsa-base.conf" "/etc/modprobe.d/alsa-base.conf" "644"

        # [5/6] Przywracanie zasobów UCM i Firmware
        echo "Przywracanie zasobów UCM i Firmware..."
        TARGET_UCM="/usr/share/alsa/ucm2/sofrt5650"
        mkdir -p "$TARGET_UCM" /lib/firmware/intel/sof /lib/firmware/intel/sof-tplg

        # UCM
        smart_copy "$BASE_DIR/audio_backup_main/usr/share/alsa/ucm2/sofrt5650/HiFi.conf" "$TARGET_UCM/HiFi.conf" "644"

        # Logika dla głównego pliku konfiguracyjnego UCM
        if [ -f "$BASE_DIR/audio_backup_main/usr/share/alsa/ucm2/sofrt5650/sofrt5650.conf" ]; then
             cp "$BASE_DIR/audio_backup_main/usr/share/alsa/ucm2/sofrt5650/sofrt5650.conf" "$TARGET_UCM/"
        elif [ -f "$BASE_DIR/audio_backup_main/usr/share/alsa/ucm2/sofrt5650/sofrt5650.conf.backup" ]; then
             cp "$BASE_DIR/audio_backup_main/usr/share/alsa/ucm2/sofrt5650/sofrt5650.conf.backup" "$TARGET_UCM/sofrt5650.conf"
        else
             cp "$BASE_DIR/audio_backup_main/usr/share/alsa/ucm2/sofrt5650/sof-rt5650.conf" "$TARGET_UCM/sofrt5650.conf" 2>/dev/null || true
        fi
        verify_copy "$TARGET_UCM/sofrt5650.conf" "644"

        # Korekta nazw wewnątrz plików UCM
        find "$TARGET_UCM" -type f -name "*.conf" -exec sed -i 's/sof-rt5650/sofrt5650/g' {} +

        # Firmware i Topologie
        smart_copy "$BASE_DIR/system_audio_resources/sof-firmware/sof-jsl.ri" "/lib/firmware/intel/sof/sof-jsl.ri" "644"

        # Kopiowanie wielu plików .tplg i ich weryfikacja
        for tplg in "$BASE_DIR/system_audio_resources/sof-tplg/"*.tplg; do
            [ -e "$tplg" ] || continue
            dest="/lib/firmware/intel/sof-tplg/$(basename "$tplg")"
            cp "$tplg" "$dest"
            verify_copy "$dest" "644"
        done

        # [6/6] Finalizacja systemu
        echo "Przywracanie stanu miksera..."
        smart_copy "$BASE_DIR/audio_backup_main/var/lib/alsa/asound.state" "/var/lib/alsa/asound.state" "644"

        update-initramfs -u -k "$CURRENT_KERNEL"

        # Usuwanie autostartu
        rm "$FLAG_FILE"
        sed -i '/restore_audio.sh/d' "/home/$SUDO_USER/.bashrc"

        echo "-------------------------------------------------------"
        echo "GOTOWE! Konfiguracja audio zakończona na jądrze $TARGET_VERSION."
        echo "Przy kolejnym restarcie system wróci do domyślnego jądra."
        echo "-------------------------------------------------------"
        exit 0
    else
        echo "BŁĄD: System uruchomiony na jądrze $CURRENT_KERNEL."
        echo "Zrestartuj i wybierz jądro 6.8 w menu GRUB (Advanced Options)."
        exit 1
    fi
fi

# PHASE 1: Instalacja jądra i ustawienie jednorazowego bootowania
echo "--- Faza 1: Przygotowanie jądra 6.8 ---"

if [ ! -d "$BASE_DIR/audio_backup_main" ] || [ ! -d "$BASE_DIR/system_audio_resources" ]; then
    echo "BŁĄD: Nie znaleziono katalogów backupu w $BASE_DIR!"
    exit 1
fi

apt update
apt install -y linux-image-6.8.0-generic linux-headers-6.8.0-generic linux-modules-extra-6.8.0-generic

MENU_ENTRY=$(grep -e "menuentry '.*6.8.0-generic" /boot/grub/grub.cfg | head -n 1 | cut -d"'" -f2)

if [ -n "$MENU_ENTRY" ]; then
    echo "Znaleziono wpis GRUB: $MENU_ENTRY"
    grub-reboot "1>$MENU_ENTRY"
    echo "System ustawiony na jednorazowy start jądra 6.8."
else
    echo "Ostrzeżenie: Nie znaleziono jądra 6.8 w grub.cfg. Wybierz je ręcznie przy restarcie."
fi

touch "$FLAG_FILE"
if ! grep -q "restore_audio.sh" "/home/$SUDO_USER/.bashrc"; then
    echo "sudo $BASE_DIR/restore_audio.sh" >> "/home/$SUDO_USER/.bashrc"
fi

echo "-------------------------------------------------------"
echo "FAZA 1 ZAKOŃCZONA."
echo "System zrestartuje się teraz w jądrze 6.8."
echo "-------------------------------------------------------"
read -p "Zrestartować teraz? (y/n) " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && reboot
