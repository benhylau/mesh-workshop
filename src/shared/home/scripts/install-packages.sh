mount /dev/mmcblk0p1 /mnt

# Install local debian packages
dpkg --install /mnt/conf.d/deb/*.deb

umount /mnt