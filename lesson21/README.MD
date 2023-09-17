# Домашнее задание
## Настройка мониторинга

### Цель:
научиться настраивать дашборд;


### Описание/Пошаговая инструкция выполнения домашнего задания:
Что нужно сделать?
Настроить дашборд с 4-мя графиками

память;
процессор;
диск;
сеть.
Настроить на одной из систем:
zabbix (использовать screen (комплексный экран);
prometheus - grafana.
Использование систем, примеры которых не рассматривались на занятии*
Список возможных систем был приведен в презентации.
В качестве результата прислать скриншот экрана - дашборд должен содержать в названии имя приславшего.

# Ход выполнения домашнего задания


Для выполнения ДЗ выбираю Prometheus, так как с Zabbix знаком больше.


Для развертывания и настройки лабораторного окружения будем использовать vagrant и ansible


Так как задача довольна большая, будем есть слона по частям и использовать чужой опыт.

1. Создадим каталог vm  для конфигурации Vagrantfile и сам файл


```shell

mkdir vm && cd vm

vagrant init

# Содержимое Vagrantfile - создаст сервер (для prometheus и два хоста которые будем мониторить)

# -*- mode: ruby -*-
# vim: set ft=ruby :
node_list = [
    { :host => "server", :box => "centos/8",
        :gui => false, :ip => "192.168.56.10" , :cpu => 2 ,:ram => 2028 },
    { :host => "client1-nodeexporters", :box => "centos/8",
        :gui => false, :ip => "192.168.56.11" , :cpu => 1 ,:ram => 1024 },
    { :host => "client2-nodeexporters", :box => "centos/8",
        :gui => false, :ip => "192.168.56.12" , :cpu => 1 ,:ram => 1024 },
]


Vagrant.configure("2") do |config|


    node_list.each do |node|


        config.vm.define node[:host] do |node_config|


            node_config.vm.box = node[:box]


            node_config.vm.network "private_network", ip: node[:ip], :netmask => "255.255.255.0"
            node_config.vm.hostname = "#{node[:host]}"
            node_config.vm.provider :virtualbox do |v|
                v.name = node[:host].to_s


                v.customize ["modifyvm", :id, "--memory", node[:ram].to_s]
                v.customize ["modifyvm", :id, "--cpus", node[:cpu].to_s]
            end
            node_config.vm.provision "shell", inline: <<-SHELL
            mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
            sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
            systemctl restart sshd
          SHELL
        end
    end
end


```
<details> 
<summary> Процесс создания VM</summary>

```shell
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson21/vm$ vagrant up
Bringing machine 'server' up with 'virtualbox' provider...
Bringing machine 'client1-nodeexporters' up with 'virtualbox' provider...
Bringing machine 'client2-nodeexporters' up with 'virtualbox' provider...
==> server: Importing base box 'centos/8'...
==> server: Matching MAC address for NAT networking...
==> server: Checking if box 'centos/8' version '2011.0' is up to date...
==> server: Setting the name of the VM: server
==> server: Fixed port collision for 22 => 2222. Now on port 2200.
==> server: Clearing any previously set network interfaces...
==> server: Preparing network interfaces based on configuration...
    server: Adapter 1: nat
    server: Adapter 2: hostonly
==> server: Forwarding ports...
    server: 22 (guest) => 2200 (host) (adapter 1)
==> server: Running 'pre-boot' VM customizations...
==> server: Booting VM...
==> server: Waiting for machine to boot. This may take a few minutes...
    server: SSH address: 127.0.0.1:2200
    server: SSH username: vagrant
    server: SSH auth method: private key
    server: 
    server: Vagrant insecure key detected. Vagrant will automatically replace
    server: this with a newly generated keypair for better security.
    server: 
    server: Inserting generated public key within guest...
    server: Removing insecure key from the guest if it's present...
    server: Key inserted! Disconnecting and reconnecting using new SSH key...
==> server: Machine booted and ready!
==> server: Checking for guest additions in VM...
    server: No guest additions were detected on the base box for this VM! Guest
    server: additions are required for forwarded ports, shared folders, host only
    server: networking, and more. If SSH fails on this machine, please install
    server: the guest additions and repackage the box to continue.
    server: 
    server: This is not an error message; everything may continue to work properly,
    server: in which case you may ignore this message.
==> server: Setting hostname...
==> server: Configuring and enabling network interfaces...
==> server: Rsyncing folder: /home/sincere/vagrantdocs/lesson21/vm/ => /vagrant
==> server: Running provisioner: shell...
    server: Running: inline script
==> client1-nodeexporters: Importing base box 'centos/8'...
==> client1-nodeexporters: Matching MAC address for NAT networking...
==> client1-nodeexporters: Checking if box 'centos/8' version '2011.0' is up to date...
==> client1-nodeexporters: Setting the name of the VM: client1-nodeexporters
==> client1-nodeexporters: Fixed port collision for 22 => 2222. Now on port 2201.
==> client1-nodeexporters: Clearing any previously set network interfaces...
==> client1-nodeexporters: Preparing network interfaces based on configuration...
    client1-nodeexporters: Adapter 1: nat
    client1-nodeexporters: Adapter 2: hostonly
==> client1-nodeexporters: Forwarding ports...
    client1-nodeexporters: 22 (guest) => 2201 (host) (adapter 1)
==> client1-nodeexporters: Running 'pre-boot' VM customizations...
==> client1-nodeexporters: Booting VM...
==> client1-nodeexporters: Waiting for machine to boot. This may take a few minutes...
    client1-nodeexporters: SSH address: 127.0.0.1:2201
    client1-nodeexporters: SSH username: vagrant
    client1-nodeexporters: SSH auth method: private key
    client1-nodeexporters: 
    client1-nodeexporters: Vagrant insecure key detected. Vagrant will automatically replace
    client1-nodeexporters: this with a newly generated keypair for better security.
    client1-nodeexporters: 
    client1-nodeexporters: Inserting generated public key within guest...
    client1-nodeexporters: Removing insecure key from the guest if it's present...
    client1-nodeexporters: Key inserted! Disconnecting and reconnecting using new SSH key...
==> client1-nodeexporters: Machine booted and ready!
==> client1-nodeexporters: Checking for guest additions in VM...
    client1-nodeexporters: No guest additions were detected on the base box for this VM! Guest
    client1-nodeexporters: additions are required for forwarded ports, shared folders, host only
    client1-nodeexporters: networking, and more. If SSH fails on this machine, please install
    client1-nodeexporters: the guest additions and repackage the box to continue.
    client1-nodeexporters: 
    client1-nodeexporters: This is not an error message; everything may continue to work properly,
    client1-nodeexporters: in which case you may ignore this message.
==> client1-nodeexporters: Setting hostname...
==> client1-nodeexporters: Configuring and enabling network interfaces...
==> client1-nodeexporters: Rsyncing folder: /home/sincere/vagrantdocs/lesson21/vm/ => /vagrant
==> client1-nodeexporters: Running provisioner: shell...
    client1-nodeexporters: Running: inline script
==> client2-nodeexporters: Importing base box 'centos/8'...
==> client2-nodeexporters: Matching MAC address for NAT networking...
==> client2-nodeexporters: Checking if box 'centos/8' version '2011.0' is up to date...
==> client2-nodeexporters: Setting the name of the VM: client2-nodeexporters
==> client2-nodeexporters: Fixed port collision for 22 => 2222. Now on port 2202.
==> client2-nodeexporters: Clearing any previously set network interfaces...
==> client2-nodeexporters: Preparing network interfaces based on configuration...
    client2-nodeexporters: Adapter 1: nat
    client2-nodeexporters: Adapter 2: hostonly
==> client2-nodeexporters: Forwarding ports...
    client2-nodeexporters: 22 (guest) => 2202 (host) (adapter 1)
==> client2-nodeexporters: Running 'pre-boot' VM customizations...
==> client2-nodeexporters: Booting VM...
==> client2-nodeexporters: Waiting for machine to boot. This may take a few minutes...
    client2-nodeexporters: SSH address: 127.0.0.1:2202
    client2-nodeexporters: SSH username: vagrant
    client2-nodeexporters: SSH auth method: private key
    client2-nodeexporters: 
    client2-nodeexporters: Vagrant insecure key detected. Vagrant will automatically replace
    client2-nodeexporters: this with a newly generated keypair for better security.
    client2-nodeexporters: 
    client2-nodeexporters: Inserting generated public key within guest...
    client2-nodeexporters: Removing insecure key from the guest if it's present...
    client2-nodeexporters: Key inserted! Disconnecting and reconnecting using new SSH key...
==> client2-nodeexporters: Machine booted and ready!
==> client2-nodeexporters: Checking for guest additions in VM...
    client2-nodeexporters: No guest additions were detected on the base box for this VM! Guest
    client2-nodeexporters: additions are required for forwarded ports, shared folders, host only
    client2-nodeexporters: networking, and more. If SSH fails on this machine, please install
    client2-nodeexporters: the guest additions and repackage the box to continue.
    client2-nodeexporters: 
    client2-nodeexporters: This is not an error message; everything may continue to work properly,
    client2-nodeexporters: in which case you may ignore this message.
==> client2-nodeexporters: Setting hostname...
==> client2-nodeexporters: Configuring and enabling network interfaces...
==> client2-nodeexporters: Rsyncing folder: /home/sincere/vagrantdocs/lesson21/vm/ => /vagrant
==> client2-nodeexporters: Running provisioner: shell...
    client2-nodeexporters: Running: inline script
```
</details>


Проверим доступность подключения


```shell
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson21/vm$ VBoxManage list vms
"server" {cded0580-2421-4726-83b8-348ebc19219a}
"client1-nodeexporters" {1a48638d-0ea2-4ece-84cb-0ec306c18cb6}
"client2-nodeexporters" {57dc728e-691f-4789-96ed-baf9f4d87943}

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson21/vm$ vagrant ssh server
[vagrant@server ~]$ uname -a
Linux server 4.18.0-240.1.1.el8_3.x86_64 #1 SMP Thu Nov 19 17:20:08 UTC 2020 x86_64 x86_64 x86_64 GNU/Linux
[vagrant@server ~]$ 

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson21/vm$ vagrant ssh client1-nodeexporters
[vagrant@client1-nodeexporters ~]$ uname -a
Linux client1-nodeexporters 4.18.0-240.1.1.el8_3.x86_64 #1 SMP Thu Nov 19 17:20:08 UTC 2020 x86_64 x86_64 x86_64 GNU/Linux
[vagrant@client1-nodeexporters ~]$ ping ya.ru
PING ya.ru (5.255.255.242) 56(84) bytes of data.
64 bytes from ya.ru (5.255.255.242): icmp_seq=1 ttl=63 time=95.8 ms
^C
--- ya.ru ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 95.791/95.791/95.791/0.000 ms


sincere@sincere-ubuntuotus:~/vagrantdocs/lesson21/vm$ vagrant ssh client2-nodeexporters
[vagrant@client2-nodeexporters ~]$ uname -a
Linux client2-nodeexporters 4.18.0-240.1.1.el8_3.x86_64 #1 SMP Thu Nov 19 17:20:08 UTC 2020 x86_64 x86_64 x86_64 GNU/Linux
[vagrant@client2-nodeexporters ~]$ exit
logout
Connection to 127.0.0.1 closed.



```

Все vm доступны и готовы к настройке


2. Создадим каталог ansible

```shell

mkdir ansible &&  mkdir inventories

touch hosts


# Содержимое файла hosts

[server]
server-prometheus ansible_host=192.168.56.10 ansible_port=22 ansible_user=vagrant ansible_private_key_file=../vm/.vagrant/machines/server/virtualbox/private_key

[client]
client1-nodeexporters ansible_host=192.168.56.11 ansible_private_key_file=../vm/.vagrant/machines/client1-nodeexporters/virtualbox/private_key
client2-nodeexporters ansible_host=192.168.56.12 ansible_private_key_file=../vm/.vagrant/machines/client2-nodeexporters/virtualbox/private_key

[client:vars]
ansible_user=vagrant
ansible_port=22
#ansible_ssh_private_key_file=/home/sincere/vagrantdocs/lesson21/vm/.vagrant/machines/server/virtualbox/private_key

# Cодержимое файла ansible.cfg

[defaults]
inventory = inventories/hosts
remote_user = vagrant
host_key_checking = False
retry_files_enabled = False
deprecation_warnings = False

# Проверка

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson21/ansible$ ansible-inventory --list
{
    "_meta": {
        "hostvars": {
            "client1-nodeexporters": {
                "ansible_host": "192.168.56.11",
                "ansible_port": 22,
                "ansible_private_key_file": "../vm/.vagrant/machines/client1-nodeexporters/virtualbox/private_key",
                "ansible_user": "vagrant"
            },
            "client2-nodeexporters": {
                "ansible_host": "192.168.56.12",
                "ansible_port": 22,
                "ansible_private_key_file": "../vm/.vagrant/machines/client2-nodeexporters/virtualbox/private_key",
                "ansible_user": "vagrant"
            },
            "server-prometheus": {
                "ansible_host": "192.168.56.10",
                "ansible_port": 22,
                "ansible_private_key_file": "../vm/.vagrant/machines/server-prometheus/virtualbox/private_key",
                "ansible_user": "vagrant"
            }
        }
    },
    "all": {
        "children": [
            "client",
            "server",
            "ungrouped"
        ]
    },
    "client": {
        "hosts": [
            "client1-nodeexporters",
            "client2-nodeexporters"
        ]
    },
    "server": {
        "hosts": [
            "server-prometheus"
        ]
    }
}

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson21/ansible$ ansible all -m ping
client1-nodeexporters | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/libexec/platform-python"
    },
    "changed": false,
    "ping": "pong"
}
client2-nodeexporters | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/libexec/platform-python"
    },
    "changed": false,
    "ping": "pong"
}
server-prometheus | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/libexec/platform-python"
    },
    "changed": false,
    "ping": "pong"
}



```

Наши машинки готовы к настройке.


Подготовим playbook

Покажу только структуру и как пользоваться

в коренвом каталоге лежит файл main.sh - как ключ к полноценной настройке и провижнингу

Сознательно разделил vagrant и запуск провижнинга, так как в таком объеме собирал первый раз и требовалось много времени для отладки


<details><summary>Ход выполнения скрипта</summary>


```shell
prometheus-2.47.0.linux-amd64/
prometheus-2.47.0.linux-amd64/console_libraries/
prometheus-2.47.0.linux-amd64/console_libraries/menu.lib
prometheus-2.47.0.linux-amd64/console_libraries/prom.lib
prometheus-2.47.0.linux-amd64/prometheus.yml
prometheus-2.47.0.linux-amd64/promtool
prometheus-2.47.0.linux-amd64/LICENSE
prometheus-2.47.0.linux-amd64/prometheus
prometheus-2.47.0.linux-amd64/NOTICE
prometheus-2.47.0.linux-amd64/consoles/
prometheus-2.47.0.linux-amd64/consoles/prometheus-overview.html
prometheus-2.47.0.linux-amd64/consoles/node.html
prometheus-2.47.0.linux-amd64/consoles/node-cpu.html
prometheus-2.47.0.linux-amd64/consoles/index.html.example
prometheus-2.47.0.linux-amd64/consoles/prometheus.html
prometheus-2.47.0.linux-amd64/consoles/node-overview.html
prometheus-2.47.0.linux-amd64/consoles/node-disk.html
node_exporter-1.6.1.linux-amd64/
node_exporter-1.6.1.linux-amd64/NOTICE
node_exporter-1.6.1.linux-amd64/node_exporter
node_exporter-1.6.1.linux-amd64/LICENSE
Bringing machine 'server-prometheus' up with 'virtualbox' provider...
Bringing machine 'client1-nodeexporters' up with 'virtualbox' provider...
Bringing machine 'client2-nodeexporters' up with 'virtualbox' provider...
==> server-prometheus: Importing base box 'centos/8'...

[KProgress: 20%
[KProgress: 40%
[KProgress: 50%
[KProgress: 70%
[KProgress: 90%
[K==> server-prometheus: Matching MAC address for NAT networking...
==> server-prometheus: Checking if box 'centos/8' version '2011.0' is up to date...
==> server-prometheus: Setting the name of the VM: server-prometheus
==> server-prometheus: Clearing any previously set network interfaces...
==> server-prometheus: Preparing network interfaces based on configuration...
    server-prometheus: Adapter 1: nat
    server-prometheus: Adapter 2: hostonly
==> server-prometheus: Forwarding ports...
    server-prometheus: 22 (guest) => 2222 (host) (adapter 1)
==> server-prometheus: Running 'pre-boot' VM customizations...
==> server-prometheus: Booting VM...
==> server-prometheus: Waiting for machine to boot. This may take a few minutes...
    server-prometheus: SSH address: 127.0.0.1:2222
    server-prometheus: SSH username: vagrant
    server-prometheus: SSH auth method: private key
    server-prometheus: 
    server-prometheus: Vagrant insecure key detected. Vagrant will automatically replace
    server-prometheus: this with a newly generated keypair for better security.
    server-prometheus: 
    server-prometheus: Inserting generated public key within guest...
    server-prometheus: Removing insecure key from the guest if it's present...
    server-prometheus: Key inserted! Disconnecting and reconnecting using new SSH key...
==> server-prometheus: Machine booted and ready!
==> server-prometheus: Checking for guest additions in VM...
    server-prometheus: No guest additions were detected on the base box for this VM! Guest
    server-prometheus: additions are required for forwarded ports, shared folders, host only
    server-prometheus: networking, and more. If SSH fails on this machine, please install
    server-prometheus: the guest additions and repackage the box to continue.
    server-prometheus: 
    server-prometheus: This is not an error message; everything may continue to work properly,
    server-prometheus: in which case you may ignore this message.
==> server-prometheus: Setting hostname...
==> server-prometheus: Configuring and enabling network interfaces...
==> server-prometheus: Rsyncing folder: /home/sincere/vagrantdocs/lesson21/vm/ => /vagrant
==> server-prometheus: Running provisioner: shell...
    server-prometheus: Running: inline script
==> client1-nodeexporters: Importing base box 'centos/8'...

[KProgress: 20%
[KProgress: 40%
[KProgress: 50%
[KProgress: 70%
[KProgress: 90%
[K==> client1-nodeexporters: Matching MAC address for NAT networking...
==> client1-nodeexporters: Checking if box 'centos/8' version '2011.0' is up to date...
==> client1-nodeexporters: Setting the name of the VM: client1-nodeexporters
==> client1-nodeexporters: Fixed port collision for 22 => 2222. Now on port 2200.
==> client1-nodeexporters: Clearing any previously set network interfaces...
==> client1-nodeexporters: Preparing network interfaces based on configuration...
    client1-nodeexporters: Adapter 1: nat
    client1-nodeexporters: Adapter 2: hostonly
==> client1-nodeexporters: Forwarding ports...
    client1-nodeexporters: 22 (guest) => 2200 (host) (adapter 1)
==> client1-nodeexporters: Running 'pre-boot' VM customizations...
==> client1-nodeexporters: Booting VM...
==> client1-nodeexporters: Waiting for machine to boot. This may take a few minutes...
    client1-nodeexporters: SSH address: 127.0.0.1:2200
    client1-nodeexporters: SSH username: vagrant
    client1-nodeexporters: SSH auth method: private key
    client1-nodeexporters: 
    client1-nodeexporters: Vagrant insecure key detected. Vagrant will automatically replace
    client1-nodeexporters: this with a newly generated keypair for better security.
    client1-nodeexporters: 
    client1-nodeexporters: Inserting generated public key within guest...
    client1-nodeexporters: Removing insecure key from the guest if it's present...
    client1-nodeexporters: Key inserted! Disconnecting and reconnecting using new SSH key...
==> client1-nodeexporters: Machine booted and ready!
==> client1-nodeexporters: Checking for guest additions in VM...
    client1-nodeexporters: No guest additions were detected on the base box for this VM! Guest
    client1-nodeexporters: additions are required for forwarded ports, shared folders, host only
    client1-nodeexporters: networking, and more. If SSH fails on this machine, please install
    client1-nodeexporters: the guest additions and repackage the box to continue.
    client1-nodeexporters: 
    client1-nodeexporters: This is not an error message; everything may continue to work properly,
    client1-nodeexporters: in which case you may ignore this message.
==> client1-nodeexporters: Setting hostname...
==> client1-nodeexporters: Configuring and enabling network interfaces...
==> client1-nodeexporters: Rsyncing folder: /home/sincere/vagrantdocs/lesson21/vm/ => /vagrant
==> client1-nodeexporters: Running provisioner: shell...
    client1-nodeexporters: Running: inline script
==> client2-nodeexporters: Importing base box 'centos/8'...

[KProgress: 20%
[KProgress: 40%
[KProgress: 50%
[KProgress: 70%
[KProgress: 90%
[K==> client2-nodeexporters: Matching MAC address for NAT networking...
==> client2-nodeexporters: Checking if box 'centos/8' version '2011.0' is up to date...
==> client2-nodeexporters: Setting the name of the VM: client2-nodeexporters
==> client2-nodeexporters: Fixed port collision for 22 => 2222. Now on port 2201.
==> client2-nodeexporters: Clearing any previously set network interfaces...
==> client2-nodeexporters: Preparing network interfaces based on configuration...
    client2-nodeexporters: Adapter 1: nat
    client2-nodeexporters: Adapter 2: hostonly
==> client2-nodeexporters: Forwarding ports...
    client2-nodeexporters: 22 (guest) => 2201 (host) (adapter 1)
==> client2-nodeexporters: Running 'pre-boot' VM customizations...
==> client2-nodeexporters: Booting VM...
==> client2-nodeexporters: Waiting for machine to boot. This may take a few minutes...
    client2-nodeexporters: SSH address: 127.0.0.1:2201
    client2-nodeexporters: SSH username: vagrant
    client2-nodeexporters: SSH auth method: private key
    client2-nodeexporters: 
    client2-nodeexporters: Vagrant insecure key detected. Vagrant will automatically replace
    client2-nodeexporters: this with a newly generated keypair for better security.
    client2-nodeexporters: 
    client2-nodeexporters: Inserting generated public key within guest...
    client2-nodeexporters: Removing insecure key from the guest if it's present...
    client2-nodeexporters: Key inserted! Disconnecting and reconnecting using new SSH key...
==> client2-nodeexporters: Machine booted and ready!
==> client2-nodeexporters: Checking for guest additions in VM...
    client2-nodeexporters: No guest additions were detected on the base box for this VM! Guest
    client2-nodeexporters: additions are required for forwarded ports, shared folders, host only
    client2-nodeexporters: networking, and more. If SSH fails on this machine, please install
    client2-nodeexporters: the guest additions and repackage the box to continue.
    client2-nodeexporters: 
    client2-nodeexporters: This is not an error message; everything may continue to work properly,
    client2-nodeexporters: in which case you may ignore this message.
==> client2-nodeexporters: Setting hostname...
==> client2-nodeexporters: Configuring and enabling network interfaces...
==> client2-nodeexporters: Rsyncing folder: /home/sincere/vagrantdocs/lesson21/vm/ => /vagrant
==> client2-nodeexporters: Running provisioner: shell...
    client2-nodeexporters: Running: inline script

PLAY [Playbook of server (prometheus) initialization] ***************************************************************************************************************************

TASK [Gathering Facts] **********************************************************************************************************************************************************
ok: [server-prometheus]

TASK [../roles/server : Set time zone] ******************************************************************************************************************************************
changed: [server-prometheus]

TASK [../roles/server : Update Repo url] ****************************************************************************************************************************************
changed: [server-prometheus] => (item=sudo sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo)
changed: [server-prometheus] => (item=sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo)

TASK [../roles/server : Synchronize datetime | Install chrony] ******************************************************************************************************************
changed: [server-prometheus]

TASK [../roles/server : Synchronize datetime | Turn on chronyd] *****************************************************************************************************************
ok: [server-prometheus]

TASK [../roles/server : Create prometheus user] *********************************************************************************************************************************
changed: [server-prometheus]

TASK [../roles/server : Create new folders, set specific permission] ************************************************************************************************************
changed: [server-prometheus]

TASK [../roles/server : Copy ./prometheus to /usr/local/bin] ********************************************************************************************************************
changed: [server-prometheus]

TASK [../roles/server : Copy ./promtool to /usr/local/bin] **********************************************************************************************************************
changed: [server-prometheus]

TASK [../roles/server : Configure prometeus application | prometheus.yml] *******************************************************************************************************
changed: [server-prometheus]

TASK [../roles/server : Configure prometeus application | consoles] *************************************************************************************************************
changed: [server-prometheus]

TASK [../roles/server : Configure prometeus application | console libraries] ****************************************************************************************************
changed: [server-prometheus]

TASK [../roles/server : Configure prometeus application | consoles] *************************************************************************************************************
changed: [server-prometheus]

TASK [../roles/server : Configure prometeus service] ****************************************************************************************************************************
changed: [server-prometheus]

TASK [../roles/server : Turn on prometeus service] ******************************************************************************************************************************
changed: [server-prometheus]

TASK [../roles/server : Check http] *********************************************************************************************************************************************
ok: [server-prometheus]

TASK [../roles/server : Check http] *********************************************************************************************************************************************
skipping: [server-prometheus]

TASK [../roles/server : Create repo Grafana] ************************************************************************************************************************************
changed: [server-prometheus]

TASK [../roles/server : Install Grafana] ****************************************************************************************************************************************

PLAY [Playbook of client (node exporter) initialization] ************************************************************************************************************************

TASK [Gathering Facts] **********************************************************************************************************************************************************
ok: [client1-nodeexporters]
ok: [client2-nodeexporters]

TASK [../roles/client : Set time zone] ******************************************************************************************************************************************
changed: [client1-nodeexporters]
changed: [client2-nodeexporters]

TASK [../roles/client : Update Repo url from updatereposcript.sh] ***************************************************************************************************************
changed: [client1-nodeexporters]
changed: [client2-nodeexporters]

TASK [../roles/client : Synchronize datetime | Install chrony] ******************************************************************************************************************
changed: [client2-nodeexporters]
changed: [client1-nodeexporters]

TASK [../roles/client : Synchronize datetime | Turn on chronyd] *****************************************************************************************************************
ok: [client1-nodeexporters]
ok: [client2-nodeexporters]

TASK [../roles/client : Create node exporter user] ******************************************************************************************************************************
changed: [client1-nodeexporters]
changed: [client2-nodeexporters]

TASK [../roles/client : Create work paths] **************************************************************************************************************************************
changed: [client1-nodeexporters]
changed: [client2-nodeexporters]

TASK [../roles/client : Copy ./node_exporter to /usr/local/bin] *****************************************************************************************************************
changed: [client1-nodeexporters]
changed: [client2-nodeexporters]

TASK [../roles/client : Configure node exporter service] ************************************************************************************************************************
changed: [client1-nodeexporters]
changed: [client2-nodeexporters]

TASK [../roles/client : Turn on node_exporter service] **************************************************************************************************************************
changed: [client2-nodeexporters]
changed: [client1-nodeexporters]

TASK [../roles/client : Check data on client] ***********************************************************************************************************************************
ok: [client1-nodeexporters]
ok: [client2-nodeexporters]

TASK [../roles/client : Check data on client] ***********************************************************************************************************************************
skipping: [client1-nodeexporters]
skipping: [client2-nodeexporters]

TASK [../roles/client : Show data on client] ************************************************************************************************************************************
ok: [client1-nodeexporters] => {
    "msg": {
        "changed": false,
        "connection": "close",
        "content_length": "961",
        "content_type": "text/html; charset=UTF-8",
        "cookies": {},
        "cookies_string": "",
        "date": "Sun, 17 Sep 2023 15:19:11 GMT",
        "elapsed": 0,
        "failed": false,
        "msg": "OK (961 bytes)",
        "redirected": false,
        "status": 200,
        "url": "http://localhost:9100"
    }
}
ok: [client2-nodeexporters] => {
    "msg": {
        "changed": false,
        "connection": "close",
        "content_length": "961",
        "content_type": "text/html; charset=UTF-8",
        "cookies": {},
        "cookies_string": "",
        "date": "Sun, 17 Sep 2023 15:19:11 GMT",
        "elapsed": 0,
        "failed": false,
        "msg": "OK (961 bytes)",
        "redirected": false,
        "status": 200,
        "url": "http://localhost:9100"
    }
}

RUNNING HANDLER [../roles/client : systemctl daemon reload] *********************************************************************************************************************
ok: [client2-nodeexporters]
ok: [client1-nodeexporters]

PLAY RECAP **********************************************************************************************************************************************************************
client1-nodeexporters      : ok=13   changed=8    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
client2-nodeexporters      : ok=13   changed=8    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   


PLAY [Playbook of server configure after clent initialization] ******************************************************************************************************************

TASK [Gathering Facts] **********************************************************************************************************************************************************
ok: [server-prometheus]

TASK [../roles/updateserversnode : Register content] ****************************************************************************************************************************
changed: [server-prometheus]

TASK [../roles/updateserversnode : Update prometheus.yml] ***********************************************************************************************************************
changed: [server-prometheus]

TASK [../roles/updateserversnode : Update prometheus.yml] ***********************************************************************************************************************
changed: [server-prometheus]

RUNNING HANDLER [../roles/updateserversnode : service restart prometheus] *******************************************************************************************************
changed: [server-prometheus]

PLAY RECAP **********************************************************************************************************************************************************************
server-prometheus          : ok=5    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

```

</details>


В результате получаем настроенный стенд с сервером Prometheus/Grafana, двумя нодами экспортерами для мониторинга


```shell

sincere@sincere-ubuntuotus:~/vagrantdocs$ tree lesson21
lesson21
├── ansible
│   ├── ansible.cfg
│   ├── inventories
│   │   └── hosts
│   ├── playbooks
│   │   ├── client.yml
│   │   ├── server.yml
│   │   └── updateserversnode.yml
│   └── roles
│       ├── client
│       │   ├── files
│       │   │   └── etc
│       │   │       ├── systemd
│       │   │       │   └── system
│       │   │       │       └── node_exporter.service
│       │   │       └── updatereposcript.sh
│       │   ├── handlers
│       │   │   └── main.yml
│       │   └── tasks
│       │       └── main.yml
│       ├── server
│       │   ├── files
│       │   │   ├── dashboard
│       │   │   │   └── overview.html
│       │   │   └── etc
│       │   │       ├── createpromfoldersandperm.sh
│       │   │       ├── grafana
│       │   │       │   └── grafana.repo
│       │   │       ├── prometheus
│       │   │       │   └── prometheus.yml
│       │   │       ├── systemd
│       │   │       │   └── system
│       │   │       │       └── prometheus.service
│       │   │       └── updatereposcript.sh
│       │   ├── handlers
│       │   │   └── main.yml
│       │   └── tasks
│       │       └── main.yml
│       └── updateserversnode
│           ├── handlers
│           │   └── main.yml
│           └── tasks
│               └── main.yml
├── img
│   ├── screencast.gif
│   └── screenshot.png
├── main.sh
├── promgrafanaexport.log
├── README.MD
└── vm
    └── Vagrantfile


```

Screenshot Prometheus with target

![Alt text](img/Prometheus_target.png)
В графане сделать Dashboards -> Manage -> Import и введите идентификатор доски 15172 - источник данных Prometheus

Screenshot Grafana with nodeexporters

![Alt text](<img/Sincere - Grafana.png>)





