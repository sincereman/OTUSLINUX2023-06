#!/bin/bash
 
echo "Create NFS Client"

echo "UP Privilege"    
sudo -s
mkdir -p ~root/.ssh
cp ~vagrant/.ssh/auth* ~root/.ssh
echo "Install nfs-utils"
yum install -y nfs-utils
echo "Set up a firewall"
systemctl enable firewalld --now
systemctl status firewalld
echo "Mount an NFS share"
echo "192.168.56.10:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab
echo "Restart NFS Service"
sleep 5
systemctl daemon-reload
systemctl restart remote-fs.target
sleep 5
echo "Check a mount point"
mount | grep mnt
echo "Check version NFS and UDP protocol"

cd /mnt/upload

echo "Если в следующей строке находится слово testlinenfs, то сервер NFS работает верно и клиент к нему подключился"
grep -r testlinenfs nfs_control_file
echo "Проверяем права у файла"
ls -la nfs_control_file

