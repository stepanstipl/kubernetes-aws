#!/bin/bash

trap 'echo "Shutting down"; exit 0' SIGKILL SIGTERM SIGHUP SIGINT EXIT

echo "Waiting for master persistent disk to be attached"
attempt=0
while true; do
  echo "Attempt $(($attempt+1)) to check for ${DRK_DEVICE}"
  if [[ -e ${DRK_DEVICE} ]]; then
    echo "Found ${DRK_DEVICE}"
    break
  fi
  attempt=$(($attempt+1))
  sleep 1
done

# Check if we have fs in the fstab already
echo "Checking if persistent disk is configured"
if (! grep -q "^${DRK_DEVICE}" /etc/fstab); then

  # Mount Master Persistent Disk
  echo "Mounting master persistend Disk"
  mkdir -p ${DRK_MOUNTPOINT}
  mkfs -t ext4 ${DRK_DEVICE}
  echo "${DRK_DEVICE} ${DRK_MOUNTPOINT} ext4 noatime  0 0" >> /etc/fstab
  mount ${DRK_MOUNTPOINT}
fi
