# Fix-sound-in-Acer-chromebook-315 for UBUNTU 24.04
Operating System: Kubuntu 24.04 KDE Plasma Version: 5.27.12 KDE Frameworks Version: 5.115.0 Qt Version: 5.15.13 Kernel Version: 6.12.0-061200-generic (64-bit) Graphics Platform: X11 Processors: 4 × Intel® N150 Memory: 7.6 GiB of RAM Graphics Processor: Mesa Intel® Graphics Manufacturer: Google Product Name: Rull System Version: rev3 . 


"Hi! Together with Gemini AI, I’ve developed a fix for Ubuntu 24.04 that enables the sof-rt5650 sound card on the Acer Chromebook 315 (Intel Alder Lake/Jasper Lake). You can find the system specifications at the beginning of the description.
In folder "audio_backup_rull" you have a files which are needed do proper work for soundcard. They are organize in proper folder tree.
Requirements:

Kernel: This fix is designed for Linux Mainline Kernel 6.12 or newer.

Packages: Before applying the fix, ensure you have the necessary firmware installed: sudo apt update && sudo apt install firmware-sof-signed alsa-ucm-conf"
After applying a fix, remember to unmute all chanells in alsamixer, and set a proper audio output in GUI system mixser!!!
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Linux on Chromebook Rull - Setup Guide</title>
    <style>
        body { font-family: -apple-system, Segoe UI, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; max-width: 800px; margin: auto; padding: 20px; }
        h1 { border-bottom: 2px solid #eee; padding-bottom: 10px; color: #2c3e50; }
        h2 { color: #2980b9; margin-top: 30px; }
        code { background-color: #f4f4f4; padding: 2px 5px; border-radius: 3px; font-family: monospace; }
        pre { background: #2d3436; color: #dfe6e9; padding: 15px; border-radius: 5px; overflow-x: auto; font-family: monospace; }
        .warning { background-color: #fff3cd; border-left: 5px solid #ffeeba; padding: 15px; margin: 20px 0; }
        .success { color: #27ae60; font-weight: bold; }
        .issue { color: #e67e22; font-weight: bold; }
    </style>
</head>
<body>

    <h1>Linux on Chromebook "Rull" (Intel Jasper/Alder Lake)</h1>
    <p>This guide provides a verified procedure for setting up a fully functional Linux system (Ubuntu/Debian) on the "Rull" model.</p>

    <h2>1. Essential Audio Installation Procedure</h2>
    <div class="warning">
        <strong>CRITICAL STEP:</strong> To successfully initialize the SOF (Sound Open Firmware) driver, you must follow this specific sequence.
    </div>
    <ol>
        <li><strong>Kernel Downgrade:</strong> Temporarily switch back to a stable <strong>Kernel 6.8</strong> (e.g., the default Ubuntu 24.04 kernel).</li>
        <li><strong>SOF Configuration:</strong> Apply the modprobe fixes while running Kernel 6.8 and ensure firmware/topology files are present.</li>
        <li><strong>First Initialization:</strong> Reboot into Kernel 6.8. Once audio is successfully initialized and working, you can safely upgrade to <strong>Kernel 6.12/6.14</strong>.</li>
    </ol>
    <p><em>Note: Attempting a direct configuration on Kernel 6.14 often results in DSP initialization failures (IPC errors).</em></p>

    <h2>2. System and Kernel</h2>
    <ul>
        <li><strong>Target Version:</strong> Kernel 6.14.0 or newer (for full Wi-Fi 6E support and CPU optimizations).</li>
        <li><strong>Method:</strong> Stabilize on 6.8 first, then upgrade to the latest version.</li>
    </ul>

    <h2>3. Audio Fix (Configuration File)</h2>
    <p>Create the following file: <code>sudo nano /etc/modprobe.d/sof-fix.conf</code></p>
    <pre>options snd-sof-intel-hda-common dmic_num=2
options snd-sof-intel-hda-common hda_model=generic
options snd-intel-dspcfg dsp_driver=3</pre>

    <h2>4. Btrfs Optimization</h2>
    <p>For better performance and longevity on eMMC/SSD storage, use these mount options in <code>/etc/fstab</code>:</p>
    <pre>defaults,compress=zstd:3,autodefrag</pre>
    <p>This typically provides <strong>30-50% disk space savings</strong> on the system partition.</p>

    <h2>5. Log Cleanup (GRUB)</h2>
    <p>To silence harmless ACPI and UBSAN errors in Kernel 6.14, edit <code>/etc/default/grub</code>:</p>
    <pre>GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 ubsan_handle_misaligned_access_only i2c_designware.force_restart=1"</pre>
    <p>Apply changes with: <code>sudo update-grub</code></p>

    <h2>6. Hardware Status</h2>
    <ul>
        <li><span class="success">[✔] Wi-Fi 6E (AX211):</span> Working (Intel Firmware)</li>
        <li><span class="success">[✔] Bluetooth:</span> Working</li>
        <li><span class="success">[✔] Touchpad (Synaptics):</span> Working (Multitouch support)</li>
        <li><span class="success">[✔] Audio:</span> Working (Requires the Kernel 6.8 transition step)</li>
        <li><span class="issue">[!] Function Keys:</span> Known issue with EC communication (Packet too long error).</li>
    </ul>

</body>
</html>
