#!/bin/bash

echo "Create NFS Server"

echo "UP Privilege"    
sudo -s
mkdir -p ~root/.ssh
cp  ~vagrant/.ssh/auth* ~root/.ssh
echo "Install nfs-utils"
yum install -y nfs-utils 
echo "Set up a firewall"
systemctl enable firewalld --now
firewall-cmd --add-service="nfs3" --add-service="rpc-bind" --add-service="mountd" --permanent
firewall-cmd --reload
firewall-cmd --list-all
systemctl status firewalld
systemctl enable nfs --now
echo "Check an open port"
ss -tnplu | grep 2049
echo "Create a share"
mkdir -p /srv/share/upload
chown -R nfsnobody:nfsnobody /srv/share
chmod 0777 /srv/share/upload
echo "Set up the config nfs share"
echo "/srv/share 192.168.56.11/32(rw,sync,all_squash,no_subtree_check,root_squash)" > /etc/exports
echo "Export FS"
exportfs -r
echo "Check exportFS"
exportfs -s
#почему то права так и не примеяются
echo "Понизим права до пользователя" 
sudo su - vagrant
sleep 5
echo "The current user: $USER"
cd /srv/share/upload/
echo "testlinenfs" >> nfs_control_file
cat nfs_control_file