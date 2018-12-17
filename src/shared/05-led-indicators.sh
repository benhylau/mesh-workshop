#!/usr/bin/env bash

# Configure LED indicators to indicate node status
echo Configure LED indicators

# Mount sys
mount -t sysfs sysfs /sys

# Turn off green LED
echo none > /sys/class/leds/led0/trigger
echo 0 > /sys/class/leds/led0/brightness

# Heartbeat trigger red LED
echo heartbeat > /sys/class/leds/led1/trigger

# Create binary that enables green and red LEDs
cat <<"EOF" >/usr/local/bin/led-indicators
#!/bin/sh

# Enable green and red LEDs
echo 1 >/sys/class/leds/led0/brightness
echo 1 >/sys/class/leds/led1/brightness
exit 0 
EOF
chmod +x /usr/local/bin/led-indicators

# Add systemd service to run led-indicators
cat <<"EOF" >/lib/systemd/system/led-indicators.service
[Unit]
Description=LED indicators of node status

[Service]
Type=idle
ExecStart=/usr/local/bin/led-indicators
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF