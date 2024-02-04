# Проект

## Дипломный проект

### Тема: Организация сетевой связности распределенной филиальной сети на основе IPSEC (быстрое добавление новых узлов) с управлением конфигурацией через отказоустойчивый web.

Требования:
1. Централизованная конфигурация новых и существующих узлов.
2. По схеме без центрального узла
3. Базовая ОС Debian 12 - но стараться сделать ОС независимую конфигурацию
4. Конфигурация фаервола на узлах
5. Web - часть не является одним из узлов рассматриваемой сети - желательно географически разнесенная и бд (мастер-slave)
6. Сбор логов с хостов rsyslogd
7. Backup - выберу позже.
8. В качестве системы мониторинга Zabbix.


PS. На написание связки web+db надо заложить около двух месяцев уйдет в самостоятельную раюочую чать - не к дипломному проекту


### Выполнение.


1. Необходимо подготовить шаблон базовой виртуальной машины на основе Debian 12

Воспользуемся готовым образом с vagrant cloud


Vagrantfile


```shell



```

Поднимем машинки



```shell



Начнем создавать  ansible-playbook

Пропишем файл hosts для ansible

python3 v2a.py -o ansible/inventories/hosts

Файл hosts

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson99-DIPLOM/vm$ cat  ansible/inventories/hosts
star1 ansible_ssh_host=127.0.0.1 ansible_ssh_user=vagrant ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_private_key_file=/home/sincere/vagrantdocs/lesson99-DIPLOM/vm/.vagrant/machines/star1/virtualbox/private_key ansible_ssh_port=2222 ansible_ssh_transfer_method=scp
star2 ansible_ssh_host=127.0.0.1 ansible_ssh_user=vagrant ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_private_key_file=/home/sincere/vagrantdocs/lesson99-DIPLOM/vm/.vagrant/machines/star2/virtualbox/private_key ansible_ssh_port=2200 ansible_ssh_transfer_method=scp
node11 ansible_ssh_host=127.0.0.1 ansible_ssh_user=vagrant ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_private_key_file=/home/sincere/vagrantdocs/lesson99-DIPLOM/vm/.vagrant/machines/node11/virtualbox/private_key ansible_ssh_port=2201 ansible_ssh_transfer_method=scp
node12 ansible_ssh_host=127.0.0.1 ansible_ssh_user=vagrant ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_private_key_file=/home/sincere/vagrantdocs/lesson99-DIPLOM/vm/.vagrant/machines/node12/virtualbox/private_key ansible_ssh_port=2202 ansible_ssh_transfer_method=scp
node13 ansible_ssh_host=127.0.0.1 ansible_ssh_user=vagrant ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_private_key_file=/home/sincere/vagrantdocs/lesson99-DIPLOM/vm/.vagrant/machines/node13/virtualbox/private_key ansible_ssh_port=2203 ansible_ssh_transfer_method=scp
node222 ansible_ssh_host=127.0.0.1 ansible_ssh_user=vagrant ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_private_key_file=/home/sincere/vagrantdocs/lesson99-DIPLOM/vm/.vagrant/machines/node222/virtualbox/private_key ansible_ssh_port=2204 ansible_ssh_transfer_method=scp
mon222 ansible_ssh_host=127.0.0.1 ansible_ssh_user=vagrant ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_private_key_file=/home/sincere/vagrantdocs/lesson99-DIPLOM/vm/.vagrant/machines/mon222/virtualbox/private_key ansible_ssh_port=2205 ansible_ssh_transfer_method=scp
node225 ansible_ssh_host=127.0.0.1 ansible_ssh_user=vagrant ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_private_key_file=/home/sincere/vagrantdocs/lesson99-DIPLOM/vm/.vagrant/machines/node225/virtualbox/private_key ansible_ssh_port=2206 ansible_ssh_transfer_method=scp
web1 ansible_ssh_host=127.0.0.1 ansible_ssh_user=vagrant ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_private_key_file=/home/sincere/vagrantdocs/lesson99-DIPLOM/vm/.vagrant/machines/web1/virtualbox/private_key ansible_ssh_port=2207 ansible_ssh_transfer_method=scp
web2 ansible_ssh_host=127.0.0.1 ansible_ssh_user=vagrant ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_private_key_file=/home/sincere/vagrantdocs/lesson99-DIPLOM/vm/.vagrant/machines/web2/virtualbox/private_key ansible_ssh_port=2208 ansible_ssh_transfer_method=scp
database1 ansible_ssh_host=127.0.0.1 ansible_ssh_user=vagrant ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_private_key_file=/home/sincere/vagrantdocs/lesson99-DIPLOM/vm/.vagrant/machines/database1/virtualbox/private_key ansible_ssh_port=2209 ansible_ssh_transfer_method=scp
database2 ansible_ssh_host=127.0.0.1 ansible_ssh_user=vagrant ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_private_key_file=/home/sincere/vagrantdocs/lesson99-DIPLOM/vm/.vagrant/machines/database2/virtualbox/private_key ansible_ssh_port=2210 ansible_ssh_transfer_method=scp
backup1 ansible_ssh_host=127.0.0.1 ansible_ssh_user=vagrant ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_private_key_file=/home/sincere/vagrantdocs/lesson99-DIPLOM/vm/.vagrant/machines/backup1/virtualbox/private_key ansible_ssh_port=2211 ansible_ssh_transfer_method=scp
log1 ansible_ssh_host=127.0.0.1 ansible_ssh_user=vagrant ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_private_key_file=/home/sincere/vagrantdocs/lesson99-DIPLOM/vm/.vagrant/machines/log1/virtualbox/private_key ansible_ssh_port=2212 ansible_ssh_transfer_method=scp

```



generate PSK key


```shell

head -c 24 /dev/urandom | base64

```
ipsec.conf

```shell

#node11

config setup

        charondebug="all"

        uniqueids=yes

conn node11-star1
	type=tunnel
	auto=start
	keyexchange=ikev2
	authby=secret
	#node11
	left=77.77.1.11
	leftsubnet=192.168.11.0/24
	#star1
	right=77.77.1.1
	rightsubnet=192.168.1.0/24
	#cipher
	ike=aes256-sha1-modp1024!
	esp=aes256-sha1!
	aggressive=no
	keyingtries=%forever
	ikelifetime=28800s
	lifetime=3600s
	dpddelay=30s
	dpdtimeout=120s
	dpdaction=restart

#node12

config setup

        charondebug="all"

        uniqueids=yes

conn node12-star1
	type=tunnel
	auto=start
	keyexchange=ikev2
	authby=secret
	#node11
	left=77.77.1.12
	leftsubnet=192.168.12.0/24
	#star1
	right=77.77.1.1
	rightsubnet=192.168.1.0/24
	#cipher
	ike=aes256-sha1-modp1024!
	esp=aes256-sha1!
	aggressive=no
	keyingtries=%forever
	ikelifetime=28800s
	lifetime=3600s
	dpddelay=30s
	dpdtimeout=120s
	dpdaction=restart


#star1

config setup

        charondebug="all"
        uniqueids=yes

conn star1-node11
	type=tunnel
	auto=start
	keyexchange=ikev2
	authby=secret
	#star1	
    left=77.77.1.1
    leftsubnet=192.168.1.0/24
	#node11
	right=77.77.1.11
	rightsubnet=192.168.11.0/24
	#cipher
	ike=aes256-sha1-modp1024!
	esp=aes256-sha1!
	aggressive=no
	keyingtries=%forever
	ikelifetime=28800s
	lifetime=3600s
	dpddelay=30s
	dpdtimeout=120s
	dpdaction=restart

conn star1-node12
	type=tunnel
	auto=start
	keyexchange=ikev2
	authby=secret
	#star1	
    left=77.77.1.1
    leftsubnet=192.168.1.0/24
	#node12
	right=77.77.1.12
	rightsubnet=192.168.12.0/24
	#cipher
	ike=aes256-sha1-modp1024!
	esp=aes256-sha1!
	aggressive=no
	keyingtries=%forever
	ikelifetime=28800s
	lifetime=3600s
	dpddelay=30s
	dpdtimeout=120s
	dpdaction=restart


```

ipsec.secrets

```shell



# This file holds shared secrets or RSA private keys for authentication.

# RSA private key for this host, authenticating it to any other host
# which knows the public part.


#------- Node11-Star1 ------- 

77.77.1.11 77.77.1.1 : PSK "93lM5M0dBH5BUy30granauh8WhU41t5m="

#------- Star1-Node11 ------- 

77.77.1.1 77.77.1.11 : PSK "93lM5M0dBH5BUy30granauh8WhU41t5m="


#------- Node12-Star1 ------- 

77.77.1.12 77.77.1.1 : PSK "93lM5M0dBH5BUy30granauh8WhU41t5m="

#------- Star1-Node12 ------- 

77.77.1.1 77.77.1.12 : PSK "93lM5M0dBH5BUy30granauh8WhU41t5m="





```

routing (optional)


```
#node11
ip route add 192.168.1.0/24 via 77.77.1.11

#star1
ip route add 192.168.11.0/24 via 77.77.1.1


```

#Zabbix

ansible-galaxy collection install community.zabbix




# nftables

sudo systemctl disable ufw
sudo apt install nftables
sudo systemctl enable nftables

lsmod | grep nf

sudo nft flush ruleset

sudo nft list ruleset


# Base Rules

nft 'add table ip filter'
nft 'add chain ip filter INPUT { type filter hook input priority 0; policy accept; }'
nft 'add chain ip filter FORWARD { type filter hook forward priority 0; policy accept; }'
nft 'add chain ip filter OUTPUT { type filter hook output priority 0; policy accept; }'
nft 'add rule ip filter INPUT ct state related,established  counter accept'

# Allow SSH
#nft 'add rule ip filter INPUT ct state new tcp dport 22 counter accept comment "SSH"'
nft 'add rule ip filter INPUT iifname eth1 ip saddr 10.99.1.0/24 tcp dport 22 counter accept comment "SSH"'
nft 'add rule ip filter INPUT iifname eth2 ip saddr 192.168.0.0/16 tcp dport 22 counter accept comment "SSH"'
nft 'add rule ip filter INPUT iifname eth3 ip saddr 192.168.56.0/24 tcp dport 22 counter accept comment "SSH"'


# Allow ICMP

nft 'add rule ip filter INPUT ip protocol icmp accept'


# Allow IPSEC (esp ah)

nft 'add rule ip filter INPUT ip protocol { esp, ah } accept'

# loopback
nft 'add rule ip filter INPUT iifname "lo" counter accept'

# allow input inet to 80 zabbix

nft 'add rule ip filter INPUT ct state new  tcp dport 80 counter accept comment "HTTP"'

# allow input inet to 10050 zabbix server

nft 'add rule ip filter INPUT ct state new  tcp dport 10051 counter accept comment "zabbix"'

# port forwarding for node222 to mon222

nft 'add table nat'

nft 'add chain nat postrouting { type nat hook postrouting priority 100 ; }'

nft 'add chain nat prerouting { type nat hook prerouting priority -100; }'

nft 'add rule nat prerouting ip daddr 77.77.1.222 tcp dport { 80 } dnat 192.168.222.10:80'
nft 'add rule nat prerouting ip daddr 77.77.1.222 tcp dport { 10051 } dnat 192.168.222.10:10051'
nft 'add rule nat postrouting masquerade'
# nat 'add rule oif { 77.77.1.222 } masquerade'

sudo nft list ruleset


nft 'add chain ip filter INPUT { policy drop; }'


nft -s list ruleset > /etc/nftables.conf

# Роутинг

ip route delete default

route add default gw 192.168.222.254







ssl

curl --insecure --silent --verbose --proto-default https --output /dev/null 192.168.225.10


curl --insecure --silent --verbose --proto-default https 192.168.225.10

 curl --insecure --silent --verbose --proto-default https user:user@10.99.1.225/config/run_ipsec.pl


htpasswd

sudo apt install apache2-utils

sudo htpasswd -c .htpasswd user


borg init --encryption=repokey borg@192.168.225.40:/var/backup/{hostname}


root@dataserver:/home/vagrant# borg list borg@192.168.225.40:/var/backup/
Enter passphrase for key ssh://borg@192.168.11.160/var/backup: 
dataserver-2023-10-29_22:54:37       Sun, 2023-10-29 22:54:38 [369d642dcd80ebe7c18b12e18d3b57dab1b251de0328f0cb38c6d1fead876ad3]
dataserver-2023-10-29_23:01:53       Sun, 2023-10-29 23:01:53 [0378d814a8483ce4c26000eff7dc65556a6df34910945968d0d1dbd33c9b1773]
dataserver-2023-10-29_23:05:05       Sun, 2023-10-29 23:05:06 [1a578830959858ee18e64042a5e2671e86d2c4b922fffe694160a3cb6db912ec]

```


Ну и попробуем восстановить


```shell

rm -rf /etc/hostname


root@dataserver:/home/vagrant# mkdir ~/restore

cd ~/restore
root@dataserver:~/restore# 
root@dataserver:~/restore# pwd
/root/restore

root@dataserver:~/restore# borg extract borg@192.168.225.40:/var/backup/{hostname}::dataserver-2023-10-29_23:05:05 etc/hostname


borg info borg@192.168.225.40:/var/backup/web1::web1-2024-02-04_20:34:11

borg list borg@192.168.225.40:/var/backup/web1::web1-2024-02-04_20:34:11

borg extract -v --list /home/borg/backup/::27-11-2021 home/waqar/




