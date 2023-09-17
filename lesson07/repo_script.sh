#!/bin/bash

echo "Create REPO Server"

echo "UP Privilege"    
sudo su

echo "Install required package" 
sudo yum install -y \
redhat-lsb-core \
wget \
rpmdevtools \
rpm-build \
createrepo \
yum-utils \
gcc \
openssl-devel

echo "GET nginx" 
wget https://nginx.org/packages/centos/8/SRPMS/nginx-1.24.0-1.el8.ngx.src.rpm

echo "Unpacking RPM" 
rpm -i nginx-1.*

echo "GET openssl" 
 wget https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1u/openssl-1.1.1u.tar.gz -O /root/openssl-1.1.1u.tar.gz


echo "Unpacking Openssl" 
 tar -xvf /root/openssl-1.1.1u.tar.gz -C /root/



echo "Prepare structure" 
yum-builddep  -y /root/rpmbuild/SPECS/nginx.spec

echo "Change parameters" 

echo "Add autoindex" 
 sed -i 's@index.htm;@index.htm;\n        autoindex on;@g' /root/rpmbuild/SOURCES/nginx.default.conf

echo "Add options openssl" 
 sed -i 's@--with-ld-opt="%{WITH_LD_OPT}" @--with-ld-opt="%{WITH_LD_OPT}" \\\n    --with-openssl=/root/openssl-1.1.1u @g' /root/rpmbuild/SPECS/nginx.spec


echo "Create a package" 
rpmbuild -bb /root/rpmbuild/SPECS/nginx.spec


echo "A little clean"

rm -rf /home/vagrant/nginx-1.24.0-1.el8.ngx.src.rpm

echo "Try to install nginx with SSL"

yum localinstall -y /root/rpmbuild/RPMS/x86_64/nginx-1.24.0-1.el8.ngx.x86_64.rpm

echo "Install and enable services"

systemctl enable nginx
systemctl start nginx

echo "Create a REPO dir"

mkdir -p /usr/share/nginx/html/repo

echo "Move to REPO dir my own rpm and percona from vendor"
cp /root/rpmbuild/RPMS/x86_64/nginx-1.24.0-1.el8.ngx.x86_64.rpm /usr/share/nginx/html/repo/nginx-1.24.0-1.el8.ngx_withopenssl.rpm
wget https://downloads.percona.com/downloads/percona-release/percona-release-1.0-6/redhat/percona-release-1.0-6.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-0.1-6.noarch.rpm

# test скачать пакеты с зависимостями
yum install -y --downloadonly --downloaddir="/usr/share/nginx/html/repo/" mc

echo "Create REPO"
createrepo /usr/share/nginx/html/repo/


echo "A little check"

systemctl status nginx
curl http://localhost/repo/



echo "Подключаем репозиторий в систему"

cat >> /etc/yum.repos.d/sincere2023.repo << EOF
[sincere2023]
name="sincere local repo"
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF



echo "Check repository"
yum repolist enabled | grep sincere2023

yum list | grep sincere2023

echo "Install Percona"

sudo yum install percona-release.noarch -y

echo "FINISH"

