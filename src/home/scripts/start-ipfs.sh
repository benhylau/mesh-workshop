mount /dev/mmcblk0p1 /mnt

# Load ipfs docker archive
docker load --input /mnt/conf.d/docker/tomeshnet-ipfs-0.1.tar

# Start ipfs docker container
docker run --name ipfs --network host --detach tomeshnet/ipfs:0.1

umount /mnt