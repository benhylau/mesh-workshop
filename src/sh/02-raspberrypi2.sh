#!/bin/sh
if [[ "$(cat /sys/firmware/devicetree/base/model | awk '{print $3}')" == "2" ]]; then
    sed -i "s/ath9k_htc //" /etc/systemd/network/85-wlan-mesh.link
    sed -i "s/ath9k_htc //" /etc/systemd/network/85-wlan-mesh.network
fi
