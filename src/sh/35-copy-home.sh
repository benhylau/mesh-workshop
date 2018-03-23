#!/usr/bin/env bash

# Copy content in home directory if it exists in conf.d
if [ -d /mnt/conf.d/home ]; then
  cp -r /mnt/conf.d/home/* /root/
fi
