# Lesson32 -  OSPF

Цель домашнего задания
Создать домашнюю сетевую лабораторию. Научится настраивать протокол OSPF в Linux-based системах.


Описание домашнего задания
1. Развернуть 3 виртуальные машины
2. Объединить их разными vlan
- настроить OSPF между машинами на базе Quagga;
- изобразить ассиметричный роутинг;
- сделать один из линков "дорогим", но что бы при этом роутинг был симметричным.

Формат сдачи: Vagrantfile + ansible

## Выполнение ДЗ

Vagrantfile

```shell

# -*- mode: ruby -*-
# vi: set ft=ruby :

MACHINES = {
  :router1 => {
        :box_name => "debian/bullseye64",
        :vm_name => "router1",
        :net => [
                   [ "10.0.10.1", 2, "255.255.255.252", "r1-r2"],
                   [ "10.0.12.1", 3, "255.255.255.252",  "r1-r3"],
                   [ "192.168.10.1", 4, "255.255.255.0", "net1"],
                   [ "192.168.56.10", 5],
                ]
  },

  :router2 => {
        :box_name => "debian/bullseye64",
        :vm_name => "router2",
        :net => [
                   [ "10.0.10.2", 2, "255.255.255.252", "r1-r2"],
                   [ "10.0.11.2", 3, "255.255.255.252",  "r2-r3"],
                   [ "192.168.20.1", 4, "255.255.255.0", "net2"],
                   [ "192.168.56.11", 5],
                ]
  },

  :router3 => {
        :box_name => "debian/bullseye64",
        :vm_name => "router3",
        :net => [
                   [ "10.0.11.1", 2, "255.255.255.252", "r2-r3"],
                   [ "10.0.12.2", 3, "255.255.255.252",  "r1-r3"],
                   [ "192.168.30.1", 4, "255.255.255.0", "net3"],
                   [ "192.168.56.12", 5],
                ]
  }

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

    end
  end
end



# Vagrant.configure("2") do |config|

#   MACHINES.each do |boxname, boxconfig|
    
#     config.vm.define boxname do |box|
   
#       box.vm.box = boxconfig[:box_name]
#       box.vm.host_name = boxconfig[:vm_name]

#       if boxconfig[:vm_name] == "router3"
#        box.vm.provision "ansible" do |ansible|
#         ansible.playbook = "ansible/provision.yml"
#         ansible.inventory_path = "ansible/hosts"
#         ansible.host_key_checking = "false"
#         ansible.limit = "all"
#        end
#       end

#       boxconfig[:net].each do |ipconf|
#         box.vm.network "private_network", ipconf
#       end

#      end
#   end



# end

```

Заполняем файл hosts


`sincere@sincere-ubuntuotus:~/vagrantdocs/lesson32-ospf/vm$ python3 v2a.py -o ansible/inventories/hosts`

Дооформим руками



```shell

[routers]
router1 ansible_ssh_host=127.0.0.1 ansible_ssh_user=vagrant ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_private_key_file=/home/sincere/vagrantdocs/lesson32-ospf/vm/.vagrant/machines/router1/virtualbox/private_key ansible_ssh_port=2222 ansible_ssh_transfer_method=scp router_id=1.1.1.1
router2 ansible_ssh_host=127.0.0.1 ansible_ssh_user=vagrant ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_private_key_file=/home/sincere/vagrantdocs/lesson32-ospf/vm/.vagrant/machines/router2/virtualbox/private_key ansible_ssh_port=2200 ansible_ssh_transfer_method=scp router_id=2.2.2.2
router3 ansible_ssh_host=127.0.0.1 ansible_ssh_user=vagrant ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_private_key_file=/home/sincere/vagrantdocs/lesson32-ospf/vm/.vagrant/machines/router3/virtualbox/private_key ansible_ssh_port=2201 ansible_ssh_transfer_method=scp router_id=3.3.3.3


```

Подготовим сначала один роутер к настройке ospf c поиощью следующего playbook

`~/vagrantdocs/lesson32-ospf/vm/ansible$ ansible-playbook playbooks/router1.yml `


```shell


---

##Set timezone
- name: set timezone
  shell: timedatectl set-timezone Europe/Moscow

#Install Chrony to time Sync

- name: Synchronize datetime | Install chrony
  apt:
    name: chrony
    state: latest
  tags:
    - router-ospf-chrony

#Enable Chrony Services to time Sync

- name: Synchronize datetime | Turn on chronyd
  service:
    name: chronyd
    enabled: yes
    state: started
  notify:
    - systemctl daemon reload
  tags:
    - router-ospf-chrony

# Устанавливаем инструменты анализа сети
- name: install base tools
  apt:
    name:
      - traceroute
      - tcpdump
      - net-tools
      - mtr
      - netplan.io
      - curl
      - gnupg
    state: present
    update_cache: true


#d Отключаем ufw
- name: Disable ufw services if enabled
  shell: "if systemctl is-enabled --quiet {{ item }}; then systemctl disable {{ item }} && echo disable_ok ; fi"
  register: output
  changed_when: "'disable_ok' in output.stdout"
  loop:
    - ufw
  tags:
    - ufwoff
    - inetrouter

  # Добавляем gpg-key репозитория
- name: add gpg frrouting.org
  apt_key:
    url: "https://deb.frrouting.org/frr/keys.asc"
    state: present
  become: true

  # Добавляем репозиторий https://deb.frrouting.org/frr
- name: add frr repo
  apt_repository:
    repo: 'deb https://deb.frrouting.org/frr {{ ansible_distribution_release }} frr-stable'
    state: present

  # Обновляем пакеты и устанавливаем FRR
- name: install FRR packages
  apt:
    name: 
      - frr
      - frr-pythontools
    state: present
    update_cache: true

  # Включаем маршрутизацию транзитных пакетов
- name: set up forward packages across routers
  sysctl:
    name: net.ipv4.conf.all.forwarding
    value: '1'
    state: present
  notify:
    - systemctl daemon reload```


Отработало.

PLAY RECAP *******************************************************************************
router1                    : ok=11   changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   


```

Пробуем настроить конфигурацию и дорабатываем playbook


```shell

# Настройка frr daemons
- name: Enable zebra in /etc/frr/daemons 
  ansible.builtin.lineinfile:
    path: /etc/frr/daemons 
    regexp: 'zebra=no'
    line: 'zebra=yes'
    owner: frr
    group: frr
    mode: 0640

# Настройка frr daemons
- name: Enable ospf in /etc/frr/daemons 
  ansible.builtin.lineinfile:
    path: /etc/frr/daemons
    regexp: 'ospfd=no'
    line: 'ospfd=yes'
    owner: frr
    group: frr
    mode: 0640

```

Повторим запуск playbook и настроим  /etc/frr/frr.conf 


```shell

root@router1:/home/vagrant# ip a | grep "inet " 
    inet 127.0.0.1/8 scope host lo
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic eth0
    inet 10.0.10.1/30 brd 10.0.10.3 scope global eth1
    inet 10.0.12.1/30 brd 10.0.12.3 scope global eth2
    inet 192.168.10.1/24 brd 192.168.10.255 scope global eth3
    inet 192.168.56.10/24 brd 192.168.56.255 scope global eth4


root@router1:/home/vagrant# vtysh

Hello, this is FRRouting (version 9.0.1).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

router1# show interfaces brief
% Unknown command: show interfaces brief
router1# show interface brief
Interface       Status  VRF             Addresses
---------       ------  ---             ---------
eth0            up      default         10.0.2.15/24
eth1            up      default         10.0.10.1/30
eth2            up      default         10.0.12.1/30
eth3            up      default         192.168.10.1/24
eth4            up      default         192.168.56.10/24
lo              up      default         

router1# 

```


Добавляем в  ansible кусочек конфига



```shell
# router1
## tasks

  # Копируем файл frr.conf на хосты, указываем владельца и права
- name: set up OSPF 
  template:
    src: files/frr.conf.j2
    dest: /etc/frr/frr.conf
    owner: frr
    group: frr
    mode: 0640
  tags:
    - setup_ospf

  # Перезапускам FRR и добавляем в автозагрузку
- name: restart FRR
  service:
    name: frr
    state: restarted
    enabled: true
  tags:
    - setup_ospf  

#frr.conf.j2


!Указание версии FRR
frr version 8.1
frr defaults traditional
!Указываем имя машины
hostname {{ ansible_hostname }}
log syslog informational
no ipv6 forwarding
service integrated-vtysh-config
!
!Добавляем информацию об интерфейсе enp0s8
interface eth1
 !Указываем имя интерфейса
 description r1-r2
 !Указываем ip-aдрес и маску (эту информацию мы получили в прошлом шаге)
 ip address 10.0.10.1/30
 !Указываем параметр игнорирования MTU
 ip ospf mtu-ignore
 !Если потребуется, можно указать «стоимость» интерфейса
 !ip ospf cost 1000
 !Указываем параметры hello-интервала для OSPF пакетов
 ip ospf hello-interval 10
 !Указываем параметры dead-интервала для OSPF пакетов
 !Должно быть кратно предыдущему значению
 ip ospf dead-interval 30
!
interface eth2
 description r1-r3
 ip address 10.0.12.1/30
 ip ospf mtu-ignore
 !ip ospf cost 45
 ip ospf hello-interval 10
 ip ospf dead-interval 30
!
interface eth3
 description net
 ip address 192.168.10.1/24
 ip ospf mtu-ignore
 !ip ospf cost 45
 ip ospf hello-interval 10
 ip ospf dead-interval 30 
!
!Начало настройки OSPF
router ospf
 !Указываем router-id 
 {% if router_id_enable == false %}!{% endif %}router-id {{ router_id }}
 !Указываем сети, которые хотим анонсировать соседним роутерам
 network 10.0.10.0/30 area 0
 network 10.0.12.0/30 area 0
 network 192.168.10.0/24 area 0 
 !Указываем адреса соседних роутеров
 neighbor 10.0.10.2
 neighbor 10.0.12.2
!
!Указываем адрес log-файла
log file /var/log/frr/frr.log
default-information originate always


## vars

debian_version: 11
router_id_enable: true
symmetric_routing: false


```

Запускаем

```shell

PLAY RECAP ******************************************************************************************
router1                    : ok=16   changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
router2                    : ok=16   changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
router3                    : ok=16   changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   



Смотрим, что получилось
root@router1:/home/vagrant# vtysh

Hello, this is FRRouting (version 9.0.1).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

router1# show ip route ospf
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/100] is directly connected, eth1, weight 1, 00:05:32
O>* 10.0.11.0/30 [110/200] via 10.0.10.2, eth1, weight 1, 00:04:42
O   10.0.12.0/30 [110/100] is directly connected, eth2, weight 1, 00:05:32
O   192.168.10.0/24 [110/100] is directly connected, eth3, weight 1, 00:05:32
O>* 192.168.20.0/24 [110/200] via 10.0.10.2, eth1, weight 1, 00:04:42
O>* 192.168.30.0/24 [110/300] via 10.0.10.2, eth1, weight 1, 00:04:21

exit

root@router1:/home/vagrant# ping 192.168.20.1
PING 192.168.20.1 (192.168.20.1) 56(84) bytes of data.
64 bytes from 192.168.20.1: icmp_seq=1 ttl=64 time=4.27 ms
64 bytes from 192.168.20.1: icmp_seq=2 ttl=64 time=1.27 ms
^C
--- 192.168.20.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 1.272/2.770/4.268/1.498 ms
root@router1:/home/vagrant# ping 192.168.30.1
PING 192.168.30.1 (192.168.30.1) 56(84) bytes of data.
64 bytes from 192.168.30.1: icmp_seq=1 ttl=63 time=3.81 ms
64 bytes from 192.168.30.1: icmp_seq=2 ttl=63 time=2.91 ms
64 bytes from 192.168.30.1: icmp_seq=3 ttl=63 time=6.68 ms
^C
--- 192.168.30.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2004ms
rtt min/avg/max/mdev = 2.907/4.465/6.679/1.608 ms

root@router1:/home/vagrant# mtr -r 192.168.20.1
Start: 2023-11-03T19:07:52+0300
HOST: router1                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 192.168.20.1               0.0%    10    1.5   2.4   1.4   4.0   1.0

один хоп

root@router1:/home/vagrant# mtr -r 192.168.30.1
Start: 2023-11-03T19:08:20+0300
HOST: router1                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 10.0.10.2                  0.0%    10    1.3   2.2   1.3   4.5   0.9
  2.|-- 192.168.30.1               0.0%    10    4.0   3.5   2.2   6.0   1.3

два хопа



```
Заметим что маршрут с router1 до подсети 192.168.30.1 не оптимальный - была ошибка в конфиге, после исправления стало правильно


# Ассиметричный роутинг

Добавлям в ansible playbook на router1

``` shell


Настройка ассиметричного роутинга с помощью Ansible 
# Отключаем запрет ассиметричного роутинга 
- name: set up asynchronous routing
  sysctl:
    name: net.ipv4.conf.all.rp_filter
    value: '0'
    state: present
  tags:
    - setup_ospf
    - assimectricrouting

  # Копируем файл frr.conf на хосты, указываем владельца и права
- name: set up OSPF 
  template:
    src: files/frrexpensive.conf.j2
    dest: /etc/frr/frr.conf
    owner: frr
    group: frr
    mode: 0640
  tags:
    - setup_ospf

  # Перезапускам FRR и добавляем в автозагрузку
- name: restart FRR
  service:
    name: frr
    state: restarted
    enabled: true
  tags:
    - setup_ospf  


и меняем в expensive.conf.j2


{% if ansible_hostname == 'router1' %}
 ip ospf cost 1000
{% else %}
 !ip ospf cost 45
{% endif %}

На router 2 и 3 разрешаем ассиметричный роутинг

# Отключаем запрет ассиметричного роутинга 
- name: set up asynchronous routing
  sysctl:
    name: net.ipv4.conf.all.rp_filter
    value: '0'
    state: present
  tags:
    - setup_ospf
    - assimectricrouting

```


Запускаем

```shell

~/vagrantdocs/lesson32-ospf/vm/ansible$ ansible-playbook playbooks/allhosts.yml 


PLAY RECAP ******************************************************************************************
router1                    : ok=15   changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
router2                    : ok=15   changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
router3                    : ok=15   changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  

```


Что же получили



```shell


router1# show ip route ospf
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/135] via 10.0.12.2, eth2, weight 1, 00:00:28
O>* 10.0.11.0/30 [110/90] via 10.0.12.2, eth2, weight 1, 00:00:28
O   10.0.12.0/30 [110/45] is directly connected, eth2, weight 1, 00:00:42
O   192.168.10.0/24 [110/45] is directly connected, eth3, weight 1, 00:01:33
O>* 192.168.20.0/24 [110/135] via 10.0.12.2, eth2, weight 1, 00:00:28
O>* 192.168.30.0/24 [110/145] via 10.0.12.2, eth2, weight 1, 00:00:28

router2# show ip route ospf
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/45] is directly connected, eth1, weight 1, 00:00:55
O   10.0.11.0/30 [110/45] is directly connected, eth2, weight 1, 00:01:14
O>* 10.0.12.0/30 [110/90] via 10.0.10.1, eth1, weight 1, 00:00:49
O>* 192.168.10.0/24 [110/90] via 10.0.10.1, eth1, weight 1, 00:00:55
O   192.168.20.0/24 [110/45] is directly connected, eth3, weight 1, 00:01:14
O>* 192.168.30.0/24 [110/145] via 10.0.11.1, eth2, weight 1, 00:00:35

router3# show ip route ospf
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O>* 10.0.10.0/30 [110/90] via 10.0.11.2, eth1, weight 1, 00:01:16
O   10.0.11.0/30 [110/45] is directly connected, eth1, weight 1, 00:01:30
O   10.0.12.0/30 [110/100] is directly connected, eth2, weight 1, 00:01:21
O>* 192.168.10.0/24 [110/135] via 10.0.11.2, eth1, weight 1, 00:01:16
O>* 192.168.20.0/24 [110/90] via 10.0.11.2, eth1, weight 1, 00:01:16
O   192.168.30.0/24 [110/100] is directly connected, eth3, weight 1, 00:01:30

Запускаем пинг


root@router1:/home/vagrant# ping -I 192.168.10.1 192.168.20.1
PING 192.168.20.1 (192.168.20.1) from 192.168.10.1 : 56(84) bytes of data.
64 bytes from 192.168.20.1: icmp_seq=1 ttl=64 time=9.25 ms
64 bytes from 192.168.20.1: icmp_seq=2 ttl=64 time=2.45 ms
64 bytes from 192.168.20.1: icmp_seq=3 ttl=64 time=2.76 ms
64 bytes from 192.168.20.1: icmp_seq=4 ttl=64 time=1.68 ms
64 bytes from 192.168.20.1: icmp_seq=5 ttl=64 time=4.56 ms
64 bytes from 192.168.20.1: icmp_seq=6 ttl=64 time=2.48 ms
64 bytes from 192.168.20.1: icmp_seq=7 ttl=64 time=4.35 ms
64 bytes from 192.168.20.1: icmp_seq=8 ttl=64 time=5.78 ms
64 bytes from 192.168.20.1: icmp_seq=9 ttl=64 time=7.48 ms
64 bytes from 192.168.20.1: icmp_seq=10 ttl=64 time=5.29 ms

уходит через ветку r2-r3

root@router2:/home/vagrant# tcpdump -i eth1 icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
20:29:06.953541 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 61700, seq 10, length 64
20:29:07.953764 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 61700, seq 11, length 64
20:29:08.955501 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 61700, seq 12, length 64
20:29:09.957334 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 61700, seq 13, length 64
20:29:10.959919 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 61700, seq 14, length 64
20:29:11.965869 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 61700, seq 15, length 64
20:29:12.964708 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 61700, seq 16, length 64
20:29:13.971280 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 61700, seq 17, length 64

приходит через ветку r1-r2

root@router2:/home/vagrant# tcpdump -i eth2 icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth2, link-type EN10MB (Ethernet), snapshot length 262144 bytes
20:30:05.120353 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 61700, seq 68, length 64
20:30:06.117363 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 61700, seq 69, length 64
20:30:07.117619 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 61700, seq 70, length 64
20:30:08.120617 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 61700, seq 71, length 64
20:30:09.124511 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 61700, seq 72, length 64
20:30:10.125574 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 61700, seq 73, length 64

root@router1:/home/vagrant# mtr -r 192.168.20.1
Start: 2023-11-03T20:34:17+0300
HOST: router1                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 10.0.12.2                  0.0%    10    1.2   1.8   1.1   4.9   1.1
  2.|-- 192.168.20.1               0.0%    10    2.3   4.2   2.3   8.4   2.4

root@router2:/home/vagrant# mtr -r 192.168.10.1
Start: 2023-11-03T20:35:08+0300
HOST: router2                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 192.168.10.1               0.0%    10    1.8   2.0   1.0   5.0   1.1

```
Ассиметричный роутинг работает


# Симметричный роутинг

Внесем изменения в frr.conf.j2 для router2


```shell

 !Если потребуется, можно указать «стоимость» интерфейса
{%if ansible_hostname == 'router2' and symmetric_routing == true %}
 ip ospf cost 1000
{% else %}
 !ip ospf cost 45
{% endif %}

И в vars

symmetric_routing: true

```

Получаем следующую картину


```shell

root@router1:/home/vagrant# mtr -r 192.168.20.1
Start: 2023-11-03T20:53:12+0300
HOST: router1                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 10.0.12.2                  0.0%    10    1.1   3.7   1.1   8.7   2.9
  2.|-- 192.168.20.1               0.0%    10    7.5   7.6   5.2  11.1   2.0


root@router2:/home/vagrant# mtr -r 192.168.10.1
Start: 2023-11-03T20:55:13+0300
HOST: router2                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 10.0.11.1                  0.0%    10    2.0   2.9   1.0   6.6   1.6
  2.|-- 192.168.10.1               0.0%    10    5.7   5.2   2.5   8.8   2.3


ping -I 192.168.10.1 192.168.20.1
PING 192.168.20.1 (192.168.20.1) from 192.168.10.1 : 56(84) bytes of data.
64 bytes from 192.168.20.1: icmp_seq=1 ttl=63 time=6.65 ms
64 bytes from 192.168.20.1: icmp_seq=2 ttl=63 time=2.72 ms
64 bytes from 192.168.20.1: icmp_seq=3 ttl=63 time=3.36 ms
64 bytes from 192.168.20.1: icmp_seq=4 ttl=63 time=2.71 ms
64 bytes from 192.168.20.1: icmp_seq=5 ttl=63 time=2.04 ms
64 bytes from 192.168.20.1: icmp_seq=6 ttl=63 time=2.66 ms
64 bytes from 192.168.20.1: icmp_seq=7 ttl=63 time=2.93 ms


Через 10.0.11.2


root@router2:/home/vagrant# tcpdump -i eth2 icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth2, link-type EN10MB (Ethernet), snapshot length 262144 bytes
20:50:53.585984 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 58211, seq 44, length 64
20:50:53.586048 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 58211, seq 44, length 64
20:50:54.588091 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 58211, seq 45, length 64
20:50:54.588114 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 58211, seq 45, length 64
20:50:55.589912 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 58211, seq 46, length 64
20:50:55.589953 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 58211, seq 46, length 64
20:50:56.596769 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 58211, seq 47, length 6



```

Симметричный роутинг работает, так как стоимость маршрута между r1-r2 очень дорогая.


Задание выполнено.
