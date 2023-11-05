




Выполнение

Vagrantfile

```shell


# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
    config.vm.box = "debian/bullseye64"
    config.vm.define "vpnserver" do |vpnserver|
        vpnserver.vm.hostname = "vpnserver"
        vpnserver.vm.network "private_network", ip: "192.168.56.10"
    end
    config.vm.define "vpnclient" do |vpnclient|
        vpnclient.vm.hostname = "vpnclient"
        vpnclient.vm.network "private_network", ip: "192.168.56.20"
    end
  end


```

Запустим наши VM  - vagrant up


Создадим стенд на ansible

```shell

~/vagrantdocs/lesson34-VPN/vm$ tree ansible/
ansible/
├── ansible.cfg
├── inventories
│   └── hosts
├── playbooks
│   ├── vpnclient.yml
│   └── vpnserver.yml
└── roles
    ├── vpnclient
    │   ├── files
    │   │   ├── clientras.conf
    │   │   ├── clienttap.conf
    │   │   ├── clienttun.conf
    │   │   └── static.key
    │   ├── handlers
    │   │   └── main.yml
    │   ├── tasks
    │   │   └── main.yml
    │   └── vars
    │       └── main.yml
    └── vpnserver
        ├── files
        │   ├── serverras.conf
        │   ├── servertap.conf
        │   ├── servertun.conf
        │   └── static.key
        ├── handlers
        │   └── main.yml
        ├── tasks
        │   └── main.yml
        └── vars
            └── main.yml

13 directories, 18 files

```


В конфиге ansible указаны tags tap, tun, ras

Запускаем поочередно

Сначала с тегом tap


# TAP


```shell


~/vagrantdocs/lesson34-VPN/vm/ansible$ ansible-playbook playbooks/vpnserver.yml -t tap

TASK [../roles/vpnserver : set up forward packages across routers] **********************************
changed: [vpnserver]

TASK [../roles/vpnserver : install base tools] ******************************************************
changed: [vpnserver]

TASK [../roles/vpnserver : Copy "static.key" file] **************************************************
changed: [vpnserver]

TASK [../roles/vpnserver : Copy "servertap.conf" file] **********************************************
changed: [vpnserver]

RUNNING HANDLER [../roles/vpnserver : systemctl daemon reload] **************************************
ok: [vpnserver]

PLAY RECAP ******************************************************************************************
vpnserver                  : ok=11   changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   


~/vagrantdocs/lesson34-VPN/vm/ansible$ ansible-playbook playbooks/vpnclient.yml -t tap

TASK [../roles/vpnclient : set up forward packages across routers] **********************************
changed: [vpnclient]

TASK [../roles/vpnclient : install base tools] ******************************************************
changed: [vpnclient]

TASK [../roles/vpnclient : Copy "static.key" file] **************************************************
changed: [vpnclient]

TASK [../roles/vpnclient : Copy "clienttap.conf" file] **********************************************
changed: [vpnclient]

RUNNING HANDLER [../roles/vpnclient : systemctl daemon reload] **************************************
ok: [vpnclient]

PLAY RECAP ******************************************************************************************
vpnclient                  : ok=11   changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 

```
Проверяем




```shell

VPNSERVER


root@vpnserver:/home/vagrant# cat /var/log/openvpn.log 
2023-11-04 17:30:58 Cipher negotiation is disabled since neither P2MP client nor server mode is enabled
2023-11-04 17:30:58 WARNING: file '/etc/openvpn/static.key' is group or others accessible
2023-11-04 17:30:58 OpenVPN 2.5.1 x86_64-pc-linux-gnu [SSL (OpenSSL)] [LZO] [LZ4] [EPOLL] [PKCS11] [MH/PKTINFO] [AEAD] built on May 14 2021
2023-11-04 17:30:58 library versions: OpenSSL 1.1.1w  11 Sep 2023, LZO 2.10
2023-11-04 17:30:58 WARNING: INSECURE cipher (BF-CBC) with block size less than 128 bit (64 bit).  This allows attacks like SWEET32.  Mitigate by using a --cipher with a larger block size (e.g. AES-256-CBC). Support for these insecure ciphers will be removed in OpenVPN 2.6.
2023-11-04 17:30:58 Outgoing Static Key Encryption: Cipher 'BF-CBC' initialized with 128 bit key
2023-11-04 17:30:58 WARNING: INSECURE cipher (BF-CBC) with block size less than 128 bit (64 bit).  This allows attacks like SWEET32.  Mitigate by using a --cipher with a larger block size (e.g. AES-256-CBC). Support for these insecure ciphers will be removed in OpenVPN 2.6.
2023-11-04 17:30:58 Outgoing Static Key Encryption: Using 160 bit message hash 'SHA1' for HMAC authentication
2023-11-04 17:30:58 Incoming Static Key Encryption: Cipher 'BF-CBC' initialized with 128 bit key
2023-11-04 17:30:58 WARNING: INSECURE cipher (BF-CBC) with block size less than 128 bit (64 bit).  This allows attacks like SWEET32.  Mitigate by using a --cipher with a larger block size (e.g. AES-256-CBC). Support for these insecure ciphers will be removed in OpenVPN 2.6.
2023-11-04 17:30:58 Incoming Static Key Encryption: Using 160 bit message hash 'SHA1' for HMAC authentication
2023-11-04 17:30:58 TUN/TAP device tap0 opened
2023-11-04 17:30:58 net_iface_mtu_set: mtu 1500 for tap0
2023-11-04 17:30:58 net_iface_up: set tap0 up
2023-11-04 17:30:58 net_addr_v4_add: 10.10.10.1/24 dev tap0
2023-11-04 17:30:58 Could not determine IPv4/IPv6 protocol. Using AF_INET
2023-11-04 17:30:58 Socket Buffers: R=[212992->212992] S=[212992->212992]
2023-11-04 17:30:58 UDPv4 link local (bound): [AF_INET][undef]:1194
2023-11-04 17:30:58 UDPv4 link remote: [AF_UNSPEC]
2023-11-04 19:28:15 Peer Connection Initiated with [AF_INET]192.168.56.20:1194
2023-11-04 19:28:15 WARNING: this configuration may cache passwords in memory -- use the auth-nocache option to prevent this
2023-11-04 19:28:15 Initialization Sequence Completed


root@vpnserver:/home/vagrant# ping 10.10.10.2
PING 10.10.10.2 (10.10.10.2) 56(84) bytes of data.
64 bytes from 10.10.10.2: icmp_seq=1 ttl=64 time=14.4 ms
64 bytes from 10.10.10.2: icmp_seq=2 ttl=64 time=3.90 ms
^C
--- 10.10.10.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 3.899/9.130/14.361/5.231 ms
root@vpnserver:/home/vagrant# ip route
default via 10.0.2.2 dev eth0 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 
10.10.10.0/24 dev tap0 proto kernel scope link src 10.10.10.1 
192.168.56.0/24 dev eth1 proto kernel scope link src 192.168.56.10 
root@vpnserver:/home/vagrant# 



VPNCLIENT

root@vpnclient:/home/vagrant# tail -20 /var/log/openvpn.log 
2023-11-04 19:31:21 Outgoing Static Key Encryption: Using 160 bit message hash 'SHA1' for HMAC authentication
2023-11-04 19:31:21 Incoming Static Key Encryption: Cipher 'BF-CBC' initialized with 128 bit key
2023-11-04 19:31:21 WARNING: INSECURE cipher (BF-CBC) with block size less than 128 bit (64 bit).  This allows attacks like SWEET32.  Mitigate by using a --cipher with a larger block size (e.g. AES-256-CBC). Support for these insecure ciphers will be removed in OpenVPN 2.6.
2023-11-04 19:31:21 Incoming Static Key Encryption: Using 160 bit message hash 'SHA1' for HMAC authentication
2023-11-04 19:31:21 net_route_v4_best_gw query: dst 0.0.0.0
2023-11-04 19:31:21 net_route_v4_best_gw result: via 10.0.2.2 dev eth0
2023-11-04 19:31:21 ROUTE_GATEWAY 10.0.2.2/255.255.255.0 IFACE=eth0 HWADDR=08:00:27:8d:c0:4d
2023-11-04 19:31:21 OpenVPN ROUTE: OpenVPN needs a gateway parameter for a --route option and no default was specified by either --route-gateway or --ifconfig options
2023-11-04 19:31:21 OpenVPN ROUTE: failed to parse/resolve route for host/network: 192.168.56.0
2023-11-04 19:31:21 TUN/TAP device tap0 opened
2023-11-04 19:31:21 net_iface_mtu_set: mtu 1500 for tap0
2023-11-04 19:31:21 net_iface_up: set tap0 up
2023-11-04 19:31:21 net_addr_v4_add: 10.10.10.2/24 dev tap0
2023-11-04 19:31:21 TCP/UDP: Preserving recently used remote address: [AF_INET]192.168.56.10:1194
2023-11-04 19:31:21 Socket Buffers: R=[212992->212992] S=[212992->212992]
2023-11-04 19:31:21 UDP link local (bound): [AF_INET][undef]:1194
2023-11-04 19:31:21 UDP link remote: [AF_INET]192.168.56.10:1194
2023-11-04 19:31:31 Peer Connection Initiated with [AF_INET]192.168.56.10:1194
2023-11-04 19:31:32 WARNING: this configuration may cache passwords in memory -- use the auth-nocache option to prevent this

root@vpnclient:/home/vagrant# ip route
default via 10.0.2.2 dev eth0 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 
10.10.10.0/24 dev tap0 proto kernel scope link src 10.10.10.2 
192.168.56.0/24 dev eth1 proto kernel scope link src 192.168.56.20 
root@vpnclient:/home/vagrant# ping 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=8.08 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=11.5 ms
^C
--- 10.10.10.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 8.084/9.809/11.535/1.725 ms



```
Поправим права на static.key на 600 для секьюрности (учтено в ansible)

Констатируем, что туннель на tap интерфейсах поднялся, доустановим iperf3 (Учтено в ansible)

Замеряем скорость

```shell

root@vpnserver:/home/vagrant# iperf3 -s 
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
Accepted connection from 10.10.10.2, port 42432
[  5] local 10.10.10.1 port 5201 connected to 10.10.10.2 port 42434
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-1.00   sec  4.12 MBytes  34.6 Mbits/sec                  
[  5]   1.00-2.00   sec  4.36 MBytes  36.6 Mbits/sec                  
[  5]   2.00-3.00   sec  4.89 MBytes  41.0 Mbits/sec                  
[  5]   3.00-4.00   sec  4.46 MBytes  37.4 Mbits/sec                  
[  5]   4.00-5.00   sec  4.76 MBytes  39.9 Mbits/sec                  
[  5]   5.00-6.00   sec  5.15 MBytes  43.2 Mbits/sec                  
[  5]   6.00-7.00   sec  5.75 MBytes  48.3 Mbits/sec                  
[  5]   7.00-8.00   sec  6.94 MBytes  58.2 Mbits/sec                  
[  5]   8.00-9.00   sec  6.42 MBytes  53.9 Mbits/sec                  
[  5]   9.00-10.00  sec  5.56 MBytes  46.6 Mbits/sec                  
[  5]  10.00-10.03  sec   106 KBytes  27.4 Mbits/sec                  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-10.03  sec  52.5 MBytes  43.9 Mbits/sec                  receiver
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------


root@vpnclient:/home/vagrant# iperf3 -c 10.10.10.1
Connecting to host 10.10.10.1, port 5201
[  5] local 10.10.10.2 port 42434 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  4.54 MBytes  38.0 Mbits/sec    0    235 KBytes       
[  5]   1.00-2.00   sec  4.51 MBytes  37.9 Mbits/sec   31    200 KBytes       
[  5]   2.00-3.00   sec  5.07 MBytes  42.3 Mbits/sec    0    223 KBytes       
[  5]   3.00-4.00   sec  4.51 MBytes  37.9 Mbits/sec   18    127 KBytes       
[  5]   4.00-5.00   sec  4.70 MBytes  39.4 Mbits/sec    4    105 KBytes       
[  5]   5.00-6.00   sec  5.00 MBytes  42.1 Mbits/sec    0    134 KBytes       
[  5]   6.00-7.00   sec  5.75 MBytes  48.1 Mbits/sec    6    121 KBytes       
[  5]   7.00-8.00   sec  7.04 MBytes  59.0 Mbits/sec    7    114 KBytes       
[  5]   8.00-9.00   sec  6.36 MBytes  53.5 Mbits/sec    6    110 KBytes       
[  5]   9.00-10.00  sec  5.44 MBytes  45.6 Mbits/sec    0    142 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  52.9 MBytes  44.4 Mbits/sec   72             sender
[  5]   0.00-10.03  sec  52.5 MBytes  43.9 Mbits/sec                  receiver

iperf Done.

root@vpnclient:/home/vagrant# iperf3 -c 10.10.10.1 -R
Connecting to host 10.10.10.1, port 5201
Reverse mode, remote host 10.10.10.1 is sending
[  5] local 10.10.10.2 port 38180 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-1.00   sec  4.46 MBytes  37.4 Mbits/sec                  
[  5]   1.00-2.00   sec  4.83 MBytes  40.5 Mbits/sec                  
[  5]   2.00-3.00   sec  4.84 MBytes  40.6 Mbits/sec                  
[  5]   3.00-4.00   sec  5.05 MBytes  42.3 Mbits/sec                  
[  5]   4.00-5.00   sec  4.57 MBytes  38.4 Mbits/sec                  
[  5]   5.00-6.00   sec  4.27 MBytes  35.8 Mbits/sec                  
[  5]   6.00-7.00   sec  4.38 MBytes  36.8 Mbits/sec                  
[  5]   7.00-8.00   sec  3.68 MBytes  30.9 Mbits/sec                  
[  5]   8.00-9.00   sec  3.75 MBytes  31.5 Mbits/sec                  
[  5]   9.00-10.00  sec  7.44 MBytes  62.4 Mbits/sec                  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.08  sec  47.9 MBytes  39.8 Mbits/sec   22             sender
[  5]   0.00-10.00  sec  47.3 MBytes  39.7 Mbits/sec                  receiver



```

Удалим с сервера и клиента конфиги tap и запустим установку для tun


```shell


root@vpnclient:/home/vagrant# systemctl stop openvpn

rm -rf /etc/openvpn/clienttap.conf 

root@vpnserver:/home/vagrant# systemctl stop openvpn


```


Запускаем последовательно

```shell
/vagrantdocs/lesson34-VPN/vm/ansible$ ansible-playbook playbooks/vpnserver.yml -t tun


~/vagrantdocs/lesson34-VPN/vm/ansible$ ansible-playbook playbooks/vpnclient.yml -t tun


PS Сделал два инстанса openvpn и разнес на разные порты с разными ip

ansible-playbook playbooks/vpnclient.yml -t tap,tun
ansible-playbook playbooks/vpnserver.yml -t tap,tun

```

Проверяем

```shell

root@vpnserver:/home/vagrant# ip a
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
       valid_lft 73109sec preferred_lft 73109sec
    inet6 fe80::a00:27ff:fe8d:c04d/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:9b:8c:1d brd ff:ff:ff:ff:ff:ff
    altname enp0s8
    inet 192.168.56.10/24 brd 192.168.56.255 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe9b:8c1d/64 scope link 
       valid_lft forever preferred_lft forever
10: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 500
    link/none 
    inet 10.10.20.1/24 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::d242:c7c:12c7:ac84/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever
11: tap0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 1000
    link/ether e6:9f:d3:88:8e:60 brd ff:ff:ff:ff:ff:ff
    inet 10.10.10.1/24 scope global tap0
       valid_lft forever preferred_lft forever
    inet6 fe80::fcec:a8ff:fe98:9a92/64 scope link 
       valid_lft forever preferred_lft forever


root@vpnserver:/home/vagrant# ip route
default via 10.0.2.2 dev eth0 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 
10.10.10.0/24 dev tap0 proto kernel scope link src 10.10.10.1 
10.10.20.0/24 dev tun0 proto kernel scope link src 10.10.20.1 
192.168.56.0/24 dev eth1 proto kernel scope link src 192.168.56.10 

root@vpnclient:/home/vagrant# ip a
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
       valid_lft 72415sec preferred_lft 72415sec
    inet6 fe80::a00:27ff:fe8d:c04d/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:3c:0d:3e brd ff:ff:ff:ff:ff:ff
    altname enp0s8
    inet 192.168.56.20/24 brd 192.168.56.255 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe3c:d3e/64 scope link 
       valid_lft forever preferred_lft forever
30: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 500
    link/none 
    inet 10.10.20.2/24 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::b00e:8fe9:6671:f547/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever


root@vpnclient:/home/vagrant# tail -f /var/log/openvpn.log 
2023-11-04 20:22:57 OpenVPN ROUTE: OpenVPN needs a gateway parameter for a --route option and no default was specified by either --route-gateway or --ifconfig options
2023-11-04 20:22:57 OpenVPN ROUTE: failed to parse/resolve route for host/network: 192.168.56.0
2023-11-04 20:22:57 TUN/TAP device tun0 opened
2023-11-04 20:22:57 net_iface_mtu_set: mtu 1500 for tun0
2023-11-04 20:22:57 net_iface_up: set tun0 up
2023-11-04 20:22:57 net_addr_v4_add: 10.10.20.2/24 dev tun0
2023-11-04 20:22:57 TCP/UDP: Preserving recently used remote address: [AF_INET]192.168.56.10:1195
2023-11-04 20:22:57 Socket Buffers: R=[212992->212992] S=[212992->212992]
2023-11-04 20:22:57 UDP link local (bound): [AF_INET][undef]:1194
2023-11-04 20:22:57 UDP link remote: [AF_INET]192.168.56.10:1195
2023-11-04 20:23:07 Peer Connection Initiated with [AF_INET]192.168.56.10:1195
2023-11-04 20:23:09 WARNING: this configuration may cache passwords in memory -- use the auth-nocache option to prevent this
2023-11-04 20:23:09 Initialization Sequence Completed


root@vpnclient:/home/vagrant#  ip route
default via 10.0.2.2 dev eth0 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 
10.10.20.0/24 dev tun0 proto kernel scope link src 10.10.20.2 
192.168.56.0/24 dev eth1 proto kernel scope link src 192.168.56.20 

root@vpnserver:/home/vagrant# ping 10.10.20.1
PING 10.10.20.1 (10.10.20.1) 56(84) bytes of data.
64 bytes from 10.10.20.1: icmp_seq=1 ttl=64 time=0.043 ms
64 bytes from 10.10.20.1: icmp_seq=2 ttl=64 time=0.180 ms


root@vpnclient:/home/vagrant# ping 10.10.20.1
PING 10.10.20.1 (10.10.20.1) 56(84) bytes of data.
64 bytes from 10.10.20.1: icmp_seq=1 ttl=64 time=3.40 ms
64 bytes from 10.10.20.1: icmp_seq=2 ttl=64 time=8.98 ms



```


Все поднялось, замеряем скорость

```shell

root@vpnserver:/home/vagrant# iperf3 -s
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
Accepted connection from 10.10.20.2, port 34688
[  5] local 10.10.20.1 port 5201 connected to 10.10.20.2 port 34694
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-1.00   sec  6.86 MBytes  57.5 Mbits/sec                  
[  5]   1.00-2.00   sec  7.96 MBytes  66.8 Mbits/sec                  
[  5]   2.00-3.00   sec  6.08 MBytes  51.0 Mbits/sec                  
[  5]   3.00-4.00   sec  4.18 MBytes  35.1 Mbits/sec                  
[  5]   4.00-5.00   sec  5.70 MBytes  47.9 Mbits/sec                  
[  5]   5.00-6.00   sec  7.20 MBytes  60.4 Mbits/sec                  
[  5]   6.00-7.00   sec  5.82 MBytes  48.9 Mbits/sec                  
[  5]   7.00-8.00   sec  12.1 MBytes   101 Mbits/sec                  
[  5]   8.00-9.00   sec  10.5 MBytes  88.0 Mbits/sec                  
[  5]   9.00-10.00  sec  4.90 MBytes  41.1 Mbits/sec                  
[  5]  10.00-10.05  sec   446 KBytes  75.3 Mbits/sec                  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-10.05  sec  71.7 MBytes  59.8 Mbits/sec                  receiver
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
Accepted connection from 10.10.20.2, port 44816
[  5] local 10.10.20.1 port 5201 connected to 10.10.20.2 port 44828
[ IetcD] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  7.02 MBytes  58.9 Mbits/sec    0    338 KBytes       
[  5]   1.00-2.00   sec  9.98 MBytes  83.7 Mbits/sec   52    222 KBytes       
[  5]   2.00-3.00   sec  5.02 MBytes  42.0 Mbits/sec   60    135 KBytes       
[  5]   3.00-4.00   sec  4.96 MBytes  41.7 Mbits/sec    2    116 KBytes       
[  5]   4.00-5.00   sec  4.59 MBytes  38.5 Mbits/sec    0    141 KBytes       
[  5]   5.00-6.00   sec  5.02 MBytes  42.1 Mbits/sec    7    128 KBytes       
[  5]   6.00-7.00   sec  6.51 MBytes  54.6 Mbits/sec    0    161 KBytes       
[  5]   7.00-8.00   sec  6.69 MBytes  56.1 Mbits/sec   24    102 KBytes       
[  5]   8.00-9.00   sec  6.14 MBytes  51.5 Mbits/sec    0    140 KBytes       
[  5]   9.00-10.00  sec  5.52 MBytes  46.3 Mbits/sec    9    128 KBytes       
[  5]  10.00-10.09  sec   571 KBytes  54.0 Mbits/sec    0    132 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.09  sec  62.0 MBytes  51.6 Mbits/sec  154             sender
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------



```

Итог у TUN интерфейса скорость более чем на 20 мегабит выше, чем у TAP


# Переходим на настройке RAS

Почистим конфиги от первой частина серверах

rm -rf /etc/openvpn/server{tap,tun}.conf
systemctl daemon-reload
systemctl restart openvpn


rm -rf /etc/openvpn/client{tap,tun}.conf
systemctl daemon-reload
systemctl restart openvpn


Для того чтобы организовать RAS на сертификатах необходимо развернуть инфраструктуру PKI на сервере VPNSERVER

Напишем shell модуль для ansible


```shell
cd /etc/openvpn
# Инициализация PKI
/usr/share/easy-rsa/easyrsa  init-pki
# Generate CA Certificate
echo 'VPNCA' | /usr/share/easy-rsa/easyrsa build-ca nopass
# Generate Server Certificate
#Request on the sign to certificate of server
echo 'vpnserver' | /usr/share/easy-rsa/easyrsa gen-req vpnserver nopass
# Signing to certificate of Server
echo 'yes' | /usr/share/easy-rsa/easyrsa sign-req server vpnserver

# Generate DH 2048 by default
/usr/share/easy-rsa/easyrsa gen-dh

# Generate ta.key of server
openvpn --genkey ta.key


# Generate Client Certificate
# Generate request to certificate of client
echo 'vpnclient' | /usr/share/easy-rsa/easyrsa gen-req vpnclient nopass
# Sigining to certificate of vpnclient
echo 'yes' | /usr/share/easy-rsa/easyrsa sign-req client vpnclient

```

Что делает скрипт сначала проверим вручную запустив на сервере  vpnserver

```shell

root@vpnserver:/etc/openvpn# cd /etc/openvpn
# Инициализация PKI
/usr/share/easy-rsa/easyrsa  init-pki
# Generate CA Certificate
echo 'VPNCA' | /usr/share/easy-rsa/easyrsa build-ca nopass
# Generate Server Certificate
#Request on the sign to certificate of server
echo 'vpnserver' | /usr/share/easy-rsa/easyrsa gen-req vpnserver nopass
# Signing to certificate of Server
echo 'yes' | /usr/share/easy-rsa/easyrsa sign-req server vpnserver

# Generate DH 2048 by default
/usr/share/easy-rsa/easyrsa gen-dh

# Generate ta.key of server
openvpn --genkey secret ta.key


# Generate Client Certificate
# Generate request to certificate of client
echo 'vpnclient' | /usr/share/easy-rsa/easyrsa gen-req vpnclient nopass
# Sigining to certificate of vpnclient
echo 'yes' | /usr/share/easy-rsa/easyrsa sign-req client vpnclient





init-pki complete; you may now create a CA or requests.
Your newly created PKI dir is: /etc/openvpn/pki


Using SSL: openssl OpenSSL 1.1.1w  11 Sep 2023
Generating RSA private key, 2048 bit long modulus (2 primes)
........+++++
.............+++++
e is 65537 (0x010001)
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [Easy-RSA CA]:
CA creation complete and you may now import and sign cert requests.
Your new CA certificate file for publishing is at:
/etc/openvpn/pki/ca.crt


Using SSL: openssl OpenSSL 1.1.1w  11 Sep 2023
Generating a RSA private key
..................................+++++
............................+++++
writing new private key to '/etc/openvpn/pki/easy-rsa-84524.p5lEpY/tmp.eP5IEq'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [vpnserver]:
Keypair and certificate request completed. Your files are:
req: /etc/openvpn/pki/reqs/vpnserver.req
key: /etc/openvpn/pki/private/vpnserver.key


Using SSL: openssl OpenSSL 1.1.1w  11 Sep 2023


You are about to sign the following certificate.
Please check over the details shown below for accuracy. Note that this request
has not been cryptographically verified. Please be sure it came from a trusted
source or that you have verified the request checksum with the sender.

Request subject, to be signed as a server certificate for 825 days:

subject=
    commonName                = vpnserver


Type the word 'yes' to continue, or any other input to abort.
  Confirm request details: Using configuration from /etc/openvpn/pki/easy-rsa-84547.Fawnlc/tmp.az98Vm
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'vpnserver'
Certificate is to be certified until Feb  7 07:48:11 2026 GMT (825 days)

Write out database with 1 new entries
Data Base Updated

Certificate created at: /etc/openvpn/pki/issued/vpnserver.crt


Using SSL: openssl OpenSSL 1.1.1w  11 Sep 2023
Generating DH parameters, 2048 bit long safe prime, generator 2
This is going to take a long time
.........+....................................................................................................................+......................................................................................................................++*++*++*++*

DH parameters of size 2048 created at /etc/openvpn/pki/dh.pem


Options error: unknown --genkey type: ta.key
Use --help for more information.
Using SSL: openssl OpenSSL 1.1.1w  11 Sep 2023
Generating a RSA private key
..............................................................................+++++
........................................+++++
writing new private key to '/etc/openvpn/pki/easy-rsa-84724.Mk2Rui/tmp.UN2I8o'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [vpnclient]:
Keypair and certificate request completed. Your files are:
req: /etc/openvpn/pki/reqs/vpnclient.req
key: /etc/openvpn/pki/private/vpnclient.key


Using SSL: openssl OpenSSL 1.1.1w  11 Sep 2023


You are about to sign the following certificate.
Please check over the details shown below for accuracy. Note that this request
has not been cryptographically verified. Please be sure it came from a trusted
source or that you have verified the request checksum with the sender.

Request subject, to be signed as a client certificate for 825 days:

subject=
    commonName                = vpnclient


Type the word 'yes' to continue, or any other input to abort.
  Confirm request details: Using configuration from /etc/openvpn/pki/easy-rsa-84747.qoVze9/tmp.LngqqL
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'vpnclient'
Certificate is to be certified until Feb  7 07:49:39 2026 GMT (825 days)

Write out database with 1 new entries
Data Base Updated

Certificate created at: /etc/openvpn/pki/issued/vpnclient.crt



```

Удалим наш тестовый PKI `rm -rf /etc/opemvpn/pki` и добавим в ansible на сервер

```shell

Блоки

# Конфигурируем RAS

- name: Copy "serverras.conf" file
  copy:
    src: ../files/serverras.conf
    dest: /etc/openvpn/serverras.conf
  notify:
    - systemctl daemon reload
    - service restart openvpn
  tags:
    - ras

# /home/vagrant/common/temp/easyrsa/pki/ca.crt"
- name: EasyRSA - Build Auth Center CERT
  shell: |
        cd /etc/openvpn
        cd /etc/openvpn
        # Инициализация PKI
        /usr/share/easy-rsa/easyrsa  init-pki
        # Generate CA Certificate
        echo 'VPNCA' | /usr/share/easy-rsa/easyrsa build-ca nopass
        # Generate Server Certificate
        #Request on the sign to certificate of server
        echo 'vpnserver' | /usr/share/easy-rsa/easyrsa gen-req vpnserver nopass
        # Signing to certificate of Server
        echo 'yes' | /usr/share/easy-rsa/easyrsa sign-req server vpnserver

        # Generate DH 2048 by default
        /usr/share/easy-rsa/easyrsa gen-dh

        # Generate ta.key of server
        openvpn --genkey secret ta.key


        # Generate Client Certificate
        # Generate request to certificate of client
        echo 'vpnclient' | /usr/share/easy-rsa/easyrsa gen-req vpnclient nopass
        # Sigining to certificate of vpnclient
        echo 'yes' | /usr/share/easy-rsa/easyrsa sign-req client vpnclient
  register: result
  become: true
  tags:
    - ras



- name: debuggins
  debug:
    msg: "{{ result.stdout }}"
  tags:
    - ras


- name: Add a line of route to client /etc/openvpn/client/client
  ansible.builtin.lineinfile:
    path: /etc/openvpn/client/client
    line: iroute 10.10.30.0 255.255.255.0
    create: yes
  tags:
    - ras

Результат

TASK [../roles/vpnserver : Copy "serverras.conf" file] *************************
changed: [vpnserver]

TASK [../roles/vpnserver : EasyRSA - Build Auth Center CERT] *******************
changed: [vpnserver]

TASK [../roles/vpnserver : debuggins] ******************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-
packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot
import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-
packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot
import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
ok: [vpnserver] => {
    "msg": "\ninit-pki complete; you may now create a CA or requests.\nYour newly created PKI dir is: /home/vagrant/pki\n\n\nUsing SSL: openssl OpenSSL 1.1.1w  11 Sep 2023\n\nCA creation complete and you may now import and sign cert requests.\nYour new CA certificate file for publishing is at:\n/home/vagrant/pki/ca.crt\n\n\nUsing SSL: openssl OpenSSL 1.1.1w  11 Sep 2023\n\nKeypair and certificate request completed. Your files are:\nreq: /home/vagrant/pki/reqs/vpnserver.req\nkey: /home/vagrant/pki/private/vpnserver.key\n\n\nUsing SSL: openssl OpenSSL 1.1.1w  11 Sep 2023\n\n\nYou are about to sign the following certificate.\nPlease check over the details shown below for accuracy. Note that this request\nhas not been cryptographically verified. Please be sure it came from a trusted\nsource or that you have verified the request checksum with the sender.\n\nRequest subject, to be signed as a server certificate for 825 days:\n\nsubject=\n    commonName                = vpnserver\n\n\nType the word 'yes' to continue, or any other input to abort.\n  Confirm request details: \nCertificate created at: /home/vagrant/pki/issued/vpnserver.crt\n\n\nUsing SSL: openssl OpenSSL 1.1.1w  11 Sep 2023\n\nDH parameters of size 2048 created at /home/vagrant/pki/dh.pem\n\n\nUsing SSL: openssl OpenSSL 1.1.1w  11 Sep 2023\n\nKeypair and certificate request completed. Your files are:\nreq: /home/vagrant/pki/reqs/vpnclient.req\nkey: /home/vagrant/pki/private/vpnclient.key\n\n\nUsing SSL: openssl OpenSSL 1.1.1w  11 Sep 2023\n\n\nYou are about to sign the following certificate.\nPlease check over the details shown below for accuracy. Note that this request\nhas not been cryptographically verified. Please be sure it came from a trusted\nsource or that you have verified the request checksum with the sender.\n\nRequest subject, to be signed as a client certificate for 825 days:\n\nsubject=\n    commonName                = vpnclient\n\n\nType the word 'yes' to continue, or any other input to abort.\n  Confirm request details: \nCertificate created at: /home/vagrant/pki/issued/vpnclient.crt"
}

TASK [../roles/vpnserver : Add a line of route to client /etc/openvpn/client/client] ***
changed: [vpnserver]

RUNNING HANDLER [../roles/vpnserver : systemctl daemon reload] *****************
ok: [vpnserver]

RUNNING HANDLER [../roles/vpnserver : service restart openvpn] *****************
changed: [vpnserver]

PLAY RECAP *********************************************************************
vpnserver                  : ok=16   changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   



root@vpnserver:/etc/openvpn/pki/private# tail -f /var/log/openvpn.log 
2023-11-05 11:15:50 net_addr_ptp_v4_add: 10.10.30.1 peer 10.10.30.2 dev tun0
2023-11-05 11:15:50 net_route_v4_add: 10.10.30.0/24 via 10.10.30.2 dev [NULL] table 0 metric -1
2023-11-05 11:15:50 Could not determine IPv4/IPv6 protocol. Using AF_INET
2023-11-05 11:15:50 Socket Buffers: R=[212992->212992] S=[212992->212992]
2023-11-05 11:15:50 UDPv4 link local (bound): [AF_INET][undef]:993
2023-11-05 11:15:50 UDPv4 link remote: [AF_UNSPEC]
2023-11-05 11:15:50 MULTI: multi_init called, r=256 v=256
2023-11-05 11:15:50 IFCONFIG POOL IPv4: base=10.10.30.4 size=62
2023-11-05 11:15:50 IFCONFIG POOL LIST
2023-11-05 11:15:50 Initialization Sequence Completed


root@vpnserver:/etc/openvpn/pki/private# ss -tulnp
Netid State   Recv-Q  Send-Q   Local Address:Port   Peer Address:Port Process                             
udp   UNCONN  0       0              0.0.0.0:993         0.0.0.0:*     users:(("openvpn",pid=91841,fd=6)) 

```
Серверная часть готова и слушает порт


Необходимо скопировать сгенерированные на сервере ключи клиента на клиентскую машину.
Добавим в ansible playbook fetch модуль  для нужных файлов и положим сразу в каталог playbook для клиента.


```shell

- name: Get file ca.crt from vpnserver
  fetch:
    src: /etc/openvpn/pki/ca.crt
    dest: ../roles/vpnclient/files/clientras/
  tags: 
    - fetchras
    - ras

- name: Get file vpnclient.crt from vpnserver
  fetch:
    src: /etc/openvpn/pki/issued/vpnclient.crt
    dest: ../roles/vpnclient/files/clientras/
  tags: 
    - fetchras
    - ras

- name: Get file vpnclient.key from vpnserver
  fetch:
    src: /etc/openvpn/pki/private/vpnclient.key
    dest: ../roles/vpnclient/files/clientras/
  tags: 
    - fetchras
    - ras

```

В playbook клиента соотвественно добавим блоки copy


```shell

# Конфигурируем RAS ca.crt
- name: Copy "ca.crt" file
  copy:
    src: ../files/clientras/vpnserver/etc/openvpn/pki/ca.crt
    dest: /etc/openvpn/ca.crt
  notify:
    - systemctl daemon reload
    - service restart openvpn
  tags:
    - ras

# Конфигурируем RAS vpnclient.crt

- name: Copy "vpnclient.crt" file
  copy:
    src: ../files/clientras/vpnserver/etc/openvpn/pki/issued/vpnclient.crt
    dest: /etc/openvpn/vpnclient.crt
  notify:
    - systemctl daemon reload
    - service restart openvpn
  tags:
    - ras

# Конфигурируем RAS vpnclient.key

- name: Copy "vpnclient.key" file
  copy:
    src: ../files/clientras/vpnserver/etc/openvpn/pki/private/vpnclient.key
    dest: /etc/openvpn/vpnclient.key
  notify:
    - systemctl daemon reload
    - service restart openvpn
  tags:
    - ras

```
И запустим playbook

`~/vagrantdocs/lesson34-VPN/vm/ansible$ ansible-playbook playbooks/vpnclient.yml  -t ras`



Дополнительно выложу конфиги сервера и клиента, так как порты  и часть конфигурации изменены относительно методички


```shell

#### VPNSERVER

port 993
proto udp
dev tun
ca /etc/openvpn/pki/ca.crt
cert /etc/openvpn/pki/issued/vpnserver.crt
key /etc/openvpn/pki/private/vpnserver.key
dh /etc/openvpn/pki/dh.pem
server 10.10.30.0 255.255.255.0
ifconfig-pool-persist ipp.txt
client-to-client
client-config-dir /etc/openvpn/client
keepalive 10 120
#comp-lzo
persist-key
persist-tun
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3


#### VPNCLIENT

dev tun
proto udp
remote 192.168.56.10 993
client
resolv-retry infinite
remote-cert-tls server
ca ./ca.crt
cert ./vpnclient.crt
key ./vpnclient.key
route 192.168.56.0 255.255.255.0
persist-key
persist-tun
#comp-lzo
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3


```


Проверяем


```shell

На сервере

root@vpnserver:/etc/openvpn# tail -f /var/log/openvpn.log 
2023-11-05 12:30:57 net_route_v4_add: 10.10.30.0/24 via 10.10.30.2 dev [NULL] table 0 metric -1
2023-11-05 12:30:57 Could not determine IPv4/IPv6 protocol. Using AF_INET
2023-11-05 12:30:57 Socket Buffers: R=[212992->212992] S=[212992->212992]
2023-11-05 12:30:57 UDPv4 link local (bound): [AF_INET][undef]:993
2023-11-05 12:30:57 UDPv4 link remote: [AF_UNSPEC]
2023-11-05 12:30:57 MULTI: multi_init called, r=256 v=256
2023-11-05 12:30:57 IFCONFIG POOL IPv4: base=10.10.30.4 size=62
2023-11-05 12:30:57 IFCONFIG POOL LIST
2023-11-05 12:30:57 Initialization Sequence Completed
2023-11-05 12:30:59 192.168.56.1:58256 TLS: Initial packet from [AF_INET]192.168.56.1:58256, sid=57d1eb30 59b833ac
2023-11-05 12:30:59 192.168.56.1:58256 VERIFY OK: depth=1, CN=VPNCA
2023-11-05 12:30:59 192.168.56.1:58256 VERIFY OK: depth=0, CN=vpnclient
2023-11-05 12:30:59 192.168.56.1:58256 peer info: IV_VER=2.5.1
2023-11-05 12:30:59 192.168.56.1:58256 peer info: IV_PLAT=linux
2023-11-05 12:30:59 192.168.56.1:58256 peer info: IV_PROTO=6
2023-11-05 12:30:59 192.168.56.1:58256 peer info: IV_NCP=2
2023-11-05 12:30:59 192.168.56.1:58256 peer info: IV_CIPHERS=AES-256-GCM:AES-128-GCM
2023-11-05 12:30:59 192.168.56.1:58256 peer info: IV_LZ4=1
2023-11-05 12:30:59 192.168.56.1:58256 peer info: IV_LZ4v2=1
2023-11-05 12:30:59 192.168.56.1:58256 peer info: IV_LZO=1
2023-11-05 12:30:59 192.168.56.1:58256 peer info: IV_COMP_STUB=1
2023-11-05 12:30:59 192.168.56.1:58256 peer info: IV_COMP_STUBv2=1
2023-11-05 12:30:59 192.168.56.1:58256 peer info: IV_TCPNL=1
2023-11-05 12:30:59 192.168.56.1:58256 Control Channel: TLSv1.3, cipher TLSv1.3 TLS_AES_256_GCM_SHA384, 2048 bit RSA
2023-11-05 12:30:59 192.168.56.1:58256 [vpnclient] Peer Connection Initiated with [AF_INET]192.168.56.1:58256
2023-11-05 12:30:59 vpnclient/192.168.56.1:58256 MULTI_sva: pool returned IPv4=10.10.30.6, IPv6=(Not enabled)
2023-11-05 12:30:59 vpnclient/192.168.56.1:58256 MULTI: Learn: 10.10.30.6 -> vpnclient/192.168.56.1:58256
2023-11-05 12:30:59 vpnclient/192.168.56.1:58256 MULTI: primary virtual IP for vpnclient/192.168.56.1:58256: 10.10.30.6
2023-11-05 12:30:59 vpnclient/192.168.56.1:58256 Data Channel: using negotiated cipher 'AES-256-GCM'
2023-11-05 12:30:59 vpnclient/192.168.56.1:58256 Outgoing Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
2023-11-05 12:30:59 vpnclient/192.168.56.1:58256 Incoming Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
2023-11-05 12:30:59 vpnclient/192.168.56.1:58256 SENT CONTROL [vpnclient]: 'PUSH_REPLY,route 10.10.30.0 255.255.255.0,topology net30,ping 10,ping-restart 120,ifconfig 10.10.30.6 10.10.30.5,peer-id 0,cipher AES-256-GCM' (status=1)


root@vpnserver:/etc/openvpn# cat ipp.txt 
vpnclient,10.10.30.4,

root@vpnserver:/etc/openvpn# ping 10.10.30.6
PING 10.10.30.6 (10.10.30.6) 56(84) bytes of data.
64 bytes from 10.10.30.6: icmp_seq=1 ttl=64 time=5.11 ms
64 bytes from 10.10.30.6: icmp_seq=2 ttl=64 time=7.29 ms




На клиенте

root@vpnclient:/etc/openvpn# tail -20 /var/log/openvpn.log 
2023-11-05 12:30:52 UDP link remote: [AF_INET]192.168.56.10:993
2023-11-05 12:30:59 TLS: Initial packet from [AF_INET]192.168.56.10:993, sid=80a54086 f6e1602d
2023-11-05 12:30:59 VERIFY OK: depth=1, CN=VPNCA
2023-11-05 12:30:59 VERIFY KU OK
2023-11-05 12:30:59 Validating certificate extended key usage
2023-11-05 12:30:59 ++ Certificate has EKU (str) TLS Web Server Authentication, expects TLS Web Server Authentication
2023-11-05 12:30:59 VERIFY EKU OK
2023-11-05 12:30:59 VERIFY OK: depth=0, CN=vpnserver
2023-11-05 12:30:59 Control Channel: TLSv1.3, cipher TLSv1.3 TLS_AES_256_GCM_SHA384, 2048 bit RSA
2023-11-05 12:30:59 [vpnserver] Peer Connection Initiated with [AF_INET]192.168.56.10:993
2023-11-05 12:30:59 PUSH: Received control message: 'PUSH_REPLY,route 10.10.30.0 255.255.255.0,topology net30,ping 10,ping-restart 120,ifconfig 10.10.30.6 10.10.30.5,peer-id 0,cipher AES-256-GCM'
2023-11-05 12:30:59 OPTIONS IMPORT: timers and/or timeouts modified
2023-11-05 12:30:59 OPTIONS IMPORT: --ifconfig/up options modified
2023-11-05 12:30:59 OPTIONS IMPORT: route options modified
2023-11-05 12:30:59 OPTIONS IMPORT: peer-id set
2023-11-05 12:30:59 OPTIONS IMPORT: adjusting link_mtu to 1624
2023-11-05 12:30:59 OPTIONS IMPORT: data channel crypto options modified
2023-11-05 12:30:59 Data Channel: using negotiated cipher 'AES-256-GCM'
2023-11-05 12:30:59 Outgoing Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
2023-11-05 12:30:59 Incoming Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
2023-11-05 12:30:59 net_route_v4_best_gw query: dst 0.0.0.0
2023-11-05 12:30:59 net_route_v4_best_gw result: via 10.0.2.2 dev eth0
2023-11-05 12:30:59 ROUTE_GATEWAY 10.0.2.2/255.255.255.0 IFACE=eth0 HWADDR=08:00:27:8d:c0:4d
2023-11-05 12:30:59 TUN/TAP device tun0 opened
2023-11-05 12:30:59 net_iface_mtu_set: mtu 1500 for tun0
2023-11-05 12:30:59 net_iface_up: set tun0 up
2023-11-05 12:30:59 net_addr_ptp_v4_add: 10.10.30.6 peer 10.10.30.5 dev tun0
2023-11-05 12:30:59 net_route_v4_add: 10.10.30.0/24 via 10.10.30.5 dev [NULL] table 0 metric -1
2023-11-05 12:30:59 WARNING: this configuration may cache passwords in memory -- use the auth-nocache option to prevent this
2023-11-05 12:30:59 Initialization Sequence Completed
2023-11-05 13:28:20 VERIFY OK: depth=1, CN=VPNCA
2023-11-05 13:28:20 VERIFY KU OK
2023-11-05 13:28:20 Validating certificate extended key usage
2023-11-05 13:28:20 ++ Certificate has EKU (str) TLS Web Server Authentication, expects TLS Web Server Authentication


root@vpnclient:/etc/openvpn# ping 10.10.30.1
PING 10.10.30.1 (10.10.30.1) 56(84) bytes of data.
64 bytes from 10.10.30.1: icmp_seq=1 ttl=64 time=10.6 ms
64 bytes from 10.10.30.1: icmp_seq=2 ttl=64 time=9.03 ms
64 bytes from 10.10.30.1: icmp_seq=3 ttl=64 time=12.7 ms


```

Соединение установлено.
VPN туннель на сертификатах поднят

Итоговое дерево файлов


```shell

vm
├── ansible
│   ├── ansible.cfg
│   ├── inventories
│   │   └── hosts
│   ├── playbooks
│   │   ├── vpnclient.yml
│   │   └── vpnserver.yml
│   └── roles
│       ├── vpnclient
│       │   ├── files
│       │   │   ├── clientras
│       │   │   │   └── vpnserver
│       │   │   │       └── etc
│       │   │   │           └── openvpn
│       │   │   │               └── pki
│       │   │   │                   ├── ca.crt
│       │   │   │                   ├── issued
│       │   │   │                   │   └── vpnclient.crt
│       │   │   │                   └── private
│       │   │   │                       └── vpnclient.key
│       │   │   ├── clientras.conf
│       │   │   ├── clienttap.conf
│       │   │   ├── clienttun.conf
│       │   │   └── static.key
│       │   ├── handlers
│       │   │   └── main.yml
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── vars
│       │       └── main.yml
│       └── vpnserver
│           ├── files
│           │   ├── serverras.conf
│           │   ├── servertap.conf
│           │   ├── servertun.conf
│           │   └── static.key
│           ├── handlers
│           │   └── main.yml
│           ├── tasks
│           │   └── main.yml
│           └── vars
│               └── main.yml
├── v2a.py
└── Vagrantfile



```



Задание выполнено.

