# Lesson35-DNS, настраиваем split-dns


## Цель:

создать домашнюю сетевую лабораторию;
изучить основы DNS;
научиться работать с технологией Split-DNS в Linux-based системах.

Описание/Пошаговая инструкция выполнения домашнего задания:

Для выполнения домашнего задания используйте методичку
https://docs.google.com/document/d/13kjusaFEzv6Ip_9soeDj2Ry-6WK8IDX7/edit?usp=share_link&ouid=104106368295333385634&rtpof=true&sd=true
Что нужно сделать?

    взять стенд https://github.com/erlong15/vagrant-bind
    добавить еще один сервер client2
    завести в зоне dns.lab
    имена
    web1 - смотрит на клиент1
    web2 смотрит на клиент2
    завести еще одну зону newdns.lab
    завести в ней запись
    www - смотрит на обоих клиентов
    настроить split-dns
    клиент1 - видит обе зоны, но в зоне dns.lab только web1
    клиент2 видит только dns.lab
    настроить все без выключения selinux*
    Формат сдачи ДЗ - vagrant + ansible
    В чат ДЗ отправьте ссылку на ваш git-репозиторий. Обычно мы проверяем ДЗ в течение 48 часов.
    Если возникнут вопросы, обращайтесь к студентам, преподавателям и наставникам в канал группы в Telegram.
    Удачи при выполнении!



Выполнение

Скачаем и адаптируем Vagrantfile

```shell

# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  # config.vm.box = "generic/centos7"
  config.vm.box = "debian/bullseye64"

  # vagrant-gatling-rsync is starting the sync engine
  # because you have at least one rsync folder.
  # To disable this behavior, set `config.gatling.rsync_on_startup = false` in your Vagrantfile.
  config.gatling.rsync_on_startup = false

  #config.vm.provision "ansible" do |ansible|
  #  ansible.verbose = "vvv"
  #  ansible.playbook = "provisioning/playbook.yml"
  #  ansible.sudo = "true"
  #end

  config.vm.provider "virtualbox" do |v|
    v.memory = 256
    v.cpus = 1
  end

  config.vm.define "ns01" do |ns01|
    ns01.vm.network "private_network", ip: "192.168.56.10", virtualbox__intnet: "dns"
    ns01.vm.hostname = "ns01"
  end

  config.vm.define "ns02" do |ns02|
    ns02.vm.network "private_network", ip: "192.168.56.11", virtualbox__intnet: "dns"
    ns02.vm.hostname = "ns02"
  end

  config.vm.define "client1" do |client1|
    client1.vm.network "private_network", ip: "192.168.56.15", virtualbox__intnet: "dns"
    client1.vm.hostname = "client1"
  end

  config.vm.define "client2" do |client2|
    client2.vm.network "private_network", ip: "192.168.56.16", virtualbox__intnet: "dns"
    client2.vm.hostname = "client2"
  end

end

```

Заполним файл hosts

`python3 v2a.py -o ansible/inventories/hosts`

Соберем файл playbook для сервера ns01, согласно методичке с "небольшими" ОГРОМНЫМИ КАК оказалось изменениями для debian дистрибутива.


Сначала соберем  playbook для master 

Подготовим ключ для трансфера зоны



```shell


root@ns01:/home/vagrant# tsig-keygen -a hmac-sha512 zonetransfer.key
key "zonetransfer.key" {
	algorithm hmac-sha512;
	secret "5Y/ac+P9cLHzi//RMgXTZEbGSjyXyZfr6y8+10WjWn7tF6rL27oCWF5AlNrcb/w6+3RZnXURffTeMcKxI8iQjA==";
};


```
Подготовим файл ключа

### named.zonetransfer.key

```shell
key "zonetransfer.key" {
    algorithm hmac-sha512;
    secret "/ln9PT3pU5R31IhuHxpCS/HLLLcLz2WyGQ0PtWU+9Qt51v0WwfS/aupm+elsoht2YjzVZnmbigW1VEL/eIuRSw==";
};

#Укажем сервер с которого будем забирать зоны (master)

```


```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson35-DNS/vm/ansible$ tree roles/ns01/
roles/ns01/
├── files
│   ├── master-named.conf
│   ├── master-named.conf.internal-zones
│   ├── master-named.conf.options
│   ├── named.ddns.lab
│   ├── named.dns.lab
│   ├── named.dns.lab.rev
│   ├── named.zonetransfer.key
│   └── servers-resolv.conf
├── handlers
│   └── main.yml
├── tasks
│   └── main.yml
└── vars
    └── main.yml
```

Подключаем конфиг файлы


# master-named.conf

```shell

include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
#include "/etc/bind/named.conf.default-zones";
include "/etc/bind/named.conf.internal-zones";
#include "/etc/bind/named.conf.external-zones";
include "/etc/bind/named.zonetransfer.key"; 
```

# master-named.conf.options

```shell

acl "trusted" {
#10.128.10.11;    # ns1 - can be set to localhost
192.168.56.0/24;
127.0.0.1;
key "zonetransfer.key";
};

options {

    // network 
	listen-on port 53 { 127.0.0.1; 192.168.56.10; };
	listen-on-v6 { none; };

    // data
	directory "/var/cache/bind";

    // server
	recursion yes;
    allow-recursion { trusted; };  # allows recursive queries from "trusted" clients
	allow-query     { trusted;};
    allow-transfer { trusted; };
    // forwarders { 8.8.8.8; 8.8.4.4; };
    dnssec-validation yes;
    auth-nxdomain no;    # conform to RFC1035

};

```

#  master-named.conf.internal-zones

```shell

view "internal" {

        match-clients {
                localhost;
                127.0.0.1;
                192.168.56.0/24;
                key "zonetransfer.key";
        };
        server 192.168.56.11 {
            keys { zonetransfer.key; };
        };
        zone "dns.lab" {
            type master;
            allow-transfer { key "zonetransfer.key"; };
            file "/etc/bind/named.dns.lab";
        };
        zone "56.168.192.in-addr.arpa" {
            type master;
            allow-transfer { key "zonetransfer.key"; };
            file "/etc/bind/named.dns.lab.rev";
        };
        // labs ddns zone
        zone "ddns.lab" {
            type master;
            allow-transfer { key "zonetransfer.key"; };
            allow-update { key "zonetransfer.key"; };
            file "/etc/bind/named.ddns.lab";
        };
        include "/etc/bind/named.conf.default-zones";

};

// настройки логирования
logging {
          channel "misc" {
                    file "/var/log/named/misc.log" versions 4 size 4m;
                    print-time yes;
                    print-severity yes;
                    print-category yes;
          };

          channel "query" {
                    file "/var/log/named/query.log" versions 4 size 4m;
                    print-time yes;
                    print-severity no;
                    print-category no;
          };

          category default {
                    "misc";
          };

          category queries {
                    "query";
          };
};

```


PS если логи писать в другое место то поправить

``` shell
    nano /etc/apparmor.d/usr.sbin.named


добавляем /var/log/bind/** rw,

```

# Ansible log


```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson35-DNS/vm/ansible$ ansible-playbook playbooks/ns01.yml

PLAY [Playbook of "ns01"] ****************************************************************************************************************************

TASK [Gathering Facts] *******************************************************************************************************************************
[WARNING]: Platform linux on host ns01 is using the discovered Python interpreter at /usr/bin/python3, but future installation of another Python
interpreter could change this. See https://docs.ansible.com/ansible/2.9/reference_appendices/interpreter_discovery.html for more information.
ok: [ns01]

TASK [../roles/ns01 : set timezone] ******************************************************************************************************************
changed: [ns01]

TASK [../roles/ns01 : Synchronize datetime | Install chrony] *****************************************************************************************
ok: [ns01]

TASK [../roles/ns01 : Synchronize datetime | Turn on chronyd] ****************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name
'environmentfilter' from 'jinja2.filters' (/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name
'environmentfilter' from 'jinja2.filters' (/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
ok: [ns01]

TASK [../roles/ns01 : install base tools] ************************************************************************************************************
changed: [ns01]

TASK [../roles/ns01 : Disable ufw services if enabled] ***********************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name
'environmentfilter' from 'jinja2.filters' (/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name
'environmentfilter' from 'jinja2.filters' (/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
ok: [ns01] => (item=ufw)

TASK [../roles/ns01 : install BIND packages] *********************************************************************************************************
changed: [ns01]

TASK [../roles/ns01 : copy transferkey to all servers and the client] ********************************************************************************
changed: [ns01]

TASK [../roles/ns01 : copy named.conf] ***************************************************************************************************************
changed: [ns01]

TASK [../roles/ns01 : copy named.conf.options] *******************************************************************************************************
changed: [ns01]

TASK [../roles/ns01 : copy named.conf.internal-zones] ************************************************************************************************
changed: [ns01]

TASK [../roles/ns01 : Create a directory BIND if it does not exist] **********************************************************************************
changed: [ns01]

TASK [../roles/ns01 : Change file query.log  ownership, group and permissions] ***********************************************************************
changed: [ns01]

TASK [../roles/ns01 : Change file misc.log ownership, group and permissions] *************************************************************************
changed: [ns01]

TASK [../roles/ns01 : Change file /var/log/named_stats.log ownership, group and permissions] *********************************************************
changed: [ns01]

TASK [../roles/ns01 : copy zones] ********************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name
'environmentfilter' from 'jinja2.filters' (/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name
'environmentfilter' from 'jinja2.filters' (/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
changed: [ns01] => (item=/home/sincere/vagrantdocs/lesson35-DNS/vm/ansible/roles/ns01/files/named.dns.lab)
changed: [ns01] => (item=/home/sincere/vagrantdocs/lesson35-DNS/vm/ansible/roles/ns01/files/named.dns.lab.rev)
changed: [ns01] => (item=/home/sincere/vagrantdocs/lesson35-DNS/vm/ansible/roles/ns01/files/named.ddns.lab)

TASK [../roles/ns01 : copy resolv.conf to the servers] ***********************************************************************************************
changed: [ns01]

TASK [../roles/ns01 : set /etc/bind permissions] *****************************************************************************************************
changed: [ns01]

TASK [../roles/ns01 : ensure bind9 is running and enabled] *******************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name
'environmentfilter' from 'jinja2.filters' (/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name
'environmentfilter' from 'jinja2.filters' (/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
changed: [ns01]

PLAY RECAP *******************************************************************************************************************************************
ns01                       : ok=19   changed=15   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   


```


## Проверяем доступность зон


```shell

root@ns01:/home/vagrant# named-checkconf 

root@ns01:/home/vagrant# named-checkzone dns.lab. /etc/bind/named.dns.lab
zone dns.lab/IN: loaded serial 2711201407
OK
root@ns01:/home/vagrant# named-checkzone ddns.lab /etc/bind/named.ddns.lab
zone ddns.lab/IN: loaded serial 2711201408
OK

root@ns01:/home/vagrant# named-checkzone 56.168.192.in-addr.arpa /etc/bind/named.dns.lab.rev 
/etc/bind/named.dns.lab.rev:20: file does not end with newline
zone 56.168.192.in-addr.arpa/IN: loaded serial 2711201407
OK


root@ns01:/home/vagrant# dig ANY @192.168.56.10 dns.lab

; <<>> DiG 9.16.44-Debian <<>> ANY @192.168.56.10 dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 65493
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 3, AUTHORITY: 0, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 159785484e81147001000000655328ff78d0d36eef7c26c4 (good)
;; QUESTION SECTION:
;dns.lab.			IN	ANY

;; ANSWER SECTION:
dns.lab.		3600	IN	SOA	ns01.dns.lab. root.dns.lab. 2711201407 3600 600 86400 600
dns.lab.		3600	IN	NS	ns02.dns.lab.
dns.lab.		3600	IN	NS	ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.		3600	IN	A	192.168.56.10
ns02.dns.lab.		3600	IN	A	192.168.56.11

;; Query time: 4 msec
;; SERVER: 192.168.56.10#53(192.168.56.10)
;; WHEN: Tue Nov 14 10:59:59 MSK 2023
;; MSG SIZE  rcvd: 175

```

### Первичная настройка DNS (Master) произведена.




## Настраиваем DNS (slave)

Создаем подобную структуру подобную master, кроме зон

# slave-named.conf


Подключаем конфиг файлы

```shell

include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
#include "/etc/bind/named.conf.default-zones";
include "/etc/bind/named.conf.internal-zones";
#include "/etc/bind/named.conf.external-zones";
include "/etc/bind/named.zonetransfer.key"; 
```

# slave-named.conf.options

```shell 

acl "trusted" {
#10.128.10.11;    # ns1 - can be set to localhost
192.168.56.0/24;
127.0.0.1;
key "zonetransfer.key";
};

options {

    // network 
	listen-on port 53 { 127.0.0.1; 192.168.56.11; };
	listen-on-v6 { none; };

    // data
	directory "/var/cache/bind";

    // server
	recursion yes;
    allow-recursion { trusted; };  # allows recursive queries from "trusted" clients
	allow-query     { trusted;};
    allow-transfer { trusted; };
    // forwarders { 8.8.8.8; 8.8.4.4; };
    dnssec-validation yes;
    auth-nxdomain no;    # conform to RFC1035

};

```

#  slave-named.conf.internal-zones

```shell

view "internal" {

        match-clients {
                localhost;
                127.0.0.1;
                192.168.56.0/24;
                key "zonetransfer.key";
        };
        server 192.168.56.10 {
            keys { zonetransfer.key; };
        };
        zone "dns.lab" {
            type slave;
            file "/etc/bind/named.dns.lab";
            masters { 192.168.50.10 key "zonetransfer.key"; };
        };
        zone "56.168.192.in-addr.arpa" {
            type slave;
             file "/etc/bind/named.dns.lab.rev";
            masters { 192.168.50.10 key "zonetransfer.key"; };
        };
        // labs ddns zone
        zone "ddns.lab" {
            type slave;
            file "/etc/bind/named.ddns.lab";
            masters { 192.168.50.10 key "zonetransfer.key"; };
        };
        include "/etc/bind/named.conf.default-zones";

};

// настройки логирования
logging {
          channel "misc" {
                    file "/var/log/named/misc.log" versions 4 size 4m;
                    print-time yes;
                    print-severity yes;
                    print-category yes;
          };

          channel "query" {
                    file "/var/log/named/query.log" versions 4 size 4m;
                    print-time yes;
                    print-severity no;
                    print-category no;
          };

          category default {
                    "misc";
          };

          category queries {
                    "query";
          };
};

```
# Ansible log

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson35-DNS/vm/ansible$ ansible-playbook playbooks/ns02.yml

PLAY [Playbook of "ns02"] ****************************************************************************************************************************

TASK [Gathering Facts] *******************************************************************************************************************************
[WARNING]: Platform linux on host ns02 is using the discovered Python interpreter at /usr/bin/python3, but future installation of another Python
interpreter could change this. See https://docs.ansible.com/ansible/2.9/reference_appendices/interpreter_discovery.html for more information.
ok: [ns02]

TASK [../roles/ns02 : set timezone] ******************************************************************************************************************
changed: [ns02]

TASK [../roles/ns02 : Synchronize datetime | Install chrony] *****************************************************************************************
ok: [ns02]

TASK [../roles/ns02 : Synchronize datetime | Turn on chronyd] ****************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name
'environmentfilter' from 'jinja2.filters' (/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name
'environmentfilter' from 'jinja2.filters' (/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
ok: [ns02]

TASK [../roles/ns02 : install base tools] ************************************************************************************************************
changed: [ns02]

TASK [../roles/ns02 : Disable ufw services if enabled] ***********************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name
'environmentfilter' from 'jinja2.filters' (/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name
'environmentfilter' from 'jinja2.filters' (/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
ok: [ns02] => (item=ufw)

TASK [../roles/ns02 : install BIND packages] *********************************************************************************************************
changed: [ns02]

TASK [../roles/ns02 : copy transferkey to all servers and the client] ********************************************************************************
changed: [ns02]

TASK [../roles/ns02 : copy named.conf] ***************************************************************************************************************
changed: [ns02]

TASK [../roles/ns02 : copy named.conf.options] *******************************************************************************************************
changed: [ns02]

TASK [../roles/ns02 : copy named.conf.internal-zones] ************************************************************************************************
changed: [ns02]

TASK [../roles/ns02 : Create a directory BIND if it does not exist] **********************************************************************************
changed: [ns02]

TASK [../roles/ns02 : Change file query.log  ownership, group and permissions] ***********************************************************************
changed: [ns02]

TASK [../roles/ns02 : Change file misc.log ownership, group and permissions] *************************************************************************
changed: [ns02]

TASK [../roles/ns02 : Change file /var/log/named_stats.log ownership, group and permissions] *********************************************************
changed: [ns02]

TASK [../roles/ns02 : copy resolv.conf to the servers] ***********************************************************************************************
changed: [ns02]

TASK [../roles/ns02 : set /etc/bind permissions] *****************************************************************************************************
changed: [ns02]

TASK [../roles/ns02 : ensure bind9 is running and enabled] *******************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name
'environmentfilter' from 'jinja2.filters' (/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name
'environmentfilter' from 'jinja2.filters' (/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
changed: [ns02]

PLAY RECAP *******************************************************************************************************************************************
ns02                       : ok=18   changed=14   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  


```


# Проверяем трансфер зоны

```shell


root@ns02:/home/vagrant# dig @192.168.56.10 dns.lab axfr -k /etc/bind/named.zonetransfer.key

; <<>> DiG 9.16.44-Debian <<>> @192.168.56.10 dns.lab axfr -k /etc/bind/named.zonetransfer.key
; (1 server found)
;; global options: +cmd
dns.lab.		3600	IN	SOA	ns01.dns.lab. root.dns.lab. 2711201408 3600 600 86400 600
dns.lab.		3600	IN	NS	ns01.dns.lab.
dns.lab.		3600	IN	NS	ns02.dns.lab.
ns01.dns.lab.		3600	IN	A	192.168.56.10
ns02.dns.lab.		3600	IN	A	192.168.56.11
web1.dns.lab.		3600	IN	A	192.168.56.15
web2.dns.lab.		3600	IN	A	192.168.56.16
dns.lab.		3600	IN	SOA	ns01.dns.lab. root.dns.lab. 2711201408 3600 600 86400 600
zonetransfer.key.	0	ANY	TSIG	hmac-sha512. 1699963219 300 64 l25eAwoq6/JDr0Yacdmadc2R1XhO0chkOAOgwowgoKoymuc6ujJDMeDa 2AWFsTS+9vDZ0cwjN5KCz/N4uK+zJg== 20811 NOERROR 0 
;; Query time: 40 msec
;; SERVER: 192.168.56.10#53(192.168.56.10)
;; WHEN: Tue Nov 14 15:00:19 MSK 2023
;; XFR size: 8 records (messages 1, bytes 374)

root@ns02:/home/vagrant# dig @192.168.56.10 ddns.lab axfr -k /etc/bind/named.zonetransfer.key

; <<>> DiG 9.16.44-Debian <<>> @192.168.56.10 ddns.lab axfr -k /etc/bind/named.zonetransfer.key
; (1 server found)
;; global options: +cmd
ddns.lab.		3600	IN	SOA	ns01.ddns.lab. root.ddns.lab. 2711201408 3600 600 86400 600
ddns.lab.		3600	IN	NS	ns01.ddns.lab.
ddns.lab.		3600	IN	NS	ns02.ddns.lab.
ns01.ddns.lab.		3600	IN	A	192.168.56.10
ns02.ddns.lab.		3600	IN	A	192.168.56.11
ddns.lab.		3600	IN	SOA	ns01.ddns.lab. root.ddns.lab. 2711201408 3600 600 86400 600
zonetransfer.key.	0	ANY	TSIG	hmac-sha512. 1699963800 300 64 5e2ZJNY3FIqZiD6Yq3wwVvslNgUg2LtPUvJGrXU8pgDfkl+xc0e+j28z VCSs4saW0j1P21V0C/GIOXZXfBre9g== 34381 NOERROR 0 
;; Query time: 40 msec
;; SERVER: 192.168.56.10#53(192.168.56.10)
;; WHEN: Tue Nov 14 15:10:01 MSK 2023
;; XFR size: 6 records (messages 1, bytes 333)

root@ns02:/home/vagrant# dig @192.168.56.10 dns.lab axfr

; <<>> DiG 9.16.44-Debian <<>> @192.168.56.10 dns.lab axfr
; (1 server found)
;; global options: +cmd
; Transfer failed.


```

Зона передается по ключу и без ключа не передается


Проверим slave сервер


```shell

root@ns02:/home/vagrant# tree /var/cache/bind/
/var/cache/bind/
├── managed-keys.bind
├── managed-keys.bind.jnl
├── named.ddns.lab
├── named.dns.lab
└── named.dns.lab.rev


oot@ns02:/home/vagrant# dig ANY @192.168.56.11 dns.lab.

; <<>> DiG 9.16.44-Debian <<>> ANY @192.168.56.11 dns.lab.
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 49211
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 3, AUTHORITY: 0, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 85c30c16a4f7a1230100000065539c8104e9a0093b2cf3d6 (good)
;; QUESTION SECTION:
;dns.lab.			IN	ANY

;; ANSWER SECTION:
dns.lab.		3600	IN	SOA	ns01.dns.lab. root.dns.lab. 2711201409 3600 600 86400 600
dns.lab.		3600	IN	NS	ns02.dns.lab.
dns.lab.		3600	IN	NS	ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.		3600	IN	A	192.168.56.10
ns02.dns.lab.		3600	IN	A	192.168.56.11

;; Query time: 0 msec
;; SERVER: 192.168.56.11#53(192.168.56.11)
;; WHEN: Tue Nov 14 19:12:49 MSK 2023
;; MSG SIZE  rcvd: 175



root@ns02:/home/vagrant# dig ANY @192.168.56.11 ddns.lab.

; <<>> DiG 9.16.44-Debian <<>> ANY @192.168.56.11 ddns.lab.
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 51126
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 3, AUTHORITY: 0, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 810307302b810fea0100000065539cd6a54bc6c23d0403b9 (good)
;; QUESTION SECTION:
;ddns.lab.			IN	ANY

;; ANSWER SECTION:
ddns.lab.		3600	IN	SOA	ns01.ddns.lab. root.ddns.lab. 2711201408 3600 600 86400 600
ddns.lab.		3600	IN	NS	ns02.ddns.lab.
ddns.lab.		3600	IN	NS	ns01.ddns.lab.

;; ADDITIONAL SECTION:
ns01.ddns.lab.		3600	IN	A	192.168.56.10
ns02.ddns.lab.		3600	IN	A	192.168.56.11

;; Query time: 0 msec
;; SERVER: 192.168.56.11#53(192.168.56.11)
;; WHEN: Tue Nov 14 19:14:14 MSK 2023
;; MSG SIZE  rcvd: 176


```


# Настроим SPLIT-DNS

Создаем дополнительный файл зоны dns.lab, в котором будет прописана только одна запись: /etc/named/named.dns.lab.client

```shell

$TTL 3600
$ORIGIN dns.lab.
@               IN      SOA     ns01.dns.lab. root.dns.lab. (
                            2711201409 ; serial
                            3600       ; refresh (1 hour)
                            600        ; retry (10 minutes)
                            86400      ; expire (1 day)
                            600        ; minimum (10 minutes)
                        )

                IN      NS      ns01.dns.lab.
                IN      NS      ns02.dns.lab.

; DNS Servers
ns01            IN      A       192.168.56.10
ns02            IN      A       192.168.56.11

;Web
web1            IN      A       192.168.56.15


```


Подготовим ключи для client1 и client2

tsig-keygen -a hmac-sha512 client1.key
tsig-keygen -a hmac-sha512 client2.key


```shell

root@ns01:/home/vagrant# tsig-keygen -a hmac-sha512 client1.key

tsig-keygen -a hmac-sha512 client2.key

key "client1.key" {
	algorithm hmac-sha512;
	secret "wFuP4XkMQ5RekP4/ecodsQM+K5zutTtzjcfupA/SQwYla1w+kDn0gaW2/O3J9MrZr6iAnRlH4EWsGt/pRuLiPQ==";
};

key "client2.key" {
	algorithm hmac-sha512;
	secret "bMAtc3lpzunsz2b1MdeG2aoseC063P9djT/POUHYCxYKJTWutZ0HhmfSPvUpS1W9+JeIFXiHoCOFBECf4ZanrQ==";
};



```

Внесем изменения  в named.conf


## master

### master-named.conf.internal-zones - только добавленная часть

```shell


### client key for split dns part2

key "client1.key" {
	algorithm hmac-sha512;
	secret "wFuP4XkMQ5RekP4/ecodsQM+K5zutTtzjcfupA/SQwYla1w+kDn0gaW2/O3J9MrZr6iAnRlH4EWsGt/pRuLiPQ==";
};

key "client2.key" {
	algorithm hmac-sha512;
	secret "bMAtc3lpzunsz2b1MdeG2aoseC063P9djT/POUHYCxYKJTWutZ0HhmfSPvUpS1W9+JeIFXiHoCOFBECf4ZanrQ==";
};

## WHO CAN USE OF VIEW
// Указание Access листов 
acl client1 { !key client2.key; key client1.key; 192.168.56.15; };
acl client2 { !key client1.key; key client2.key; 192.168.56.16; };

view "client1" {
    // Кому из клиентов разрешено подключаться, нужно указать имя access-листа
    match-clients { client1; };

    // Описание зоны dns.lab для client
    zone "dns.lab" {
        // Тип сервера — мастер
        type master;
        // Добавляем ссылку на файл зоны, который создали в прошлом пункте
        file "/etc/bind/named.dns.lab.client";
        // Адрес хостов, которым будет отправлена информация об изменении зоны
        also-notify { 192.168.56.11 key client1.key; };
    };
    // ddns.lab zone
    zone "ddns.lab" {
        type master;
        file "/etc/bind/named.ddns.lab";
        also-notify { 192.168.56.11 key client1.key; };
    };
};

// Описание view для client2
view "client2" {
    match-clients { client2; };

    // dns.lab zone
    zone "dns.lab" {
        type master;
        file "/etc/bind/named.dns.lab";
        also-notify { 192.168.56.11 key client2.key; };
    };

    // dns.lab zone reverse
    zone "56.168.192.in-addr.arpa" {
        type master;
        file "/etc/bind/named.dns.lab.rev";
        also-notify { 192.168.56.11 key client2.key; };
    };
};

### END of Part2

```

## slave-named.conf.internal-zones - только измененная часть

```shell


### client key for split dns part2




key "client1.key" {
	algorithm hmac-sha512;
	secret "wFuP4XkMQ5RekP4/ecodsQM+K5zutTtzjcfupA/SQwYla1w+kDn0gaW2/O3J9MrZr6iAnRlH4EWsGt/pRuLiPQ==";
};

key "client2.key" {
	algorithm hmac-sha512;
	secret "bMAtc3lpzunsz2b1MdeG2aoseC063P9djT/POUHYCxYKJTWutZ0HhmfSPvUpS1W9+JeIFXiHoCOFBECf4ZanrQ==";
};

## WHO CAN USE OF VIEW


// Указание Access листов 
acl client1 { !key client2.key; key client1.key; 192.168.56.15; };
acl client2 { !key client1.key; key client2.key; 192.168.56.16; };

view "client1" {
    // Кому из клиентов разрешено подключаться, нужно указать имя access-листа
    match-clients { client1; };

    // Описание зоны dns.lab для client
    zone "dns.lab" {
        // Тип сервера — мастер
        type slave;
        // Добавляем ссылку на файл зоны
        file "named.dns.lab.client1";
        masters { 192.168.56.10 key "client1.key"; };
    };

    // ddns.lab zone
    zone "ddns.lab" {
        type slave;
        file "named.ddns.lab.client1";
        masters { 192.168.56.10 key "client1.key"; };
    };
};

// Описание view для client2
view "client2" {
    match-clients { client2; };

    // dns.lab zone
    zone "dns.lab" {
        type slave;
        file "named.dns.lab.client2";
        masters { 192.168.56.10 key "client2.key"; };
    };

    // dns.lab zone reverse
    zone "56.168.192.in-addr.arpa" {
        type slave;
        file "named.dns.lab.client2.rev";
        masters { 192.168.56.10 key "client2.key"; };
    };
};

### END of Part2


```


На клиентах изменим resolv.conf указав ns сервера 192.168.56.10 и 192.168.56.11


Проверка

```shell

# Запрос c client1 на ns01
root@client1:/home/vagrant# dig A @192.168.56.10 web1.dns.lab +short
192.168.56.15

root@client1:/home/vagrant# dig A @192.168.56.10 web2.dns.lab +short

root@client1:/home/vagrant# dig A @192.168.56.10 ns01.ddns.lab +short
192.168.56.10
root@client1:/home/vagrant# 

# Запрос c client1 на ns02

root@client1:/home/vagrant# dig A @192.168.56.11 ns01.ddns.lab +short
192.168.56.10
root@client1:/home/vagrant# dig A @192.168.56.11 web2.dns.lab +short
root@client1:/home/vagrant# dig A @192.168.56.11 web1.dns.lab +short
192.168.56.15



# Запрос c client2 на ns01

root@client2:/home/vagrant# dig A @192.168.56.10 web1.dns.lab +short
192.168.56.15
root@client2:/home/vagrant# dig A @192.168.56.10 web2.dns.lab +short
192.168.56.16
root@client2:/home/vagrant# dig A @192.168.56.10 ns01.ddns.lab +short


# Запрос c client2 на ns02

root@client2:/home/vagrant# dig A @192.168.56.11 web1.dns.lab +short
192.168.56.15
root@client2:/home/vagrant# dig A @192.168.56.11 web2.dns.lab +short
192.168.56.16
root@client2:/home/vagrant# dig A @192.168.56.11 ns01.ddns.lab +short


```
Поднять итоговый стенд можно командой

`lesson35-DNS/vm/ansible$ ansible-playbook playbooks/allhosts.yml`

SELinux в Debian нет, но условиям apparmor удовлетворил.

# Задание выполнено.
