#!/usr/bin/env bash

# Create an additional 6G partition on the sdcard
{
  echo label: dos
  echo label-id: 0x00000000
  echo device: /dev/mmcblk0
  echo unit: sectors

  echo /dev/mmcblk0p1 : start=        2048, size=     2048000, type=6, bootable
  echo /dev/mmcblk0p2 : start=     2050048, size=    12288000, type=83
} | sfdisk --no-reread /dev/mmcblk0

# Tell kernel the sdcard partitions have been updated
partx --update /dev/mmcblk0

# Use new partition as swap memory
mkswap /dev/mmcblk0p2
swapon /dev/mmcblk0p2

# Use the swap memory to back the ramdisk file system
mount -o remount,size=6000000k,nr_inodes=2000000 /