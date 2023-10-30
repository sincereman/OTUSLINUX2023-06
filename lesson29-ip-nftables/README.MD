# Домашнее задание

Сценарии iptables
Описание/Пошаговая инструкция выполнения домашнего задания:

Что нужно сделать?

    реализовать knocking port

    centralRouter может попасть на ssh inetrRouter через knock скрипт
    пример в материалах.

    добавить inetRouter2, который виден(маршрутизируется (host-only тип сети для виртуалки)) с хоста или форвардится порт через локалхост.
    запустить nginx на centralServer.
    пробросить 80й порт на inetRouter2 8080.
    дефолт в инет оставить через inetRouter.
    Формат сдачи ДЗ - vagrant + ansible
    реализовать проход на 80й порт без маскарадинга*
    В чат ДЗ отправьте ссылку на ваш git-репозиторий. Обычно мы проверяем ДЗ в течение 48 часов.
    Если возникнут вопросы, обращайтесь к студентам, преподавателям и наставникам в канал группы в Telegram.
    Удачи при выполнении!


Критерии оценки:

Статус "Принято" ставится при выполнении всех основных условий.
Задание со звездочкой выполняется по желанию.


# Выполнение.


Так как у нас добавляется новый inetRouter2, а маска сети не позволяет добавить еще один хост. Поменяем сеть с 192.168.255.1/30 на 192.168.255.64/29
InetRouter - 66
InetRouter - 67
CentralRouter - 65

Опишем это в Vagrantfile и также добавим проброс порта с localhost

```shell
      case boxname.to_s
      when "inetRouter2"
          box.vm.network 'forwarded_port', guest: 8080, host: 8080, host_ip: '127.0.0.1'
      end

```

Vagrantfile


```shell

# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
  :inetRouter => {
        :box_name => "debian/bullseye64",
        :vm_name => "inetRouter",
        :net => [
                   #["10.4.111.51", 1, "255.255.255.0", "inet"],
                   [ "192.168.255.66",  2,  "255.255.255.248",  "router-net"],
                   #подсеть 192.168.56.0/24 - для связи с vagrant
                   [ "192.168.56.10", 8, "255.255.255.0",    "mgmt"],
                ]
  },
  :inetRouter2 => {
        :box_name => "debian/bullseye64",
        :vm_name => "inetRouter2",
        :net => [
            ["192.168.255.67",  2,  "255.255.255.248",  "router-net"],
            [ "192.168.56.9", 8, "255.255.255.0",    "mgmt"],
        ]
  },

  :centralRouter => {
        :box_name => "debian/bullseye64",
        :vm_name => "centralRouter",
        :net => [
                   [ "192.168.255.65",  2,  "255.255.255.248",  "router-net"],
                   [ "192.168.0.1",  3,  "255.255.255.240",  "dir-net"],
                   [ "192.168.0.33",  4,  "255.255.255.240",  "hw1-net"],
                   [ "192.168.0.65",  5,  "255.255.255.192",  "wifi-net"],
                   [ "192.168.255.9",  6,  "255.255.255.252",  "office1-central"],
                   [ "192.168.255.5",  7,  "255.255.255.252",  "office2-central"],
                   [ "192.168.56.11",  8, "255.255.255.0",    "mgmt"],
                ]
  },
  
  :centralServer => {
        :box_name => "debian/bullseye64",
        :vm_name => "centralServer",
        :net => [
                   [ "192.168.0.2",  2,  "255.255.255.240",  "dir-net"],
                   [ "192.168.56.12",  8, "255.255.255.0",    "mgmt"],
                ]
  },

  :office1Router => {
        :box_name => "debian/bullseye64",
        :vm_name => "office1Router",
        :net => [
                   [ "192.168.255.10",  2,  "255.255.255.252",  "office1-central"],
                   [ "192.168.2.1",  3,  "255.255.255.192",  "dev1-net"],
                   [ "192.168.2.65",  4,  "255.255.255.192",  "test1-net"],
                   [ "192.168.2.129",  5,  "255.255.255.192",  "managers-net"],
                   [ "192.168.2.193",  6,  "255.255.255.192",  "office1hardware-net"],
                   [ "192.168.56.20",  8, "255.255.255.0",    "mgmt"],
                ]
  },

  :office1Server => {
        :box_name => "debian/bullseye64",
        :vm_name => "office1Server",
        :net => [
                   [ "192.168.2.130",  2,  "255.255.255.192",  "managers-net"],
                   [ "192.168.56.21",  8, "255.255.255.0",    "mgmt"],
                ]
  },

  :office2Router => {
    :box_name => "debian/bullseye64",
    :vm_name => "office2Router",
    :net => [
               [ "192.168.255.6",  2,  "255.255.255.252",  "office2-central"],
               [ "192.168.1.1",  3,  "255.255.255.128",  "dev2-net"],
               [ "192.168.1.129",  4,  "255.255.255.192",  "test2-net"],
               [ "192.168.1.193",  5,  "255.255.255.192",  "office2-net"],
               [ "192.168.56.30",  8, "255.255.255.0",    "mgmt"],
            ]
  },

  :office2Server => {
        :box_name => "debian/bullseye64",
        :vm_name => "office2Server",
        :net => [
                   [ "192.168.1.2",  2,  "255.255.255.128",  "dev2-net"],
                   [ "192.168.56.31",  8, "255.255.255.0",    "mgmt"],
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

      case boxname.to_s
      when "inetRouter2"
          box.vm.network 'forwarded_port', guest: 8080, host: 8080, host_ip: '127.0.0.1'
      end

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

Структура ansible почти не изменилась,

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson29-ip-nftables/vm$ tree ansible
ansible
├── ansible.cfg
├── inventories
│   └── hosts
├── playbooks
│   ├── allhosts.yml
│   ├── centralRouter.yml
│   ├── centralServer.yml
│   ├── inetRouter2.yml
│   ├── inetRouter.yml
│   ├── office1Router.yml
│   ├── office1Server.yml
│   ├── office2Router.yml
│   ├── office2Server.yml
│   └── testmtr.yml
└── roles
    ├── centralRouter
    │   ├── files
    │   │   ├── 00-installer-config.yaml
    │   │   ├── netplan_centralRouter.yaml
    │   │   └── port_knocking.sh
    │   ├── handlers
    │   │   └── main.yml
    │   ├── tasks
    │   │   └── main.yml
    │   └── vars
    │       └── main.yml
    ├── centralServer
    │   ├── files
    │   │   ├── 00-installer-config.yaml
    │   │   ├── netplan_centralServer.yaml
    │   │   └── nginx
    │   │       ├── index.html
    │   │       └── nginx.conf
    │   ├── handlers
    │   │   └── main.yml
    │   ├── tasks
    │   │   └── main.yml
    │   └── vars
    │       └── main.yml
    ├── inetRouter
    │   ├── files
    │   │   ├── 00-installer-config.yaml
    │   │   ├── iptables_rules.ipv4
    │   │   └── netplan_inetRouter.yaml
    │   ├── handlers
    │   │   └── main.yml
    │   ├── tasks
    │   │   └── main.yml
    │   └── vars
    │       └── main.yml
    ├── inetRouter2
    │   ├── files
    │   │   ├── 00-installer-config.yaml
    │   │   └── netplan_inetRouter2.yaml
    │   ├── handlers
    │   │   └── main.yml
    │   ├── tasks
    │   │   └── main.yml
    │   └── vars
    │       └── main.yml
    ├── office1Router
    │   ├── files
    │   │   ├── 00-installer-config.yaml
    │   │   └── netplan_office1Router.yaml
    │   ├── handlers
    │   │   └── main.yml
    │   ├── tasks
    │   │   └── main.yml
    │   └── vars
    │       └── main.yml
    ├── office1Server
    │   ├── files
    │   │   ├── 00-installer-config.yaml
    │   │   └── netplan_office1Server.yaml
    │   ├── handlers
    │   │   └── main.yml
    │   ├── tasks
    │   │   └── main.yml
    │   └── vars
    │       └── main.yml
    ├── office2Router
    │   ├── files
    │   │   ├── 00-installer-config.yaml
    │   │   └── netplan_office2Router.yaml
    │   ├── handlers
    │   │   └── main.yml
    │   ├── tasks
    │   │   └── main.yml
    │   └── vars
    │       └── main.yml
    ├── office2Server
    │   ├── files
    │   │   ├── 00-installer-config.yaml
    │   │   └── netplan_office2Server.yaml
    │   ├── handlers
    │   │   └── main.yml
    │   ├── tasks
    │   │   └── main.yml
    │   └── vars
    │       └── main.yml
    └── testmtr
        ├── tasks
        │   └── main.yml
        └── vars
            └── main.yml

47 directories, 58 files


```



Исправлены конфигурации:


 ## inetrouter

Netplan config

```shell

---
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true   
    eth1:
      addresses:
      - 192.168.255.66/29
      routes:
      - to: 192.168.0.0/16
        via: 192.168.255.65
    eth2:
      addresses:
      - 192.168.56.9/24

```

Iptables config 

Добавляем часть про port knocking

```shell 

*nat
:PREROUTING ACCEPT [1:44]
:INPUT ACCEPT [1:44]
:OUTPUT ACCEPT [111:8672]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING ! -d 192.168.0.0/16 -o eth0 -j MASQUERADE
COMMIT

*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:TRAFFIC - [0:0]
:SSH-INPUT - [0:0]
:SSH-INPUTTWO - [0:0]

-A INPUT -p icmp --icmp-type 3 -j ACCEPT
-A INPUT -p icmp --icmp-type 8 -j ACCEPT
-A INPUT -p icmp --icmp-type 12 -j ACCEPT
-A OUTPUT -p icmp --icmp-type 0 -j ACCEPT
-A OUTPUT -p icmp --icmp-type 3 -j ACCEPT
-A OUTPUT -p icmp --icmp-type 4 -j ACCEPT
-A OUTPUT -p icmp --icmp-type 11 -j ACCEPT
-A OUTPUT -p icmp --icmp-type 12 -j ACCEPT

# TRAFFIC chain for Port Knocking. The correct port sequence in this example is  8881 -> 7777 -> 9991; any other sequence will drop the traffic
-A INPUT -j TRAFFIC
-A TRAFFIC -p icmp --icmp-type any -j ACCEPT
-A TRAFFIC -m state --state ESTABLISHED,RELATED -j ACCEPT
-A TRAFFIC -m state --state NEW -m tcp -p tcp --dport 22 -m recent --rcheck --seconds 15 --name SSH2 -j ACCEPT
-A TRAFFIC -m state --state NEW -m tcp -p tcp -m recent --name SSH2 --remove -j DROP
-A TRAFFIC -m state --state NEW -m tcp -p tcp --dport 9991 -m recent --rcheck --name SSH1 -j SSH-INPUTTWO
-A TRAFFIC -m state --state NEW -m tcp -p tcp -m recent --name SSH1 --remove -j DROP
-A TRAFFIC -m state --state NEW -m tcp -p tcp --dport 7777 -m recent --rcheck --name SSH0 -j SSH-INPUT
-A TRAFFIC -m state --state NEW -m tcp -p tcp -m recent --name SSH0 --remove -j DROP
-A TRAFFIC -m state --state NEW -m tcp -p tcp --dport 8881 -m recent --name SSH0 --set -j DROP
-A SSH-INPUT -m recent --name SSH1 --set -j DROP
-A SSH-INPUTTWO -m recent --name SSH2 --set -j DROP
-A TRAFFIC -j DROP
COMMIT
# END or further rules

```


## inetRouter2

Netplan config

```shell
---
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true   
    eth1:
      addresses:
      - 192.168.255.67/29
      routes:
      - to: 0.0.0.0/0
        via: 192.168.255.65        
    eth2:
      addresses:
      - 192.168.56.10/24


```

Iptables config 

Добавляем часть про port forwarding

```shell 

- name: iptables dnat
  iptables:
    table: nat
    chain: PREROUTING
    protocol: tcp
    destination_port: 8080
    to_destination: "192.168.0.2:80"
    jump: DNAT
  tags:
    - deploy
    - iptables-dnat

- name: iptables snat
  iptables:
    table: nat
    chain: POSTROUTING
    protocol: tcp
    destination_port: 80
    to_source: "192.168.255.67"
    jump: SNAT
  tags:
    - iptables-snat

```

## centralRouter

Netplan config

```shell
---
network:
  version: 2
  renderer: networkd
  ethernets:
    eth1:
        addresses:
        - 192.168.255.65/29
        routes:
        - to: 0.0.0.0/0
          via: 192.168.255.66
    eth2:
        addresses:
        - 192.168.0.1/28
    eth3:
        addresses:
        - 192.168.0.33/28
    eth4:
        addresses:
        - 192.168.0.65/26
    eth5:
        addresses:
        - 192.168.255.9/30
        routes:
        - to: 192.168.2.0/24
          via: 192.168.255.10
    eth6:
        addresses:
        - 192.168.255.5/30
        routes:
        - to: 192.168.1.0/24
          via: 192.168.255.6
    eth7:
        addresses:
        - 192.168.56.11/24


```


Port knocking script


```shell
#!/bin/bash
# ./port_knocking.sh  192.168.255.66 8881 7777 9991 && ssh 192.168.0.66

# Проверка на переданный параметр
USAGE="SYNOPSIS: ./port_knocking.sh <TARGET_IP> <port_1> [<port_2> <port_3> ...]"
if [ -z "$1" ]
then
    echo "Sorry, there is no first parameter TARGET_IP. "
    echo $USAGE
    exit 1
fi

if [ -z "$2" ]
then
    echo "Sorry, some knock-port id needed. "
    echo $USAGE
    exit 1
fi

TARGET_IP=$1
shift
for ARG in "$@"
do
  sudo nmap -Pn --max-retries 0 -p $ARG $TARGET_IP # !! SUDO - MUST BE
#  sudo ssh -o ConnectTimeout=1 $TARGET_IP -p $ARG
done

```

## centralServer

Nginx

```shell

# add nginx lesson 29
- name: Install nginx
  apt:
    name: nginx
    state: present

- name: Configure nginx
  template:
    src: ../files/nginx/nginx.conf
    dest: /etc/nginx/nginx.conf
  notify:
    - start nginx

- name: index.html
  template:
    src: ../files/nginx/index.html
    dest: /usr/share/nginx/html/index.html
  notify:
    - restart nginx

```




После внесенных изменений запускаем

```shell

~/vagrantdocs/lesson29-ip-nftables/vm/ansible$ ansible-playbook playbooks/allhosts.yml


TASK [../roles/office2Server : Apply and reload the new config address with netplan] ********************************************************************
changed: [office2Server]

PLAY RECAP **********************************************************************************************************************************************
centralRouter              : ok=10   changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
centralServer              : ok=10   changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
inetRouter                 : ok=12   changed=1    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
inetRouter2                : ok=14   changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
office1Router              : ok=8    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
office1Server              : ok=7    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
office2Router              : ok=8    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
office2Server              : ok=7    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   


```

### Проверяем проброс портов (часть 2,3,4,5 задания)

Запросим страничку и пакет идет вот таким образом на 127.0.0.1:8080 - > 10.4.255.67:8080 - > 192.168.0.2:80

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson29-ip-nftables/vm/ansible$ curl 127.0.0.1:8080
curl 127.0.0.1:8080

Nginx centralServer Port 80

```
Работает.


### Проверяем port knocking (часть  1  задания)


Так как у нас по умолчанию в образе в конфиге ssh не разрешен парольный вход, а только по ключу.
Необходимо  добавить пару строчек в конфиг 

PasswordAuthentication yes
PermitRootLogin #(не делать так в продакшн - речь про root)

````shell
root@centralRouter:/home/vagrant# ssh root@192.168.255.66
ssh: connect to host 192.168.255.66 port 22: Connection timed out


root@centralRouter:/home/vagrant# sudo ./port_knocking.sh  192.168.255.66 8881 7777 9991 && ssh 192.168.255.66
Starting Nmap 7.80 ( https://nmap.org ) at 2023-10-30 19:19 UTC
Warning: 192.168.255.66 giving up on port because retransmission cap hit (0).
Nmap scan report for 192.168.255.66
Host is up (0.0050s latency).

PORT     STATE    SERVICE
8881/tcp filtered galaxy4d
MAC Address: 08:00:27:9B:60:FC (Oracle VirtualBox virtual NIC)

Nmap done: 1 IP address (1 host up) scanned in 0.32 seconds
Starting Nmap 7.80 ( https://nmap.org ) at 2023-10-30 19:19 UTC
Warning: 192.168.255.66 giving up on port because retransmission cap hit (0).
Nmap scan report for 192.168.255.66
Host is up (0.0042s latency).

PORT     STATE    SERVICE
7777/tcp filtered cbt
MAC Address: 08:00:27:9B:60:FC (Oracle VirtualBox virtual NIC)

Nmap done: 1 IP address (1 host up) scanned in 0.31 seconds
Starting Nmap 7.80 ( https://nmap.org ) at 2023-10-30 19:19 UTC
Warning: 192.168.255.66 giving up on port because retransmission cap hit (0).
Nmap scan report for 192.168.255.66
Host is up (0.0044s latency).

PORT     STATE    SERVICE
9991/tcp filtered issa
MAC Address: 08:00:27:9B:60:FC (Oracle VirtualBox virtual NIC)

Nmap done: 1 IP address (1 host up) scanned in 0.40 seconds
root@192.168.255.66's password: 
Linux inetRouter 5.10.0-26-amd64 #1 SMP Debian 5.10.197-1 (2023-09-29) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Mon Oct 30 19:03:11 2023 from 192.168.255.65
root@inetRouter:~# 

````


# Задание выполнено