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
nft 'add rule ip filter INPUT iifname eth1 ip saddr 192.168.0.0/16 tcp dport 22 counter accept comment "SSH"'
nft 'add rule ip filter INPUT iifname eth2 ip saddr 192.168.56.0/16 tcp dport 22 counter accept comment "SSH"'
#nft 'add rule ip filter INPUT iifname eth3 ip saddr 192.168.56.0/24 tcp dport 22 counter accept comment "SSH"'


# Allow ICMP

nft 'add rule ip filter INPUT ip protocol icmp accept'


# Allow IPSEC (esp ah)

nft 'add rule ip filter INPUT ip protocol { esp, ah } accept'

# loopback
nft 'add rule ip filter INPUT iifname "lo" counter accept'

#allow input inet to 80 zabbix

nft 'add rule ip filter INPUT ct state new  tcp dport 80 counter accept comment "HTTP"'


#allow input inet to 443 zabbix

nft 'add rule ip filter INPUT ct state new  tcp dport 443 counter accept comment "HTTPS"'

# allow input inet to 10051 zabbix server

nft 'add rule ip filter INPUT ct state new  tcp dport 10051 counter accept comment "zabbix"'



sudo nft list ruleset


nft 'add chain ip filter INPUT { policy drop; }'


nft -s list ruleset > /etc/nftables.conf