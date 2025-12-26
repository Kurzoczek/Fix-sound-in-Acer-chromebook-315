# Audio Recovery Tool for Intel JSL (RT5650)

This repository contains a complete automated recovery system for Intel Jasper Lake devices (like Chromebooks/Laptops) using the **RT5650** audio codec. It includes a two-phase script that manages a kernel downgrade and restores specific audio configurations.

## 📁 Directory Structure
- `audio_backup_main/`: Core system configuration files (`alsa-base.conf`, `asound.state`, UCM configs).
- `system_audio_resources/`: Hardware-specific binaries (`sof-jsl.ri` firmware and `.tplg` topologies).
- `restore_audio.sh`: The main automation engine.


<br><br>




**⚠️ IMPORTANT: SAFETY FIRST** **Please make a full backup of your important data before running this script (or do full system backup, if you feel uncomfortable with manipulation on workin machine 😛)** *While this script is designed for safety, kernel and system file modifications always carry risks.*




<br><br>



## 🚀 How to use it

1. **Clone or download** this repository to your local machine.
2. **Unpack 📦 or open main folder 📂**
3. **Open a terminal** 💻 inside the unpacked folder.
4. **Run the script** with root 👑 privileges:
   ```bash
   sudo chmod +x restore_audio.sh
   sudo ./restore_audio.sh

***ENJO YOUR SOUND 🥳🎉🎶🎧***
