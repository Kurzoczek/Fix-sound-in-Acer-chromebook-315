#!/bin/bash

# 1. Ewcovering UCM structure
sudo mkdir -p /usr/share/alsa/ucm2/sofrt5650
sudo cp /usr/share/alsa/ucm2/sof-rt5650/HiFi.conf /usr/share/alsa/ucm2/sofrt5650/
sudo cp /usr/share/alsa/ucm2/sof-rt5650/sof-rt5650.conf /usr/share/alsa/ucm2/sofrt5650/sofrt5650.conf
sudo sed -i 's/sof-rt5650/sofrt5650/g' /usr/share/alsa/ucm2/sofrt5650/sofrt5650.conf

# 2. Recovering driver parametrs
echo "options snd-intel-dspcfg dsp_driver=0" | sudo tee /etc/modprobe.d/alsa-base.conf
echo "options snd-hda-intel power_save=0" | sudo tee -a /etc/modprobe.d/alsa-base.conf
echo "options snd-sof-pci-intel-tgl disable_msi=1" | sudo tee -a /etc/modprobe.d/alsa-base.conf

# 3. System refresh
sudo alsactl init
systemctl --user restart pipewire pipewire-pulse wireplumber

echo "Repairing complete, chceck sound in all chanels, also check Alsamixer and unmute everythink, whats muted!!!"
