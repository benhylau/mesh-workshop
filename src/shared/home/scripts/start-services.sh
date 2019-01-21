# Reload systemd manager configuration
systemctl daemon-reload

# Start haveged
systemctl start haveged

# Start mesh services
systemctl start cjdns
systemctl start yggdrasil

# Start mdns service
systemctl start avahi-daemon
