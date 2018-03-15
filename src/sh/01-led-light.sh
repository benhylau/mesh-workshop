#!/bin/sh
echo LED Indicator
mount >> /var/log/test1
mount -t sysfs sysfs /sys
ls /sys/class  >>/var/log/test1
ls /sys/class/led  >>/var/log/test1
echo heartbeat > /sys/class/leds/led1/trigger 
echo none > /sys/class/leds/led0/trigger
echo 0 > /sys/class/leds/led0/brightness
echo '#!/bin/sh' > /etc/rc.local
echo "echo 1 > /sys/class/leds/led1/brightness" >> /etc/rc.local
echo "echo 1 > /sys/class/leds/led0/brightness" >> /etc/rc.local
echo "exit 0" >> /etc/rc.local
chmod +x /etc/rc.local

