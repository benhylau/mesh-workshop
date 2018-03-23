while true; do { echo -e 'HTTP/1.1 200 OK\r\n'; echo -e "You have reached $(cat /etc/hostname) on $(date)"; } | nc -l -p 80; done
