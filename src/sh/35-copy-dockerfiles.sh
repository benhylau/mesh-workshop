#!/usr/bin/env bash

# Copy docker directory if it exists in conf.d
if [ -d /mnt/conf.d/docker ]; then
  cp -r /mnt/conf.d/docker /root/
fi