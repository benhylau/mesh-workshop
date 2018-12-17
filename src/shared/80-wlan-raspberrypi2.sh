#!/usr/bin/env bash

# For Raspberry Pi 2, configure ath9k_htc and rtl8192cu interfaces as access points
grep -q "Raspberry Pi 2" /proc/device-tree/model
if [ $? -eq 0 ]; then
  sed -i "s/ ath9k_htc//" /etc/systemd/network/85-wlan-mesh.link
  sed -i "s/ ath9k_htc//" /etc/systemd/network/85-wlan-mesh.network
  sed -i "s/ rtl8192cu//" /etc/systemd/network/85-wlan-mesh.link
  sed -i "s/ rtl8192cu//" /etc/systemd/network/85-wlan-mesh.network
fi