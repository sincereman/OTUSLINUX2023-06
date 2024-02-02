#!/bin/bash

nft flush ruleset

#nft list ruleset


# Base Rules

nft 'add table ip filter'
nft 'add chain ip filter INPUT { type filter hook input priority 0; policy accept; }'
nft 'add chain ip filter FORWARD { type filter hook forward priority 0; policy accept; }'
nft 'add chain ip filter OUTPUT { type filter hook output priority 0; policy accept; }'
nft 'add rule ip filter INPUT ct state related,established  counter accept'

# Allow SSH
nft 'add rule ip filter INPUT ct state new tcp dport 22 counter accept comment "SSH"'
nft 'add rule ip filter INPUT iifname eth1 ip saddr 10.99.1.0/24 tcp dport 22 counter accept comment "SSH"'
nft 'add rule ip filter INPUT iifname eth2 ip saddr 192.168.0.0/16 tcp dport 22 counter accept comment "SSH"'
#nft 'add rule ip filter INPUT iifname eth3 ip saddr 192.168.56.0/24 tcp dport 22 counter accept comment "SSH"'


# Allow ICMP

nft 'add rule ip filter INPUT ip protocol icmp accept'


# Allow IPSEC (esp ah)

nft 'add rule ip filter INPUT ip protocol { esp, ah } accept'

# loopback
nft 'add rule ip filter INPUT iifname "lo" counter accept'

#####ZABBIX######

#allow input inet to 80 haproxy

nft 'add rule ip filter INPUT ct state new  tcp dport 80 counter accept comment "HTTP"'

#allow input inet to 443 haproxy

nft 'add rule ip filter INPUT ct state new  tcp dport 443 counter accept comment "HTTPS"'



#allow input inet to 514 rsyslog1 server

nft 'add rule ip filter INPUT iifname  eth1  ip saddr 10.99.1.225 tcp dport 514 counter accept comment "rsyslog1 server"'
nft 'add rule ip filter INPUT iifname  eth2  ip saddr 192.168.225.0/24 tcp dport 514 counter accept comment "rsyslog1 server"'
#nft 'add rule ip filter INPUT iifname  eth2  ip saddr 192.168.222.10 tcp dport 10050 counter accept comment "Zabbixserver"'

#Allow zabbix

nft 'add rule ip filter INPUT iifname eth1 ip saddr { 192.168.222.10, 10.99.1.222} tcp dport 10050 counter accept comment "Zabbix"'


#Allow iperf 5201

nft 'add rule ip filter INPUT ip saddr 192.168.0.0/16  tcp dport 5201 counter accept comment "IPERF3"'

# port forwarding from node225 to haproxy

nft 'add table nat'

nft 'add chain nat postrouting { type nat hook postrouting priority 100 ; }'

nft 'add chain nat prerouting { type nat hook prerouting priority -100; }'

#nft 'add rule nat prerouting ip daddr 10.99.1.225 tcp dport { 80 } dnat 192.168.225.254:80'
#nft 'add rule nat prerouting ip daddr 10.99.1.225 tcp dport { 443 } dnat 192.168.225.254:443'
nft 'add rule nat prerouting ip daddr 10.99.1.225 tcp dport { 514 } dnat 192.168.225.50:514'


#nft 'add rule nat postrouting oif { eth1 } masquerade'

nft 'add rule nat postrouting ip daddr != { 192.168.0.0/16 } oif { eth1 } masquerade comment "output nat except ipsec net"'

sudo nft list ruleset


nft 'add chain ip filter INPUT { policy drop; }'


nft -s list ruleset > /etc/nftables.conf