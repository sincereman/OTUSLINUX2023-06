#!/bin/bash

echo "Start create RAID 5"

	      echo "Start create RAID 5"
              echo "Erase superblocks"
              sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
              echo "Create RAID 5"
              sudo mdadm --create --verbose /dev/md0 -l 5 -n 5 /dev/sd{b,c,d,e,f}
              echo "Wait a little time to create RAID"
              sleep 5
              sudo mkdir /etc/mdadm
              sudo -s
              echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
              echo "MDADM.conf"
              sudo mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
              cat /etc/mdadm/mdadm.conf
              echo "Create partition"
              sudo parted -s /dev/md0 mklabel gpt
              sudo parted /dev/md0 mkpart primary ext4 2048KiB 20%
              sudo parted /dev/md0 mkpart primary ext4 20% 40%
              sudo parted /dev/md0 mkpart primary ext4 40% 60%
              sudo parted /dev/md0 mkpart primary ext4 60% 80%
              sudo parted /dev/md0 mkpart primary ext4 80% 100%
              echo "Create Filesystem"
              for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
              sudo mkdir -p /raid/part{1,2,3,4,5}
              echo "Mount part to folders"
              for i in $(seq 1 5); do sudo mount /dev/md0p$i /raid/part$i; done
              echo "Create /etc/fstab"
              for i in $(seq 1 5); do sudo echo '/dev/md0p'$i' /raid/part'$i' ext4    defaults 1 2' | sudo tee -a /etc/fstab; done
              sleep 5
              cat /etc/fstab
              cat /proc/mdstat
