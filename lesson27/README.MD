## Lesson27  - Network

Vagrantfile - для стенда урока 9 - Network

# Дано

https://github.com/erlong15/otus-linux/tree/network
(ветка network)

Метоличка новая тут https://docs.google.com/document/d/1rQH5M2MYclBkvmv3SO4wl4F_IErcojl86hD10ric6Lk/edit

2. Построить следующую сетевую архитектуру:
Сеть office1
- 192.168.2.0/26      - dev
- 192.168.2.64/26     - test servers
- 192.168.2.128/26    - managers
- 192.168.2.192/26    - office hardware

Сеть office2
- 192.168.1.0/25      - dev
- 192.168.1.128/26    - test servers
- 192.168.1.192/26    - office hardware

Сеть central
- 192.168.0.0/28     - directors
- 192.168.0.32/28    - office hardware
- 192.168.0.64/26    - wifi


```text
Office1 ---\
            -----> Central --IRouter --> internet
Office2 ---/
```

Итого должны получиться следующие сервера:
inetRouter
centralRouter
office1Router
office2Router
centralServer
office1Server
office2Server




## Теоретическая часть

    Найти свободные подсети
    Посчитать сколько узлов в каждой подсети, включая свободные
    Указать broadcast адрес для каждой подсети, проверить нет ли ошибок при разбиении.
    
## Практическая часть
    Соединить офисы в сеть согласно схеме и настроить роутинг
    Все сервера и роутеры должны ходить в инет черз inetRouter
    Все сервера должны видеть друг друга
    у всех новых серверов отключить дефолт на нат (eth0), который вагрант поднимает для связи
    при нехватке сетевых интервейсов добавить по несколько адресов на интерфейс

## Формат сдачи ДЗ - vagrant + ansible


# Выполнение


## Теоретическая часть


Таким образом мы можем сформировать таблицу топологии нашей сети

[Таблица подсетей]

Принадлежность сети | Диапазон подсети | Наименование | Кол-во IP-адресов | Первый адрес в сети  | Последний адрес в сети | Broadcast адрес
Сеть office1 | 192.168.2.0/26 | dev | 62 | 192.168.2.1 | 192.168.2.62 | 192.168.2.63
Сеть office1 | 192.168.2.64/26 | test servers | 62 | 192.168.2.65 | 192.168.2.126 | 192.168.2.127
Сеть office1 | 192.168.2.128/26 | managers | 62 | 192.168.2.129 | 192.168.2.190 | 192.168.2.191
Сеть office1 | 192.168.2.192/26 | office hardware | 62 | 192.168.2.193 | 192.168.2.254 | 192.168.2.255
Сеть office2 | 192.168.1.0/25 | dev | 126 | 192.168.1.1 | 192.168.1.126 | 192.168.1.127
Сеть office2 | 192.168.1.128/26 | test servers | 62 | 192.168.1.129 | 192.168.1.190 | 192.168.1.191
Сеть office2 | 192.168.1.192/26 | office hardware | 62 | 192.168.1.193 | 192.168.1.253 | 192.168.1.254
Сеть central | 192.168.0.0/28 | directors | 14 | 192.168.0.1 | 192.168.0.14 | 192.168.0.15
Сеть central | 192.168.0.32/28 | office hardware | 14 | 192.168.0.33 | 192.168.0.62 | 192.168.0.63
Сеть central | 192.168.0.64/26 | wifi | 62 | 192.168.0.65 | 192.168.0.126 | 192.168.0.127

[Табличный отчет](./026/001_ipcheck/table.md)


Сегмент сети | его часть | наименование | число IP-адресов
--- | --- | --- | ---
Сеть office1 | 192.168.2.0/26 | dev | 64 
Сеть office1 | 192.168.2.64/26 | test servers | 64 
Сеть office1 | 192.168.2.128/26 | managers | 64 
Сеть office1 | 192.168.2.192/26 | office hardware | 64 
Сеть office2 | 192.168.1.0/25 | dev | 128 
Сеть office2 | 192.168.1.128/26 | test servers | 64 
Сеть office2 | 192.168.1.192/26 | office hardware | 64 
Сеть central | 192.168.0.16/28 | undefined | 16 
Сеть central | 192.168.0.128/25 | undefined | 128 
Сеть central | 192.168.0.48/28 | undefined | 16 
Сеть central | 192.168.0.0/28 | directors | 16 
Сеть central | 192.168.0.32/28 | office hardware | 16 
Сеть central | 192.168.0.64/26 | wifi | 64 


Неопределенные сети в подсети 192.168.0.0/24

192.168.0.16/28, 192.168.0.128/25, 192.168.0.48/28

Вывод: подсети не пересекаются, маршрутизируемы.

Недостающие сети
Сеть в интернет

Inet — central Router
192.168.255.1/30 - 192.168.255.2/30
192.168.255.0/30 255.255.255.252 2 192.168.255.1 192.168.255.2 192.168.255.3

Сети для связывания офисов 

В методичке конечно стоило бы выделить итли подсеть для серверов и роутеров или связывать сети через подсети для office hardware.
но в целом решил от методички далеко не отступать и считать что связывание происходит через внешние сети (Интернет)

Central Router <-> office1router 
192.168.255.9/30 - 192.168.255.10/30

Central Router <-> office2router 
192.168.255.5/30 - 192.168.255.6/30

## Практическая часть

Наши серверы в общем тоже находятся в подсетях для этого не предназначенных, но ТЗ есть ТЗ


centralServer - 192.168.0.2/28
office1Server - 192.168.2.130/26
office2Server - 192.168.1.0/25

Пропустим промежуточные уровни, сразу напишем Vagrantfile c нужным количеством машин и интерфейсами

Все серверы и роутеры будут на debian11/bullseye64. Основания так и в продакшн значительно удобнее, поддерживать зоопарк ОС немного тяжеловато.


####ТУТ БЫЛА ГИГАНТСКАЯ БАГА С КОНФИГОМ НА КОТОРУЮ УШЛО 6 ЧАСОВ!!!!

В итоге Vagrantfile стал таким

```shell

# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
  :inetRouter => {
        :box_name => "debian/bullseye64",
        :vm_name => "inetRouter",
        :net => [
                   #["10.4.111.51", 1, "255.255.255.0", "inet"],
                   [ "192.168.255.1",  2,  "255.255.255.252",  "router-net"],
                   #подсеть 192.168.56.0/24 - для связи с vagrant
                   [ "192.168.56.10", 8, "255.255.255.0",    "mgmt"],
                ]
  },
  :centralRouter => {
        :box_name => "debian/bullseye64",
        :vm_name => "centralRouter",
        :net => [
                   [ "192.168.255.2",  2,  "255.255.255.252",  "router-net"],
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

Начнем писать ansible playbook

```shell

Создаем структуру


root@sincere-ubuntuotus:/home/sincere/vagrantdocs/lesson27/vm# tree
.
├── ansible
│   ├── ansible.cfg
│   ├── inventories
│   │   └── hosts
│   ├── playbooks
│   │   ├── centralRouter.yml
│   │   ├── centralServer.yml
│   │   ├── inetRouter.yml
│   │   ├── office1Router.yml
│   │   ├── office1Server.yml
│   │   ├── office2Router.yml
│   │   ├── office2Server.yml
│   │   └── testmtr.yml
│   └── roles
│       ├── centralRouter
│       │   ├── files
│       │   │   ├── 00-installer-config.yaml
│       │   │   └── netplan_centralRouter.yaml
│       │   ├── handlers
│       │   │   └── main.yml
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── vars
│       │       └── main.yml
│       ├── centralServer
│       │   ├── files
│       │   │   ├── 00-installer-config.yaml
│       │   │   └── netplan_centralServer.yaml
│       │   ├── handlers
│       │   │   └── main.yml
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── vars
│       │       └── main.yml
│       ├── inetRouter
│       │   ├── files
│       │   │   ├── 00-installer-config.yaml
│       │   │   ├── iptables_restore
│       │   │   ├── iptables_rules.ipv4
│       │   │   └── netplan_inetRouter.yaml
│       │   ├── handlers
│       │   │   └── main.yml
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── vars
│       │       └── main.yml
│       ├── office1Router
│       │   ├── files
│       │   │   ├── 00-installer-config.yaml
│       │   │   └── netplan_office1Router.yaml
│       │   ├── handlers
│       │   │   └── main.yml
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── vars
│       │       └── main.yml
│       ├── office1Server
│       │   ├── files
│       │   │   ├── 00-installer-config.yaml
│       │   │   └── netplan_office1Server.yaml
│       │   ├── handlers
│       │   │   └── main.yml
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── vars
│       │       └── main.yml
│       ├── office2Router
│       │   ├── files
│       │   │   ├── 00-installer-config.yaml
│       │   │   └── netplan_office2Router.yaml
│       │   ├── handlers
│       │   │   └── main.yml
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── vars
│       │       └── main.yml
│       ├── office2Server
│       │   ├── files
│       │   │   ├── 00-installer-config.yaml
│       │   │   └── netplan_office2Server.yaml
│       │   ├── handlers
│       │   │   └── main.yml
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── vars
│       │       └── main.yml
│       └── testmtr
│           ├── tasks
│           │   └── main.yml
│           └── vars
│               └── main.yml
├── filestestmtr
│   ├── centralRouter - mtr -r 192.168.0.2.txt
│   ├── centralRouter - mtr -r 192.168.1.2.txt
│   ├── centralRouter - mtr -r 192.168.2.130.txt
│   ├── centralRouter - mtr -r 192.168.255.1.txt
│   ├── centralRouter - mtr -r 192.168.255.2.txt
│   ├── centralRouter - mtr -r ya.ru.txt
│   ├── centralServer - mtr -r 192.168.0.2.txt
│   ├── centralServer - mtr -r 192.168.1.2.txt
│   ├── centralServer - mtr -r 192.168.2.130.txt
│   ├── centralServer - mtr -r 192.168.255.1.txt
│   ├── centralServer - mtr -r 192.168.255.2.txt
│   ├── centralServer - mtr -r ya.ru.txt
│   ├── inetRouter - mtr -r 192.168.0.2.txt
│   ├── inetRouter - mtr -r 192.168.1.2.txt
│   ├── inetRouter - mtr -r 192.168.2.130.txt
│   ├── inetRouter - mtr -r 192.168.255.1.txt
│   ├── inetRouter - mtr -r 192.168.255.2.txt
│   ├── inetRouter - mtr -r ya.ru.txt
│   ├── office1Router - mtr -r 192.168.0.2.txt
│   ├── office1Router - mtr -r 192.168.1.2.txt
│   ├── office1Router - mtr -r 192.168.2.130.txt
│   ├── office1Router - mtr -r 192.168.255.1.txt
│   ├── office1Router - mtr -r 192.168.255.2.txt
│   ├── office1Router - mtr -r ya.ru.txt
│   ├── office1Server - mtr -r 192.168.0.2.txt
│   ├── office1Server - mtr -r 192.168.1.2.txt
│   ├── office1Server - mtr -r 192.168.2.130.txt
│   ├── office1Server - mtr -r 192.168.255.1.txt
│   ├── office1Server - mtr -r 192.168.255.2.txt
│   ├── office1Server - mtr -r ya.ru.txt
│   ├── office2Router - mtr -r 192.168.0.2.txt
│   ├── office2Router - mtr -r 192.168.1.2.txt
│   ├── office2Router - mtr -r 192.168.2.130.txt
│   ├── office2Router - mtr -r 192.168.255.1.txt
│   ├── office2Router - mtr -r 192.168.255.2.txt
│   ├── office2Router - mtr -r ya.ru.txt
│   ├── office2Server - mtr -r 192.168.0.2.txt
│   ├── office2Server - mtr -r 192.168.1.2.txt
│   ├── office2Server - mtr -r 192.168.2.130.txt
│   ├── office2Server - mtr -r 192.168.255.1.txt
│   ├── office2Server - mtr -r 192.168.255.2.txt
│   └── office2Server - mtr -r ya.ru.txt
├── v2a.py
└── Vagrantfile


```


Можно было сделать всего 3 playbook, но мне проще было делать первоначальную отладку.

Поэтому количество playbook по числу хостов.


# inetRouter

Так как я отступил от ос описанной в методичке, пришлось дополнительно проверять отключенность firewall - UFW, NFTABLES и  доустанавливать  IPTABLES, IPTABLES-PERSISTENT. Доустановить netplan

Настраиваем forwarding, nat, маршруты и адреса через netplan

```shell

---
#install netplan

- name: Install netplan
  apt:
    name: "netplan.io"
    state: present
    update_cache: yes
  become: true
  tags:
    - netplaninstall
    - inetRouter

#install mtr utility
- name: Install MTR for Troubleshootings
  apt:
    name: mtr
    state: present
  tags:
    - mtr
    - inetrouter

#disabled nft fw
- name: Firewall NFT
  service:
    name: nftables
    enabled: no
    state: stopped
  notify:
    - systemctl daemon reload
  tags:
    - firewall-nft-off
    - inetrouter



#disable ufw firewall
- name: Disable ufw services if enabled
  shell: "if systemctl is-enabled --quiet {{ item }}; then systemctl disable {{ item }} && echo disable_ok ; fi"
  register: output
  changed_when: "'disable_ok' in output.stdout"
  loop:
    - ufw
  tags:
    - ufwoff
    - inetrouter

#install iptables
- name: Install iptables
  apt:
    name: iptables
    state: present
  tags:
    - iptables
    - inetrouter

#install iptables-persistent
- name: Install iptables
  apt:
    name: iptables-persistent
    state: present
  tags:
    - iptables
    - inetrouter


#setup NAT rules for iptables
- name: Set up NAT on inetRouter
  template: 
    src: "{{ item.src }}"
    dest: "{{ item.dest }}"
    owner: root
    group: root
    mode: "{{ item.mode }}"
  notify:
    - systemctl daemon reload
    - startiptables
  with_items:
    - { src: "files/iptables_rules.ipv4", dest: "/etc/iptables/rules.v4", mode: "0644" }
  when: (ansible_hostname == "inetRouter")


# - name: iptables masquerading
#   iptables:
#     table: nat
#     chain: POSTROUTING
#     destination: "!192.168.0.0/16"
#     out_interface: eth0
#     jump: MASQUERADE
#   tags:
#     - inetrouter
#     - iptables-minetrouter

#enable forwarding for interfaces

- name: set up forward packages across routers
  sysctl:
    name: net.ipv4.conf.all.forwarding
    value: '1'
    state: present
  notify:
    - systemctl daemon reload

#disable default route
- name: disable default route
  template: 
    src: files/00-installer-config.yaml
    dest: /etc/netplan/00-installer-config.yaml
    owner: root
    group: root
    mode: 0644
  when: (ansible_hostname != "inetRouter") 

- name: add default gateway for Routers
  template: 
    src: "files/netplan_{{ansible_hostname}}.yaml"
    dest: /etc/netplan/50-vagrant.yaml
    owner: root
    group: root
    mode: 0644

- name: Apply and reload the new config address with netplan
  command: netplan apply
  become: true
  async: 100
  poll: 0


- name: start iptables
  systemd:
    name: iptables
    enabled: yes
    state: started  

```

# Routers

Так как я отступил от ос описанной в методичке, пришлось дополнительно проверять отключенность firewall - UFW, NFTABLES и  доустанавливать  IPTABLES, IPTABLES-PERSISTENT. Доустановить netplan

Настраиваем forwarding, маршруты и адреса через netplan

* В методичке ошибка в примере обратного маршрута.

```shell

---
#install netplan

- name: Install netplan
  apt:
    name: "netplan.io"
    state: present
    update_cache: yes
  become: true
  tags:
    - netplaninstall
    - inetRouter

#install mtr utility
- name: Install MTR for Troubleshootings
  apt:
    name: mtr
    state: present
  tags:
    - mtr
    - inetrouter

#disable ufw firewall
- name: Disable ufw services if enabled
  shell: "if systemctl is-enabled --quiet {{ item }}; then systemctl disable {{ item }} && echo disable_ok ; fi"
  register: output
  changed_when: "'disable_ok' in output.stdout"
  loop:
    - ufw
  tags:
    - ufwoff
    - inetrouter

#enable forwarding for interfaces
- name: set up forward packages across routers
  sysctl:
    name: net.ipv4.conf.all.forwarding
    value: '1'
    state: present
  notify:
    - systemctl daemon reload


#disable default route
- name: disable default route
  template: 
    src: files/00-installer-config.yaml
    dest: /etc/netplan/00-installer-config.yaml
    owner: root
    group: root
    mode: 0644



# Add routing and ip addresses

- name: add default gateway for Routers
  template: 
    src: "files/netplan_{{ansible_hostname}}.yaml"
    dest: /etc/netplan/50-vagrant.yaml
    owner: root
    group: root
    mode: 0644

- name: Apply and reload the new config address with netplan
  command: netplan apply
  become: true
  async: 100
  poll: 0




```

# Servers

Так как я отступил от ос описанной в методичке, пришлось дополнительно проверять отключенность firewall - UFW, NFTABLES и  доустанавливать  IPTABLES, IPTABLES-PERSISTENT. Доустановить netplan

Настраиваем forwarding, маршруты и адреса через netplan

```shell

---
#install netplan

- name: Install netplan
  apt:
    name: "netplan.io"
    state: present
    update_cache: yes
  become: true
  tags:
    - netplaninstall
    - inetRouter

#install mtr utility
- name: Install MTR for Troubleshootings
  apt:
    name: mtr
    state: present
  tags:
    - mtr
    - inetrouter

#disable ufw firewall
- name: Disable ufw services if enabled
  shell: "if systemctl is-enabled --quiet {{ item }}; then systemctl disable {{ item }} && echo disable_ok ; fi"
  register: output
  changed_when: "'disable_ok' in output.stdout"
  loop:
    - ufw
  tags:
    - ufwoff
    - inetrouter

# #enable forwarding for interfaces
# - name: set up forward packages across routers
#   sysctl:
#     name: net.ipv4.conf.all.forwarding
#     value: '1'
#     state: present
#   notify:
#     - systemctl daemon reload


#disable default route
- name: disable default route
  template: 
    src: files/00-installer-config.yaml
    dest: /etc/netplan/00-installer-config.yaml
    owner: root
    group: root
    mode: 0644



# Add routing and ip addresses

- name: add default gateway for Routers
  template: 
    src: "files/netplan_{{ansible_hostname}}.yaml"
    dest: /etc/netplan/50-vagrant.yaml
    owner: root
    group: root
    mode: 0644

- name: Apply and reload the new config address with netplan
  command: netplan apply
  become: true
  async: 100
  poll: 0



```


Поднять сетевую лабораторию

```shell

vagrant up

ansible-playbook playbooks/allhosts.yml


...



PLAY RECAP **********************************************************************************
centralRouter              : ok=8    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
centralServer              : ok=7    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
inetRouter                 : ok=12   changed=1    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
office1Router              : ok=8    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
office1Server              : ok=7    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
office2Router              : ok=8    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
office2Server              : ok=7    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

```


После того как все скрипты применятся проверяем доступность сетей отельным playbook  - testmtr (дополнительно в машинку ставили пакет mtr)

`ansible-playbook playbooks/allhosts.yml`

На выходе получаем папку с тестами. Пример с office2Server до Яндекса

```shell

Start: 2023-10-27T13:55:12+0000
HOST: office2Server               Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 192.168.1.1                0.0%    10    5.0   2.0   1.0   5.0   1.2 - office2router
  2.|-- 192.168.255.5              0.0%    10    7.1   6.7   2.8  11.6   3.0 - centralRouter
  3.|-- 192.168.255.1              0.0%    10   16.4  11.3   4.4  22.5   5.8 - InetRouter
  4.|-- 10.0.2.2                   0.0%    10   15.5  12.5   5.6  26.0   6.9 - InetRouter (NAT)
  5.|-- ???                       100.0    10    0.0   0.0   0.0   0.0   0.0 - Далее сеть Интернет
  6.|-- ???                       100.0    10    0.0   0.0   0.0   0.0   0.0
  7.|-- ???                       100.0    10    0.0   0.0   0.0   0.0   0.0
  8.|-- dante.yndx.net             0.0%    10    7.4  16.6   7.4  29.7   6.9
  9.|-- ???                       100.0    10    0.0   0.0   0.0   0.0   0.0
 10.|-- ya.ru                      0.0%    10   15.4  16.3  11.2  24.0   3.8

```


Задание выполнено!

Спасибо за проверку!
