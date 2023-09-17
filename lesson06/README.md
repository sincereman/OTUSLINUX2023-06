
# NFS, FUSE - Lesson 06


## Цель домашнего задания 
- Научиться самостоятельно развернуть сервис NFS и подключить к нему клиента 
## Описание домашнего задания 
Основная часть: 
- `vagrant up` должен поднимать 2 настроенных виртуальных машины (сервер NFS и клиента) без дополнительных ручных действий; - на сервере NFS должна быть подготовлена и экспортирована директория; 
- в экспортированной директории должна быть поддиректория с именем __upload__ с правами на запись в неё; 
- экспортированная директория должна автоматически монтироваться на клиенте при старте виртуальной машины (systemd, autofs или fstab -  любым способом); 
- монтирование и работа NFS на клиенте должна быть организована с использованием NFSv3 по протоколу UDP; 
- firewall должен быть включен и настроен как на клиенте, так и на сервере. 
Для самостоятельной реализации: 
- настроить аутентификацию через KERBEROS с использованием NFSv4. ## Инструкция по выполнению домашнего задания 

Требуется предварительно установленный и работоспособный [Hashicorp  Vagrant](https://www.vagrantup.com/downloads) и [Oracle VirtualBox] (https://www.virtualbox.org/wiki/Linux_Downloads). Также имеет смысл предварительно загрузить образ CentOS 7 2004.01 из Vagrant Cloud  командой 

```shell
vagrant box add centos/7 --provider virtualbox --box version 2004.01 --clean
```
, т.к. предполагается, что дальнейшие действия будут производиться на таких образах.
Все дальнейшие действия были проверены при использовании CentOS  7.9.2009 в качестве хостовой ОС, Vagrant 2.2.18, VirtualBox v6.1.26  и образа CentOS 7 2004.01 из Vagrant Cloud. Серьёзные отступления от этой конфигурации могут потребовать адаптации с вашей стороны. 


### Создаём тестовые виртуальные машины 

Создаем директорию basehomework и переходим в нее, в ней создаем Vagrantfile

```shell
mkdir basehomework && cd basehomework
vagrant init

```


Используем предлагаемый шаблон для создания виртуальных машин (правим ip адреса под свою сеть)): 

```shell
cat Vagrantfile 

# -*- mode: ruby -*- 
# vi: set ft=ruby : vsa
Vagrant.configure(2) do |config| 
 config.vm.box = "centos/7" 
 config.vm.box_version = "2004.01" 
 config.vm.provider "virtualbox" do |v| 
 v.memory = 256 
 v.cpus = 1 
 end 
 config.vm.define "nfss" do |nfss| 
 nfss.vm.network "private_network", ip: "192.168.56.10",  virtualbox__intnet: "net1" 
 nfss.vm.hostname = "nfss" 
 end 
 config.vm.define "nfsc" do |nfsc| 
 nfsc.vm.network "private_network", ip: "192.168.56.11",  virtualbox__intnet: "net1" 
 nfsc.vm.hostname = "nfsc" 
 end 
end 
``` 

В результате выполнения команды `vagrant up` стали доступны 2 виртуальных машины: __nfss__ для сервера NFS и __nfsc__ для клиента. 


### Настраиваем сервер NFS 

- заходим на сервер 
```shell 
vagrant ssh nfss 
``` 
Дальнейшие действия выполняются __от имени пользователя имеющего повышенные привилегии__, разрешающие описанные действия. 
- сервер NFS уже установлен в CentOS 7 как часть дистрибутива, так что нам нужно лишь доустановить утилиты, которые облегчат отладку 

```shell 
sudo -s
yum -y install nfs-utils 
``` 
- включаем firewall

```shell

systemctl enable firewalld --now 

```

- разрешаем в firewall доступ к сервисам NFS 

```shell
firewall-cmd --add-service="nfs3" --add-service="rpc-bind" --add-service="mountd" --permanent 
firewall-cmd --reload

``` 
- включаем сервер NFS (конфигурация в файле __/etc/nfs.conf__) 

```shell
systemctl enable nfs --now 
``` 
- проверяем наличие слушаемых портов 2049/udp, 2049/tcp, 20048/udp,  20048/tcp, 111/udp, 111/tcp (не все они будут использоваться далее,  но их наличие сигнализирует о том, что необходимые сервисы готовы принимать внешние подключения) 

```shell
ss -tnplu | grep 2049 #Проверим что слушается порт 2049
firewall-cmd --list-all
``` 
Вывод

```shell

sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: eth0 eth1
  sources: 
  services: dhcpv6-client mountd nfs3 rpc-bind ssh
  ports: 
  protocols: 
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 

ss -tnplu

tcp    LISTEN     0      64                               [::]:2049               


- создаём и настраиваем директорию, которая будет экспортирована в будущем 

```shell

mkdir -p /srv/share/upload 
chown -R nfsnobody:nfsnobody /srv/share 
chmod 0777 /srv/share/upload 

``` 
- создаём в файле __/etc/exports__ структуру, которая позволит экспортировать ранее созданную директорию 

```shell
echo "/srv/share 192.168.56.11/32(rw,sync,no_root_squash)" > /etc/exports
``` 
- экспортируем ранее созданную директорию 

```shell
exportfs -r 
``` 
- проверяем экспортированную директорию следующей командой

 ```shell
exportfs -s 
```

Вывод: 

```shell
[root@nfss vagrant]# exportfs -s
/srv/share  192.168.56.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
``` 

### Настраиваем клиент NFS 
- заходим на сервер 

```shell 
vagrant ssh nfsc 
``` 
Дальнейшие действия выполняются __от имени пользователя имеющего повышенные привилегии__, разрешающие описанные действия. 
- доустановим вспомогательные утилиты 

```bash 
sudo -s
yum install nfs-utils 
``` 
- включаем firewall и проверяем, что он работает (доступ к SSH  обычно включен по умолчанию, поэтому здесь мы его не затрагиваем, но имейте это ввиду, если настраиваете firewall с нуля)

```shell
systemctl enable firewalld --now 
systemctl status firewalld 
``` 
- добавляем в __/etc/fstab__ строку_ 

```shell
echo "192.168.56.10:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab
``` 
и выполняем 
```shell
systemctl daemon-reload 
systemctl restart remote-fs.target 
``` 
Отметим, что в данном случае происходит автоматическая генерация systemd units в каталоге `/run/systemd/generator/`, которые производят монтирование при первом обращении к катаmcлогу `/mnt/` - заходим в директорию `/mnt/` и проверяем успешность монтирования 

```shell

mount | grep mnt 
``` 

При успехе вывод должен примерно соответствовать этому 

```shell
[root@nfsc mnt]# mount | grep mnt 

mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=27,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=25337)
192.168.56.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.56.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.56.10)

``` 

Обратите внимание на `vers=3` и `proto=udp`, что соотвествует NFSv3  over UDP, как того требует задание.


### Проверка работоспособности 

 - Сервер

```shell
cd /srv/share/upload/
echo "testlinenfs" >> nfs_control_file
cat nfs_control_file

showmount -a 192.168.56.10
All mount points on 192.168.56.10

```

- Клиент

```shell
cd /mnt/upload
grep -r testlinenfs nfs_control_file
showmount -a 192.168.56.10

showmount -a 192.168.56.10
All mount points on 192.168.56.10:
192.168.56.11:/srv/share


```

### Итоговый стенд


#### Vagrantfile


```shell

# -*- mode: ruby -*- 
# vi: set ft=ruby : vsa
Vagrant.configure(2) do |config| 
      config.vm.box = "centos/7" 
      config.vm.box_version = "2004.01" 
      config.vm.provider "virtualbox" do |v| 
          v.memory = 256 
          v.cpus = 1 
      end 
      config.vm.define "nfss" do |nfss| 
          nfss.vm.network "private_network", ip: "192.168.56.10",  virtualbox__intnet: "net1" 
          nfss.vm.hostname = "nfss" 
          nfss.vm.provision "shell", path: "nfss_script.sh"
      end 
      config.vm.define "nfsc" do |nfsc| 
          nfsc.vm.network "private_network", ip: "192.168.56.11",  virtualbox__intnet: "net1" 
          nfsc.vm.hostname = "nfsc"
          nfsc.vm.provision "shell", path: "nfsc_script.sh"
      end
    end 



```


#### nfss_script.sh

```shell

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
echo "/srv/share 192.168.56.11/32(rw,sync,root_squash)" > /etc/exports
echo "Export FS"
exportfs -r
echo "Check exportFS"
exportfs -s

cd /srv/share/upload/
echo "testlinenfs" >> nfs_control_file

```

#### nfsc_script.sh
```shell

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



```




