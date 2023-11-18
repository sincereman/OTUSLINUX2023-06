# Lesson36 -  VLAN и LACP.

## Цель: научиться настраивать VLAN и LACP

Описание/Пошаговая инструкция выполнения домашнего задания:

Для выполнения домашнего задания используйте методичку
https://docs.google.com/document/d/1BO5cUT0u4ABzEOjogeHyCaNiYh76Bh73/edit?usp=share_link&ouid=104106368295333385634&rtpof=true&sd=true
Что нужно сделать?
в Office1 в тестовой подсети появляется сервера с доп интерфесами и адресами
в internal сети testLAN

    testClient1 - 10.10.10.254
    testClient2 - 10.10.10.254
    testServer1- 10.10.10.1
    testServer2- 10.10.10.1
    развести вланами
    testClient1 <-> testServer1
    testClient2 <-> testServer2
    между centralRouter и inetRouter
    "пробросить" 2 линка (общая inernal сеть) и объединить их в бонд
    проверить работу c отключением интерфейсов
    Формат сдачи ДЗ - vagrant + ansible
    Обычно мы проверяем ДЗ в течение 48 часов.
    Если возникнут вопросы, обращайтесь к студентам, преподавателям и наставникам в канал группы в Slack.
    Удачи при выполнении!

# Выполнение


Создадим Vagrantfile


```shell

# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
  :inetRouter => {
        :box_name => "debian/bullseye64",
        :vm_name => "inetRouter",
        :net => [
                   #["10.4.111.51", 1, "255.255.255.0", "inet"],
                   [ "127.0.0.2",  2,  "255.255.255.0",  "router-net"],
                   [ "127.0.0.3",  3,  "255.255.255.0",  "router-net"],
                   #подсеть 192.168.56.0/24 - для связи с vagrant
                   [ "192.168.56.10", 8, "255.255.255.0",    "mgmt"],
                ]
  },
  :centralRouter => {
        :box_name => "debian/bullseye64",
        :vm_name => "centralRouter",
        :net => [
                   [ "127.0.0.4",  2,  "255.255.255.0",  "router-net"],
                   [ "127.0.0.5",  3,  "255.255.255.0",  "router-net"],
                   [ "192.168.255.9",  6,  "255.255.255.252",  "office1-central"],
                   [ "192.168.56.11",  8, "255.255.255.0",    "mgmt"],
                ]
  },

  :office1Router => {
        :box_name => "debian/bullseye64",
        :vm_name => "office1Router",
        :net => [
                   [ "192.168.255.10",  2,  "255.255.255.252",  "office1-central"],
                   [ "127.0.0.5",  3,  "255.255.255.0",  "vlan10"],
                   [ "127.0.0.6",  4,  "255.255.255.0",  "vlan10"],
                   [ "127.0.0.7",  5,  "255.255.255.0",  "vlan20"],
                   [ "127.0.0.8",  6,  "255.255.255.0",  "vlan20"],
                   [ "192.168.56.20",  8, "255.255.255.0",    "mgmt"],
                ]
  },

  :testClient1 => {
        :box_name => "debian/bullseye64",
        :vm_name => "testClient1",
        :net => [
                   [ "127.0.0.9",  2,  "255.255.255.0",  "vlan10"],
                   [ "192.168.56.21",  8, "255.255.255.0",    "mgmt"],
                ]
  },


  :testServer1 => {
        :box_name => "debian/bullseye64",
        :vm_name => "testServer1",
        :net => [
                   [ "127.0.0.10",  2,  "255.255.255.0",  "vlan10"],
                   [ "192.168.56.22",  8, "255.255.255.0",    "mgmt"],
                ]
  },
  

  :testClient2 => {
        :box_name => "debian/bullseye64",
        :vm_name => "testClient2",
        :net => [
                   [ "127.0.0.11",  2,  "255.255.255.0",  "vlan20"],
                   [ "192.168.56.31",  8, "255.255.255.0",    "mgmt"],
                ]
  },


  :testServer2 => {
        :box_name => "debian/bullseye64",
        :vm_name => "testServer2",
        :net => [
                   [ "127.0.0.12",  2,  "255.255.255.0",  "vlan20"],
                   [ "192.168.56.32",  8, "255.255.255.0",    "mgmt"],
                ]
  },

}

Vagrant.configure("2") do |config|

  MACHINES.each do |boxname, boxconfig|

    config.vm.define boxname do |box|
   
      box.vm.box = boxconfig[:box_name]
      box.vm.host_name = boxconfig[:vm_name]
      
      box.vm.provider "virtualbox" do |v|
        v.memory = 768
        v.cpus = 1
       end

      # if boxconfig[:vm_name] == "office2Server"
      #  box.vm.provision "ansible" do |ansible|
      #   ansible.playbook = "ansible/provision.yml"
      #   ansible.inventory_path = "ansible/hosts"
      #   ansible.host_key_checking = "false"
      #   ansible.limit = "all"
      #  end
      # end

      boxconfig[:net].each do |ipconf|
        box.vm.network("private_network", ip: ipconf[0], adapter: ipconf[1], netmask: ipconf[2], virtualbox__intnet: ipconf[3])
      end

      # if boxconfig.key?(:public)
      #   box.vm.network "public_network", boxconfig[:public]
      # end

      box.vm.provision "shell", inline: <<-SHELL
        mkdir -p ~root/.ssh
        cp ~vagrant/.ssh/auth* ~root/.ssh
      SHELL

      
      # Закомментирован блок, так как настрйка будет выполняться в ansible
      #   case boxname.to_s
      #   when "inetRouter"
      #     box.vm.provision "shell", run: "always", inline: <<-SHELL
      #       sysctl net.ipv4.conf.all.forwarding=1
      #       iptables -t nat -A POSTROUTING ! -d 192.168.0.0/16 -o eth0 -j MASQUERADE
      #       SHELL
      #   when "centralRouter"
      #     box.vm.provision "shell", run: "always", inline: <<-SHELL
      #       sysctl net.ipv4.conf.all.forwarding=1
      #       echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0 
      #       echo "GATEWAY=192.168.255.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
      #       systemctl restart network
      #       SHELL
      #   when "centralServer"
      #     box.vm.provision "shell", run: "always", inline: <<-SHELL
      #       echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0 
      #       echo "GATEWAY=192.168.0.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
      #       systemctl restart network
      #       SHELL
      #  end
    end
  end
end

```

Создадим структуру ansible


```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson36-VLAN_LACP/vm$ tree ansible
ansible
├── ansible.cfg
├── inventories
│   └── hosts
├── playbooks
│   ├── allhosts.yml
│   ├── create_lacp.yml
│   └── create_vlan.yml
└── roles
    ├── create_lacp
    │   ├── files
    │   │   ├── netplan_centralRouter.yaml
    │   │   └── netplan_inetRouter.yaml
    │   ├── handlers
    │   │   └── main.yml
    │   ├── tasks
    │   │   └── main.yml
    │   └── vars
    │       └── main.yml
    └── create_vlan
        ├── files
        │   ├── netplan_testClient1.yaml
        │   ├── netplan_testClient2.yaml
        │   ├── netplan_testServer1.yaml
        │   └── netplan_testServer2.yaml
        ├── handlers
        │   └── main.yml
        ├── tasks
        │   └── main.yml
        └── vars
            └── main.yml

13 directories, 17 files



```

# VLAN

отступил от базовой картинки у меня два vlan 10 и vlan 20  (vlan 1 - фактически обычно считается базовым vlan для всех и его лучше не использовать для разделения l2 сетей)

Настраивать будем через netplan

На client1

```shell

---
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
    eth1: {}
    #Set VLAN
    eth2:
      addresses: [192.168.56.21/24]
  vlans:
        #Name of VLAN  
    vlan10:
        #Set  VLAN`  
      id: 10
        #Name of ph intergace
      link: eth1
        #Disable DHCP
      dhcp4: no
        #Set IP
      addresses: [10.10.10.254/24]

```


На Server1

```shell

---
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
    eth1: {}
    #Set VLAN
    eth2:
      addresses: [192.168.56.22/24]
  vlans:
        #Name of VLAN  
    vlan10:
        #Set  VLAN`  
      id: 10
        #Name of ph intergace
      link: eth1
        #Disable DHCP
      dhcp4: no
        #Set IP
      addresses: [10.10.10.1/24]


```

На второй паре серверов аналогично

Запуск

`ansible-playbook playbooks/create_vlan.yml``

PS Проверка конфига
netplan --debug generate

В итоге поднимается vlan 10 n vlan 20

## На клиенте 1

root@testClient1:/home/vagrant# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:8d:c0:4d brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic eth0
       valid_lft 84189sec preferred_lft 84189sec
    inet6 fe80::a00:27ff:fe8d:c04d/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:8b:53:c7 brd ff:ff:ff:ff:ff:ff
    altname enp0s8
    inet6 fe80::a00:27ff:fe8b:53c7/64 scope link 
       valid_lft forever preferred_lft forever
4: eth2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:52:3a:93 brd ff:ff:ff:ff:ff:ff
    altname enp0s19
    inet 192.168.56.21/24 brd 192.168.56.255 scope global eth2
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe52:3a93/64 scope link 
       valid_lft forever preferred_lft forever
5: vlan10@eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 08:00:27:8b:53:c7 brd ff:ff:ff:ff:ff:ff
    inet 10.10.10.254/24 brd 10.10.10.255 scope global vlan10
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe8b:53c7/64 scope link 
       valid_lft forever preferred_lft forever


## На сервере 1

root@testServer1:/home/vagrant# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:8d:c0:4d brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic eth0
       valid_lft 84152sec preferred_lft 84152sec
    inet6 fe80::a00:27ff:fe8d:c04d/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:ec:21:cd brd ff:ff:ff:ff:ff:ff
    altname enp0s8
    inet6 fe80::a00:27ff:feec:21cd/64 scope link 
       valid_lft forever preferred_lft forever
4: eth2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:a8:a5:b3 brd ff:ff:ff:ff:ff:ff
    altname enp0s19
    inet 192.168.56.22/24 brd 192.168.56.255 scope global eth2
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fea8:a5b3/64 scope link 
       valid_lft forever preferred_lft forever
5: vlan10@eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 08:00:27:ec:21:cd brd ff:ff:ff:ff:ff:ff
    inet 10.10.10.1/24 brd 10.10.10.255 scope global vlan10
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:feec:21cd/64 scope link 
       valid_lft forever preferred_lft forever


root@testClient1:/home/vagrant# ping 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=1.42 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=2.32 ms
^C
--- 10.10.10.1 ping statistics ---

## На клиенте 2

vagrant@testClient2:~$ sudo -s
root@testClient2:/home/vagrant# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:8d:c0:4d brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic eth0
       valid_lft 84089sec preferred_lft 84089sec
    inet6 fe80::a00:27ff:fe8d:c04d/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:ae:b9:21 brd ff:ff:ff:ff:ff:ff
    altname enp0s8
    inet6 fe80::a00:27ff:feae:b921/64 scope link 
       valid_lft forever preferred_lft forever
4: eth2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:6a:ad:1e brd ff:ff:ff:ff:ff:ff
    altname enp0s19
    inet 192.168.56.31/24 brd 192.168.56.255 scope global eth2
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe6a:ad1e/64 scope link 
       valid_lft forever preferred_lft forever
5: vlan20@eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 08:00:27:ae:b9:21 brd ff:ff:ff:ff:ff:ff
    inet 10.10.10.254/24 brd 10.10.10.255 scope global vlan20
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:feae:b921/64 scope link 
       valid_lft forever preferred_lft forever
root@testClient2:/home/vagrant# 
root@testClient2:/home/vagrant# 
root@testClient2:/home/vagrant# ping 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=12.0 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=8.41 ms
^C
--- 10.10.10.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 8.405/10.227/12.049/1.822 ms
root@testClient2:/home/vagrant# 



## Часть 1 задания выполнена


# LACP


Фактически разница в конфигурировании небольшая


### inetRouter

```shell

---
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
    eth1: {}
    eth2: {}
    #Set LACP
    eth3:
      addresses: [192.168.56.10/24]
  bonds:
    bond0:
      dhcp4: no
      interfaces: [eth1, eth2]
      addresses: [192.168.255.1/30]
      #gateway4: 192.168.122.1
      parameters:
        mode: active-backup
        transmit-hash-policy: layer3+4
        mii-monitor-interval: 1
      nameservers:
        addresses:
          - 8.8.8.8
          - 77.88.8.8

```

### centralRouter


```shell

---
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
    eth1: {}
    eth2: {}
    #Set LACP
    eth3:
      addresses: [192.168.56.11/24]
  bonds:
    bond0:
      dhcp4: no
      interfaces: [eth1, eth2]
      addresses: [192.168.255.2/30]
      #gateway4: 192.168.255.1
      parameters:
        mode: active-backup
        transmit-hash-policy: layer3+4
        mii-monitor-interval: 1
      nameservers:
        addresses:
          - 8.8.8.8
          - 77.88.8.8

```

Запуск

`ansible-playbook playbooks/create_lacp.yml`



Проверяем


### inetRouter

```shell
root@inetRouter:/home/vagrant# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:8d:c0:4d brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic eth0
       valid_lft 86273sec preferred_lft 86273sec
    inet6 fe80::a00:27ff:fe8d:c04d/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master bond0 state UP group default qlen 1000
    link/ether e2:ff:e6:75:c1:0e brd ff:ff:ff:ff:ff:ff permaddr 08:00:27:e9:eb:41
    altname enp0s8
4: eth2: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master bond0 state UP group default qlen 1000
    link/ether e2:ff:e6:75:c1:0e brd ff:ff:ff:ff:ff:ff permaddr 08:00:27:9b:8b:91
    altname enp0s9
5: eth3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:9f:00:da brd ff:ff:ff:ff:ff:ff
    altname enp0s19
    inet 192.168.56.10/24 brd 192.168.56.255 scope global eth3
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe9f:da/64 scope link 
       valid_lft forever preferred_lft forever
6: bond0: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether e2:ff:e6:75:c1:0e brd ff:ff:ff:ff:ff:ff
    inet 192.168.255.1/30 brd 192.168.255.3 scope global bond0
       valid_lft forever preferred_lft forever
    inet6 fe80::e0ff:e6ff:fe75:c10e/64 scope link 
       valid_lft forever preferred_lft forever


```

### centralRouter


```shell

root@centralRouter:/home/vagrant# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:8d:c0:4d brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic eth0
       valid_lft 84773sec preferred_lft 84773sec
    inet6 fe80::a00:27ff:fe8d:c04d/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master bond0 state UP group default qlen 1000
    link/ether ce:a3:be:fb:45:2f brd ff:ff:ff:ff:ff:ff permaddr 08:00:27:cf:63:c3
    altname enp0s8
4: eth2: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master bond0 state UP group default qlen 1000
    link/ether ce:a3:be:fb:45:2f brd ff:ff:ff:ff:ff:ff permaddr 08:00:27:a8:1c:0e
    altname enp0s9
5: eth3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:f1:a6:9a brd ff:ff:ff:ff:ff:ff
    altname enp0s17
    inet 192.168.56.11/24 brd 192.168.56.255 scope global eth3
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fef1:a69a/64 scope link 
       valid_lft forever preferred_lft forever
6: eth4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:c7:a6:3c brd ff:ff:ff:ff:ff:ff
    altname enp0s19
    inet 192.168.56.11/24 brd 192.168.56.255 scope global eth4
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fec7:a63c/64 scope link 
       valid_lft forever preferred_lft forever
7: bond0: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether ce:a3:be:fb:45:2f brd ff:ff:ff:ff:ff:ff
    inet 192.168.255.2/30 brd 192.168.255.3 scope global bond0
       valid_lft forever preferred_lft forever
    inet6 fe80::cca3:beff:fefb:452f/64 scope link 
       valid_lft forever preferred_lft forever


```
Проверим bond

```shell


root@inetRouter:/home/vagrant# sudo cat /proc/net/bonding/bond0
Ethernet Channel Bonding Driver: v5.10.0-26-amd64

Bonding Mode: fault-tolerance (active-backup)
Primary Slave: None
Currently Active Slave: eth2
MII Status: up
MII Polling Interval (ms): 1
Up Delay (ms): 0
Down Delay (ms): 0
Peer Notification Delay (ms): 0

Slave Interface: eth2
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:9b:8b:91
Slave queue ID: 0

Slave Interface: eth1
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:e9:eb:41
Slave queue ID: 0



vagrant@centralRouter:~$ sudo -s
root@centralRouter:/home/vagrant# sudo cat /proc/net/bonding/bond0
Ethernet Channel Bonding Driver: v5.10.0-26-amd64

Bonding Mode: fault-tolerance (active-backup)
Primary Slave: None
Currently Active Slave: eth2
MII Status: up
MII Polling Interval (ms): 1
Up Delay (ms): 0
Down Delay (ms): 0
Peer Notification Delay (ms): 0

Slave Interface: eth2
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:a8:1c:0e
Slave queue ID: 0

Slave Interface: eth1
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:cf:63:c3
Slave queue ID: 0


```
## Модифицируем конфиг до LACP


### inetRouter

```shell

---
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
    eth1:
      dhcp4: false
    eth2:
      dhcp4: false    
    #Set LACP
    eth3:
      addresses: [192.168.56.10/24]
  bonds:
    bond0:
      dhcp4: no
      interfaces: [eth1, eth2]
      addresses: [192.168.255.1/30]
      #gateway4: 192.168.122.1
      parameters:
        mode: 802.3ad
        lacp-rate: fast
        mii-monitor-interval: 100

```

### centralRouter

```shell

---
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
    eth1:
      dhcp4: false
    eth2:
      dhcp4: false   
    eth3:
      addresses: [192.168.255.9/30]
    eth4:
      addresses: [192.168.56.11/24]
    #Set LACP
  bonds:
    bond0:
      dhcp4: no
      interfaces: [eth1, eth2]
      addresses: [192.168.255.2/30]
      #gateway4: 192.168.255.1
      parameters:
        mode: 802.3ad
        lacp-rate: fast
        mii-monitor-interval: 100


```



Применим и еще перезапустим хосты

PS Без перезагрузки

`ip link del dev bond0 && netplan apply`

Посмотрим статус


```shell


root@inetRouter:/home/vagrant# sudo cat /proc/net/bonding/bond0
Ethernet Channel Bonding Driver: v5.10.0-26-amd64

Bonding Mode: IEEE 802.3ad Dynamic link aggregation
Transmit Hash Policy: layer2 (0)
MII Status: up
MII Polling Interval (ms): 100
Up Delay (ms): 0
Down Delay (ms): 0
Peer Notification Delay (ms): 0

802.3ad info
LACP rate: fast
Min links: 0
Aggregator selection policy (ad_select): stable
System priority: 65535
System MAC address: e2:ff:e6:75:c1:0e
Active Aggregator Info:
	Aggregator ID: 1
	Number of ports: 2
	Actor Key: 9
	Partner Key: 9
	Partner Mac Address: ce:a3:be:fb:45:2f

Slave Interface: eth2
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:9b:8b:91
Slave queue ID: 0
Aggregator ID: 1
Actor Churn State: none
Partner Churn State: churned
Actor Churned Count: 0
Partner Churned Count: 1
details actor lacp pdu:
    system priority: 65535
    system mac address: e2:ff:e6:75:c1:0e
    port key: 9
    port priority: 255
    port number: 1
    port state: 15
details partner lacp pdu:
    system priority: 65535
    system mac address: ce:a3:be:fb:45:2f
    oper key: 9
    port priority: 255
    port number: 2
    port state: 55

Slave Interface: eth1
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:e9:eb:41
Slave queue ID: 0
Aggregator ID: 1
Actor Churn State: none
Partner Churn State: none
Actor Churned Count: 0
Partner Churned Count: 0
details actor lacp pdu:
    system priority: 65535
    system mac address: e2:ff:e6:75:c1:0e
    port key: 9
    port priority: 255
    port number: 2
    port state: 63
details partner lacp pdu:
    system priority: 65535
    system mac address: ce:a3:be:fb:45:2f
    oper key: 9
    port priority: 255
    port number: 2
    port state: 63


```

Роутинг

```shell


root@inetRouter:/home/vagrant# ip r
default via 10.0.2.2 dev eth0 
default via 10.0.2.2 dev eth0 proto dhcp src 10.0.2.15 metric 100 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 
10.0.2.2 dev eth0 proto dhcp scope link src 10.0.2.15 metric 100 
127.0.0.0/24 dev eth1 proto kernel scope link src 127.0.0.2 
127.0.0.0/24 dev eth2 proto kernel scope link src 127.0.0.3 
192.168.56.0/24 dev eth3 proto kernel scope link src 192.168.56.10 
192.168.255.0/30 dev bond0 proto kernel scope link src 192.168.255.1 

root@centralRouter:/home/vagrant# ip r
default via 10.0.2.2 dev eth0 
default via 10.0.2.2 dev eth0 proto dhcp src 10.0.2.15 metric 100 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 
10.0.2.2 dev eth0 proto dhcp scope link src 10.0.2.15 metric 100 
127.0.0.0/24 dev eth1 proto kernel scope link src 127.0.0.4 
127.0.0.0/24 dev eth2 proto kernel scope link src 127.0.0.5 
192.168.56.0/24 dev eth4 proto kernel scope link src 192.168.56.11 
192.168.255.0/30 dev bond0 proto kernel scope link src 192.168.255.2 
192.168.255.8/30 dev eth3 proto kernel scope link src 192.168.255.9 


```

Опустим интерфейс

`ip link set down eth1`

Проверяю - работает.

root@inetRouter:/home/vagrant# ping 192.168.255.2
PING 192.168.255.1 (192.168.255.1) 56(84) bytes of data.
64 bytes from 192.168.255.2: icmp_seq=1 ttl=64 time=0.035 ms
64 bytes from 192.168.255.2: icmp_seq=2 ttl=64 time=0.211 ms
64 bytes from 192.168.255.2: icmp_seq=3 ttl=64 time=0.224 ms


# Задание выполнено.




