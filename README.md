# Fix-sound-in-Acer-chromebook-315 for UBUNTU 24.04
Operating System: Kubuntu 24.04 KDE Plasma Version: 5.27.12 KDE Frameworks Version: 5.115.0 Qt Version: 5.15.13 Kernel Version: 6.12.0-061200-generic (64-bit) Graphics Platform: X11 Processors: 4 × Intel® N150 Memory: 7.6 GiB of RAM Graphics Processor: Mesa Intel® Graphics Manufacturer: Google Product Name: Rull System Version: rev3 . 


"Hi! Together with Gemini AI, I’ve developed a fix for Ubuntu 24.04 that enables the sof-rt5650 sound card on the Acer Chromebook 315 (Intel Alder Lake/Jasper Lake). You can find the system specifications at the beginning of the description.
In folder "audio_backup_rull" you have a files which are needed do proper work for soundcard. They are organize in proper folder tree.
<b>Requirements: script will install nesesery packages </b>

Kernel: This fix is designed for Linux Mainline Kernel 6.12 or newer.

Packages: Before applying the fix, ensure you have the necessary firmware installed: sudo apt update && sudo apt install firmware-sof-signed alsa-ucm-conf"
After applying a fix, remember to unmute all chanells in alsamixer, and set a proper audio output in GUI system mixser!!!
