# Start mesh services
systemctl start cjdns
systemctl start yggdrasil

# Start mdns service
systemctl start avahi-daemon