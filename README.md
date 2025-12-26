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
4. **Run the script** with **root** 👑 privileges:
   ```bash
   sudo chmod +x restore_audio.sh
   sudo ./restore_audio.sh

**🛠️ Behind the Scenes (The Magic Sequence) 🪄**
Ever wondered what's happening under the hood while you wait for your sound to return? Here is the step-by-step breakdown:

   **Phase 1: The Preparation 🏗️**
      The Kernel Hunt 🕵️‍♂️: The script tracks down and installs Kernel 6.8.0-generic. Why? Because it’s the "Goldilocks" version where your audio hardware feels right at home.

      GRUB Persuasion 🧠: We politely tell your bootloader (GRUB) to pick Kernel 6.8 for the next boot. It's like giving your laptop a "one-time VIP pass" to the older kernel.

      The "Don't Forget Me" Note 📝: The script leaves a tiny reminder in your .bashrc. It’s like a digital sticky note so it can wake up and finish the job after you reboot.

   **Phase 2: The Reboot 🔄**
      At this point, you take a sip of coffee while the machine restarts... ☕

   **Phase 3: The Grand Restoration 🔊**
      Verification Check 🧐: First, the script checks if you actually booted into Kernel 6.8. If not, it won't touch a thing! Safety first. 🛡️

**The Great Unpacking** 📦: 
      All this backed-up audio files (alsa-base.conf, asound.state, and those tricky UCM files) are moved back to their rightful homes in /etc/ and /usr/share/. 🏠

**Firmware Handshake** 🤝: 
      It copies the sof-jsl firmware and topology files so the hardware finally knows how to speak "Sound."

**Mission Accomplished!** 🎉: 
      It cleans up the "sticky note" from your .bashrc, resets the GRUB settings, and tells you to enjoy your music! 🎶 💃
<br><br>
***ENJO YOUR SOUND 🥳🎉🎶🎧***
