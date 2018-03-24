#!/bin/sh
echo LED Indicator
mount -t sysfs sysfs /sys
echo heartbeat > /sys/class/leds/led1/trigger 
echo none > /sys/class/leds/led0/trigger
echo 0 > /sys/class/leds/led0/brightness

cat <<"EOF"> /usr/local/bin/bootedled
#!/bin/sh
echo 1 > /sys/class/leds/led1/brightness 
echo 1 > /sys/class/leds/led0/brightness
exit 0 
EOF
chmod +x /usr/local/bin/bootedled

cat <<"EOF"> /lib/systemd/system/bootedled.service
[Unit]
Description=LED Boot
Wants=multi-user.target
After=multi-user.target

[Service]
Type=idle
ExecStart=/usr/local/bin/bootedled
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable bootedled.service
