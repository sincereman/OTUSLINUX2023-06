# Проект

## Дипломный проект

### Тема: Организация сетевой связности сети IPSEC (GRE over IPSEC) - на транспортном уровне через центральный узел.

Требования:
1. Централизованная конфигурация новых и существующих узлов.
2. Смена центрального узла по параметру в конфигурации (web-часть взаимодействие с оператором) (* при недоступности узла с системы мониторинга сети менять центральный узел из предопределенного списка)
3. Базовая ОС Debian 12 - но стараться сделать ОС независимую конфигурацию
4. Конфигурация фаервола в вебчасти (из какой сети в какую разрешено ходить)
5. Web - часть не является одним из узлов рассматриваемой сети - желательно географически разнесенная и бд (мастер-slave)
6. Сбор логов с хостов rsyslogd
7. Backup - выберу позже.
8. В качестве системы мониторинга Zabbix.


### Выполнение.


1. Необходимо подготовить шаблон базовой виртуальной машины на основе Debian 12

Воспользуемся готовым образом с vagrant cloud


Vagrantfile


```shell

# -*- mode: ruby -*-
# vi: set ft=ruby :

MACHINES = {
  :star1 => {
        :box_name => "generic/debian12",
        :vm_name => "star1",
        :net => [
                   [ "77.77.1.1", 2, "255.255.255.0", "WAN1"],
                   [ "192.168.1.254", 3, "255.255.255.0", "LAN1"], 
                   [ "192.168.56.1", 5],
                ]
  },

  :star2 => {
        :box_name => "generic/debian12",
        :vm_name => "star2",
        :net => [
                   [ "77.77.1.2", 2, "255.255.255.0", "WAN1"],
                   [ "192.168.2.254", 3, "255.255.255.0", "LAN2"], 
                   [ "192.168.56.2", 5],
                ]
  },

  :node11 => {
        :box_name => "generic/debian12",
        :vm_name => "node11",
        :net => [
                   [ "77.77.1.11", 2, "255.255.255.0", "WAN1"],
                   [ "192.168.11.254", 3, "255.255.255.0", "LAN11"], 
                   [ "192.168.56.11", 5],
                ]
  },

  :node12 => {
        :box_name => "generic/debian12",
        :vm_name => "node12",
        :net => [
                   [ "77.77.1.12", 2, "255.255.255.0", "WAN1"],
                   [ "192.168.12.254", 3, "255.255.255.0", "LAN12"], 
                   [ "192.168.56.12", 5],
                ]
  },

  :node13 => {
        :box_name => "generic/debian12",
        :vm_name => "node13",
        :net => [
                   [ "77.77.1.13", 2, "255.255.255.0", "WAN1"],
                   [ "192.168.13.254", 3, "255.255.255.0", "LAN13"], 
                   [ "192.168.56.13", 5],
                ]
  },

  :node222 => {
        :box_name => "generic/debian12",
        :vm_name => "node222",
        :net => [
                   [ "77.77.1.222", 2, "255.255.255.0", "WAN1"],
                   [ "192.168.222.254", 3, "255.255.255.0", "LAN222"], 
                   [ "192.168.56.222", 5],
                ]
  },

  :mon222 => {
    :box_name => "generic/debian12",
    :vm_name => "mon223",
    :net => [
               [ "192.168.222.10", 2, "255.255.255.0", "LAN222"],
               [ "192.168.56.223", 5],
            ]
},

  :node225 => {
        :box_name => "generic/debian12",
        :vm_name => "node225",
        :net => [
                   [ "77.77.1.225", 2, "255.255.255.0", "WAN1"],
                   [ "192.168.225.254", 3, "255.255.255.0", "LAN225"], 
                   [ "192.168.56.225", 5],
                ]
  },

  :web1 => {
    :box_name => "generic/debian12",
    :vm_name => "web1",
    :net => [
               [ "192.168.225.10", 2, "255.255.255.0", "LAN225"],
               [ "192.168.56.226", 5],
            ]
  },

  :web2 => {
    :box_name => "generic/debian12",
    :vm_name => "web2",
    :net => [
               [ "192.168.225.11", 2, "255.255.255.0", "LAN225"],
               [ "192.168.56.227", 5],
            ]
  },

  :database1 => {
    :box_name => "generic/debian12",
    :vm_name => "database1",
    :net => [
               [ "192.168.225.20", 2, "255.255.255.0", "LAN225"],
               [ "192.168.56.228", 5],
            ]
  },

  :database2 => {
    :box_name => "generic/debian12",
    :vm_name => "database2",
    :net => [
               [ "192.168.225.21", 2, "255.255.255.0", "LAN225"],
               [ "192.168.56.229", 5],
            ]
  },

  :backup1 => {
    :box_name => "generic/debian12",
    :vm_name => "backup1",
    :net => [
               [ "192.168.225.40", 2, "255.255.255.0", "LAN225"],
               [ "192.168.56.230", 5],
            ]
  },

  :log1 => {
    :box_name => "generic/debian12",
    :vm_name => "log1",
    :net => [
               [ "192.168.225.50", 2, "255.255.255.0", "LAN225"],
               [ "192.168.56.231", 5],
            ]
  },


}


Vagrant.configure("2") do |config|

  MACHINES.each do |boxname, boxconfig|

    config.vm.define boxname do |box|
   
      box.vm.box = boxconfig[:box_name]
      box.vm.host_name = boxconfig[:vm_name]
      
      box.vm.provider "virtualbox" do |v|
        v.memory = 1024
        v.cpus = 1
       end


      boxconfig[:net].each do |ipconf|
        box.vm.network("private_network", ip: ipconf[0], adapter: ipconf[1], netmask: ipconf[2], virtualbox__intnet: ipconf[3])
      end


      box.vm.provision "shell", inline: <<-SHELL
        mkdir -p ~root/.ssh
        cp ~vagrant/.ssh/auth* ~root/.ssh
      SHELL

    end
  end
end


```

Поднимем машинки



```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson99-DIPLOM/vm$ vagrant up
==> vagrant: A new version of Vagrant is available: 2.4.1 (installed version: 2.4.0)!
==> vagrant: To upgrade visit: https://www.vagrantup.com/downloads.html

Bringing machine 'star1' up with 'virtualbox' provider...
Bringing machine 'star2' up with 'virtualbox' provider...
Bringing machine 'node11' up with 'virtualbox' provider...
Bringing machine 'node12' up with 'virtualbox' provider...
Bringing machine 'node13' up with 'virtualbox' provider...
Bringing machine 'node222' up with 'virtualbox' provider...
Bringing machine 'mon222' up with 'virtualbox' provider...
Bringing machine 'node225' up with 'virtualbox' provider...
Bringing machine 'web1' up with 'virtualbox' provider...
Bringing machine 'web2' up with 'virtualbox' provider...
Bringing machine 'database1' up with 'virtualbox' provider...
Bringing machine 'database2' up with 'virtualbox' provider...
Bringing machine 'backup1' up with 'virtualbox' provider...
Bringing machine 'log1' up with 'virtualbox' provider...
==> star1: Box 'generic/debian12' could not be found. Attempting to find and install...
    star1: Box Provider: virtualbox
    star1: Box Version: >= 0
==> star1: Loading metadata for box 'generic/debian12'
    star1: URL: https://vagrantcloud.com/api/v2/vagrant/generic/debian12
==> star1: Adding box 'generic/debian12' (v4.3.12) for provider: virtualbox (amd64)
    star1: Downloading: https://vagrantcloud.com/generic/boxes/debian12/versions/4.3.12/providers/virtualbox/amd64/vagrant.box
    star1: Calculating and comparing box checksum...
==> star1: Successfully added box 'generic/debian12' (v4.3.12) for 'virtualbox (amd64)'!
==> star1: You assigned a static IP ending in ".1" to this machine.
==> star1: This is very often used by the router and can cause the
==> star1: network to not work properly. If the network doesn't work
==> star1: properly, try changing this IP.
==> star1: You assigned a static IP ending in ".1" to this machine.
==> star1: This is very often used by the router and can cause the
==> star1: network to not work properly. If the network doesn't work
==> star1: properly, try changing this IP.
==> star1: Importing base box 'generic/debian12'...
==> star1: Matching MAC address for NAT networking...
==> star1: You assigned a static IP ending in ".1" to this machine.
==> star1: This is very often used by the router and can cause the
==> star1: network to not work properly. If the network doesn't work
==> star1: properly, try changing this IP.
==> star1: You assigned a static IP ending in ".1" to this machine.
==> star1: This is very often used by the router and can cause the
==> star1: network to not work properly. If the network doesn't work
==> star1: properly, try changing this IP.
==> star1: Checking if box 'generic/debian12' version '4.3.12' is up to date...
==> star1: Setting the name of the VM: vm_star1_1705932050262_73742
==> star1: Clearing any previously set network interfaces...
==> star1: Preparing network interfaces based on configuration...
    star1: Adapter 1: nat
    star1: Adapter 2: intnet
    star1: Adapter 3: intnet
    star1: Adapter 5: hostonly
==> star1: Forwarding ports...
    star1: 22 (guest) => 2222 (host) (adapter 1)
==> star1: Running 'pre-boot' VM customizations...
==> star1: Booting VM...
==> star1: Waiting for machine to boot. This may take a few minutes...
    star1: SSH address: 127.0.0.1:2222
    star1: SSH username: vagrant
    star1: SSH auth method: private key
    star1: Warning: Connection reset. Retrying...
    star1: Warning: Remote connection disconnect. Retrying...
    star1: 
    star1: Vagrant insecure key detected. Vagrant will automatically replace
    star1: this with a newly generated keypair for better security.
    star1: 
    star1: Inserting generated public key within guest...
    star1: Removing insecure key from the guest if it's present...
    star1: Key inserted! Disconnecting and reconnecting using new SSH key...
==> star1: Machine booted and ready!
==> star1: Checking for guest additions in VM...
    star1: The guest additions on this VM do not match the installed version of
    star1: VirtualBox! In most cases this is fine, but in rare cases it can
    star1: prevent things such as shared folders from working properly. If you see
    star1: shared folder errors, please make sure the guest additions within the
    star1: virtual machine match the version of VirtualBox you have installed on
    star1: your host and reload your VM.
    star1: 
    star1: Guest Additions Version: 7.0.12
    star1: VirtualBox Version: 6.1
==> star1: Setting hostname...
==> star1: Configuring and enabling network interfaces...
==> star1: Running provisioner: shell...
    star1: Running: inline script
==> star2: Box 'generic/debian12' could not be found. Attempting to find and install...
    star2: Box Provider: virtualbox
    star2: Box Version: >= 0
==> star2: Loading metadata for box 'generic/debian12'
    star2: URL: https://vagrantcloud.com/api/v2/vagrant/generic/debian12
==> star2: Adding box 'generic/debian12' (v4.3.12) for provider: virtualbox (amd64)
==> star2: Importing base box 'generic/debian12'...
==> star2: Matching MAC address for NAT networking...
==> star2: Checking if box 'generic/debian12' version '4.3.12' is up to date...
==> star2: Setting the name of the VM: vm_star2_1705932128836_51435
==> star2: Fixed port collision for 22 => 2222. Now on port 2200.
==> star2: Clearing any previously set network interfaces...
==> star2: Preparing network interfaces based on configuration...
    star2: Adapter 1: nat
    star2: Adapter 2: intnet
    star2: Adapter 3: intnet
    star2: Adapter 5: hostonly
==> star2: Forwarding ports...
    star2: 22 (guest) => 2200 (host) (adapter 1)
==> star2: Running 'pre-boot' VM customizations...
==> star2: Booting VM...
==> star2: Waiting for machine to boot. This may take a few minutes...
    star2: SSH address: 127.0.0.1:2200
    star2: SSH username: vagrant
    star2: SSH auth method: private key
    star2: Warning: Connection reset. Retrying...
    star2: Warning: Remote connection disconnect. Retrying...
    star2: 
    star2: Vagrant insecure key detected. Vagrant will automatically replace
    star2: this with a newly generated keypair for better security.
    star2: 
    star2: Inserting generated public key within guest...
    star2: Removing insecure key from the guest if it's present...
    star2: Key inserted! Disconnecting and reconnecting using new SSH key...
==> star2: Machine booted and ready!
==> star2: Checking for guest additions in VM...
    star2: The guest additions on this VM do not match the installed version of
    star2: VirtualBox! In most cases this is fine, but in rare cases it can
    star2: prevent things such as shared folders from working properly. If you see
    star2: shared folder errors, please make sure the guest additions within the
    star2: virtual machine match the version of VirtualBox you have installed on
    star2: your host and reload your VM.
    star2: 
    star2: Guest Additions Version: 7.0.12
    star2: VirtualBox Version: 6.1
==> star2: Setting hostname...
==> star2: Configuring and enabling network interfaces...
==> star2: Running provisioner: shell...
    star2: Running: inline script
==> node11: Box 'generic/debian12' could not be found. Attempting to find and install...
    node11: Box Provider: virtualbox
    node11: Box Version: >= 0
==> node11: Loading metadata for box 'generic/debian12'
    node11: URL: https://vagrantcloud.com/api/v2/vagrant/generic/debian12
==> node11: Adding box 'generic/debian12' (v4.3.12) for provider: virtualbox (amd64)
==> node11: Importing base box 'generic/debian12'...
==> node11: Matching MAC address for NAT networking...
==> node11: Checking if box 'generic/debian12' version '4.3.12' is up to date...
==> node11: Setting the name of the VM: vm_node11_1705932215397_67706
==> node11: Fixed port collision for 22 => 2222. Now on port 2201.
==> node11: Clearing any previously set network interfaces...
==> node11: Preparing network interfaces based on configuration...
    node11: Adapter 1: nat
    node11: Adapter 2: intnet
    node11: Adapter 3: intnet
    node11: Adapter 5: hostonly
==> node11: Forwarding ports...
    node11: 22 (guest) => 2201 (host) (adapter 1)
==> node11: Running 'pre-boot' VM customizations...
==> node11: Booting VM...
==> node11: Waiting for machine to boot. This may take a few minutes...
    node11: SSH address: 127.0.0.1:2201
    node11: SSH username: vagrant
    node11: SSH auth method: private key
    node11: Warning: Connection reset. Retrying...
    node11: Warning: Remote connection disconnect. Retrying...
    node11: 
    node11: Vagrant insecure key detected. Vagrant will automatically replace
    node11: this with a newly generated keypair for better security.
    node11: 
    node11: Inserting generated public key within guest...
    node11: Removing insecure key from the guest if it's present...
    node11: Key inserted! Disconnecting and reconnecting using new SSH key...
==> node11: Machine booted and ready!
==> node11: Checking for guest additions in VM...
    node11: The guest additions on this VM do not match the installed version of
    node11: VirtualBox! In most cases this is fine, but in rare cases it can
    node11: prevent things such as shared folders from working properly. If you see
    node11: shared folder errors, please make sure the guest additions within the
    node11: virtual machine match the version of VirtualBox you have installed on
    node11: your host and reload your VM.
    node11: 
    node11: Guest Additions Version: 7.0.12
    node11: VirtualBox Version: 6.1
==> node11: Setting hostname...
==> node11: Configuring and enabling network interfaces...
==> node11: Running provisioner: shell...
    node11: Running: inline script
==> node12: Box 'generic/debian12' could not be found. Attempting to find and install...
    node12: Box Provider: virtualbox
    node12: Box Version: >= 0
==> node12: Loading metadata for box 'generic/debian12'
    node12: URL: https://vagrantcloud.com/api/v2/vagrant/generic/debian12
==> node12: Adding box 'generic/debian12' (v4.3.12) for provider: virtualbox (amd64)
==> node12: Importing base box 'generic/debian12'...
==> node12: Matching MAC address for NAT networking...
==> node12: Checking if box 'generic/debian12' version '4.3.12' is up to date...
==> node12: Setting the name of the VM: vm_node12_1705932298850_7938
==> node12: Fixed port collision for 22 => 2222. Now on port 2202.
==> node12: Clearing any previously set network interfaces...
==> node12: Preparing network interfaces based on configuration...
    node12: Adapter 1: nat
    node12: Adapter 2: intnet
    node12: Adapter 3: intnet
    node12: Adapter 5: hostonly
==> node12: Forwarding ports...
    node12: 22 (guest) => 2202 (host) (adapter 1)
==> node12: Running 'pre-boot' VM customizations...
==> node12: Booting VM...
==> node12: Waiting for machine to boot. This may take a few minutes...
    node12: SSH address: 127.0.0.1:2202
    node12: SSH username: vagrant
    node12: SSH auth method: private key
    node12: Warning: Connection reset. Retrying...
    node12: 
    node12: Vagrant insecure key detected. Vagrant will automatically replace
    node12: this with a newly generated keypair for better security.
    node12: 
    node12: Inserting generated public key within guest...
    node12: Removing insecure key from the guest if it's present...
    node12: Key inserted! Disconnecting and reconnecting using new SSH key...
==> node12: Machine booted and ready!
==> node12: Checking for guest additions in VM...
    node12: The guest additions on this VM do not match the installed version of
    node12: VirtualBox! In most cases this is fine, but in rare cases it can
    node12: prevent things such as shared folders from working properly. If you see
    node12: shared folder errors, please make sure the guest additions within the
    node12: virtual machine match the version of VirtualBox you have installed on
    node12: your host and reload your VM.
    node12: 
    node12: Guest Additions Version: 7.0.12
    node12: VirtualBox Version: 6.1
==> node12: Setting hostname...
==> node12: Configuring and enabling network interfaces...
==> node12: Running provisioner: shell...
    node12: Running: inline script
==> node13: Box 'generic/debian12' could not be found. Attempting to find and install...
    node13: Box Provider: virtualbox
    node13: Box Version: >= 0
==> node13: Loading metadata for box 'generic/debian12'
    node13: URL: https://vagrantcloud.com/api/v2/vagrant/generic/debian12
==> node13: Adding box 'generic/debian12' (v4.3.12) for provider: virtualbox (amd64)
==> node13: Importing base box 'generic/debian12'...
==> node13: Matching MAC address for NAT networking...
==> node13: Checking if box 'generic/debian12' version '4.3.12' is up to date...
==> node13: Setting the name of the VM: vm_node13_1705932386989_63597
==> node13: Fixed port collision for 22 => 2222. Now on port 2203.
==> node13: Clearing any previously set network interfaces...
==> node13: Preparing network interfaces based on configuration...
    node13: Adapter 1: nat
    node13: Adapter 2: intnet
    node13: Adapter 3: intnet
    node13: Adapter 5: hostonly
==> node13: Forwarding ports...
    node13: 22 (guest) => 2203 (host) (adapter 1)
==> node13: Running 'pre-boot' VM customizations...
==> node13: Booting VM...
==> node13: Waiting for machine to boot. This may take a few minutes...
    node13: SSH address: 127.0.0.1:2203
    node13: SSH username: vagrant
    node13: SSH auth method: private key
    node13: Warning: Connection reset. Retrying...
    node13: 
    node13: Vagrant insecure key detected. Vagrant will automatically replace
    node13: this with a newly generated keypair for better security.
    node13: 
    node13: Inserting generated public key within guest...
    node13: Removing insecure key from the guest if it's present...
    node13: Key inserted! Disconnecting and reconnecting using new SSH key...
==> node13: Machine booted and ready!
==> node13: Checking for guest additions in VM...
    node13: The guest additions on this VM do not match the installed version of
    node13: VirtualBox! In most cases this is fine, but in rare cases it can
    node13: prevent things such as shared folders from working properly. If you see
    node13: shared folder errors, please make sure the guest additions within the
    node13: virtual machine match the version of VirtualBox you have installed on
    node13: your host and reload your VM.
    node13: 
    node13: Guest Additions Version: 7.0.12
    node13: VirtualBox Version: 6.1
==> node13: Setting hostname...
==> node13: Configuring and enabling network interfaces...
==> node13: Running provisioner: shell...
    node13: Running: inline script
==> node222: Box 'generic/debian12' could not be found. Attempting to find and install...
    node222: Box Provider: virtualbox
    node222: Box Version: >= 0
==> node222: Loading metadata for box 'generic/debian12'
    node222: URL: https://vagrantcloud.com/api/v2/vagrant/generic/debian12
==> node222: Adding box 'generic/debian12' (v4.3.12) for provider: virtualbox (amd64)
==> node222: Importing base box 'generic/debian12'...
==> node222: Matching MAC address for NAT networking...
==> node222: Checking if box 'generic/debian12' version '4.3.12' is up to date...
==> node222: Setting the name of the VM: vm_node222_1705932474143_80985
==> node222: Fixed port collision for 22 => 2222. Now on port 2204.
==> node222: Clearing any previously set network interfaces...
==> node222: Preparing network interfaces based on configuration...
    node222: Adapter 1: nat
    node222: Adapter 2: intnet
    node222: Adapter 3: intnet
    node222: Adapter 5: hostonly
==> node222: Forwarding ports...
    node222: 22 (guest) => 2204 (host) (adapter 1)
==> node222: Running 'pre-boot' VM customizations...
==> node222: Booting VM...
==> node222: Waiting for machine to boot. This may take a few minutes...
    node222: SSH address: 127.0.0.1:2204
    node222: SSH username: vagrant
    node222: SSH auth method: private key
    node222: Warning: Connection reset. Retrying...
    node222: Warning: Remote connection disconnect. Retrying...
    node222: 
    node222: Vagrant insecure key detected. Vagrant will automatically replace
    node222: this with a newly generated keypair for better security.
    node222: 
    node222: Inserting generated public key within guest...
    node222: Removing insecure key from the guest if it's present...
    node222: Key inserted! Disconnecting and reconnecting using new SSH key...
==> node222: Machine booted and ready!
==> node222: Checking for guest additions in VM...
    node222: The guest additions on this VM do not match the installed version of
    node222: VirtualBox! In most cases this is fine, but in rare cases it can
    node222: prevent things such as shared folders from working properly. If you see
    node222: shared folder errors, please make sure the guest additions within the
    node222: virtual machine match the version of VirtualBox you have installed on
    node222: your host and reload your VM.
    node222: 
    node222: Guest Additions Version: 7.0.12
    node222: VirtualBox Version: 6.1
==> node222: Setting hostname...
==> node222: Configuring and enabling network interfaces...
==> node222: Running provisioner: shell...
    node222: Running: inline script
==> mon222: Box 'generic/debian12' could not be found. Attempting to find and install...
    mon222: Box Provider: virtualbox
    mon222: Box Version: >= 0
==> mon222: Loading metadata for box 'generic/debian12'
    mon222: URL: https://vagrantcloud.com/api/v2/vagrant/generic/debian12
==> mon222: Adding box 'generic/debian12' (v4.3.12) for provider: virtualbox (amd64)
==> mon222: Importing base box 'generic/debian12'...
==> mon222: Matching MAC address for NAT networking...
==> mon222: Checking if box 'generic/debian12' version '4.3.12' is up to date...
==> mon222: Setting the name of the VM: vm_mon222_1705932563419_28119
==> mon222: Fixed port collision for 22 => 2222. Now on port 2205.
==> mon222: Clearing any previously set network interfaces...
==> mon222: Preparing network interfaces based on configuration...
    mon222: Adapter 1: nat
    mon222: Adapter 2: intnet
    mon222: Adapter 5: hostonly
==> mon222: Forwarding ports...
    mon222: 22 (guest) => 2205 (host) (adapter 1)
==> mon222: Running 'pre-boot' VM customizations...
==> mon222: Booting VM...
==> mon222: Waiting for machine to boot. This may take a few minutes...
    mon222: SSH address: 127.0.0.1:2205
    mon222: SSH username: vagrant
    mon222: SSH auth method: private key
    mon222: Warning: Connection reset. Retrying...
    mon222: Warning: Remote connection disconnect. Retrying...
    mon222: 
    mon222: Vagrant insecure key detected. Vagrant will automatically replace
    mon222: this with a newly generated keypair for better security.
    mon222: 
    mon222: Inserting generated public key within guest...
    mon222: Removing insecure key from the guest if it's present...
    mon222: Key inserted! Disconnecting and reconnecting using new SSH key...
==> mon222: Machine booted and ready!
==> mon222: Checking for guest additions in VM...
    mon222: The guest additions on this VM do not match the installed version of
    mon222: VirtualBox! In most cases this is fine, but in rare cases it can
    mon222: prevent things such as shared folders from working properly. If you see
    mon222: shared folder errors, please make sure the guest additions within the
    mon222: virtual machine match the version of VirtualBox you have installed on
    mon222: your host and reload your VM.
    mon222: 
    mon222: Guest Additions Version: 7.0.12
    mon222: VirtualBox Version: 6.1
==> mon222: Setting hostname...
==> mon222: Configuring and enabling network interfaces...
==> mon222: Running provisioner: shell...
    mon222: Running: inline script
==> node225: Box 'generic/debian12' could not be found. Attempting to find and install...
    node225: Box Provider: virtualbox
    node225: Box Version: >= 0
==> node225: Loading metadata for box 'generic/debian12'
    node225: URL: https://vagrantcloud.com/api/v2/vagrant/generic/debian12
==> node225: Adding box 'generic/debian12' (v4.3.12) for provider: virtualbox (amd64)
==> node225: Importing base box 'generic/debian12'...
==> node225: Matching MAC address for NAT networking...
==> node225: Checking if box 'generic/debian12' version '4.3.12' is up to date...
==> node225: Setting the name of the VM: vm_node225_1705932646311_17987
==> node225: Fixed port collision for 22 => 2222. Now on port 2206.
==> node225: Clearing any previously set network interfaces...
==> node225: Preparing network interfaces based on configuration...
    node225: Adapter 1: nat
    node225: Adapter 2: intnet
    node225: Adapter 3: intnet
    node225: Adapter 5: hostonly
==> node225: Forwarding ports...
    node225: 22 (guest) => 2206 (host) (adapter 1)
==> node225: Running 'pre-boot' VM customizations...
==> node225: Booting VM...
==> node225: Waiting for machine to boot. This may take a few minutes...
    node225: SSH address: 127.0.0.1:2206
    node225: SSH username: vagrant
    node225: SSH auth method: private key
    node225: Warning: Connection reset. Retrying...
    node225: 
    node225: Vagrant insecure key detected. Vagrant will automatically replace
    node225: this with a newly generated keypair for better security.
    node225: 
    node225: Inserting generated public key within guest...
    node225: Removing insecure key from the guest if it's present...
    node225: Key inserted! Disconnecting and reconnecting using new SSH key...
==> node225: Machine booted and ready!
==> node225: Checking for guest additions in VM...
    node225: The guest additions on this VM do not match the installed version of
    node225: VirtualBox! In most cases this is fine, but in rare cases it can
    node225: prevent things such as shared folders from working properly. If you see
    node225: shared folder errors, please make sure the guest additions within the
    node225: virtual machine match the version of VirtualBox you have installed on
    node225: your host and reload your VM.
    node225: 
    node225: Guest Additions Version: 7.0.12
    node225: VirtualBox Version: 6.1
==> node225: Setting hostname...
==> node225: Configuring and enabling network interfaces...
==> node225: Running provisioner: shell...
    node225: Running: inline script
==> web1: Box 'generic/debian12' could not be found. Attempting to find and install...
    web1: Box Provider: virtualbox
    web1: Box Version: >= 0
==> web1: Loading metadata for box 'generic/debian12'
    web1: URL: https://vagrantcloud.com/api/v2/vagrant/generic/debian12
==> web1: Adding box 'generic/debian12' (v4.3.12) for provider: virtualbox (amd64)
==> web1: Importing base box 'generic/debian12'...
==> web1: Matching MAC address for NAT networking...
==> web1: Checking if box 'generic/debian12' version '4.3.12' is up to date...
==> web1: Setting the name of the VM: vm_web1_1705932723087_77954
==> web1: Fixed port collision for 22 => 2222. Now on port 2207.
==> web1: Clearing any previously set network interfaces...
==> web1: Preparing network interfaces based on configuration...
    web1: Adapter 1: nat
    web1: Adapter 2: intnet
    web1: Adapter 5: hostonly
==> web1: Forwarding ports...
    web1: 22 (guest) => 2207 (host) (adapter 1)
==> web1: Running 'pre-boot' VM customizations...
==> web1: Booting VM...
==> web1: Waiting for machine to boot. This may take a few minutes...
    web1: SSH address: 127.0.0.1:2207
    web1: SSH username: vagrant
    web1: SSH auth method: private key
    web1: Warning: Connection reset. Retrying...
    web1: 
    web1: Vagrant insecure key detected. Vagrant will automatically replace
    web1: this with a newly generated keypair for better security.
    web1: 
    web1: Inserting generated public key within guest...
    web1: Removing insecure key from the guest if it's present...
    web1: Key inserted! Disconnecting and reconnecting using new SSH key...
==> web1: Machine booted and ready!
==> web1: Checking for guest additions in VM...
    web1: The guest additions on this VM do not match the installed version of
    web1: VirtualBox! In most cases this is fine, but in rare cases it can
    web1: prevent things such as shared folders from working properly. If you see
    web1: shared folder errors, please make sure the guest additions within the
    web1: virtual machine match the version of VirtualBox you have installed on
    web1: your host and reload your VM.
    web1: 
    web1: Guest Additions Version: 7.0.12
    web1: VirtualBox Version: 6.1
==> web1: Setting hostname...
==> web1: Configuring and enabling network interfaces...
==> web1: Running provisioner: shell...
    web1: Running: inline script
==> web2: Box 'generic/debian12' could not be found. Attempting to find and install...
    web2: Box Provider: virtualbox
    web2: Box Version: >= 0
==> web2: Loading metadata for box 'generic/debian12'
    web2: URL: https://vagrantcloud.com/api/v2/vagrant/generic/debian12
==> web2: Adding box 'generic/debian12' (v4.3.12) for provider: virtualbox (amd64)
==> web2: Importing base box 'generic/debian12'...
==> web2: Matching MAC address for NAT networking...
==> web2: Checking if box 'generic/debian12' version '4.3.12' is up to date...
==> web2: Setting the name of the VM: vm_web2_1705932805651_93831
==> web2: Fixed port collision for 22 => 2222. Now on port 2208.
==> web2: Clearing any previously set network interfaces...
==> web2: Preparing network interfaces based on configuration...
    web2: Adapter 1: nat
    web2: Adapter 2: intnet
    web2: Adapter 5: hostonly
==> web2: Forwarding ports...
    web2: 22 (guest) => 2208 (host) (adapter 1)
==> web2: Running 'pre-boot' VM customizations...
==> web2: Booting VM...
==> web2: Waiting for machine to boot. This may take a few minutes...
    web2: SSH address: 127.0.0.1:2208
    web2: SSH username: vagrant
    web2: SSH auth method: private key
    web2: Warning: Connection reset. Retrying...
    web2: 
    web2: Vagrant insecure key detected. Vagrant will automatically replace
    web2: this with a newly generated keypair for better security.
    web2: 
    web2: Inserting generated public key within guest...
    web2: Removing insecure key from the guest if it's present...
    web2: Key inserted! Disconnecting and reconnecting using new SSH key...
==> web2: Machine booted and ready!
==> web2: Checking for guest additions in VM...
    web2: The guest additions on this VM do not match the installed version of
    web2: VirtualBox! In most cases this is fine, but in rare cases it can
    web2: prevent things such as shared folders from working properly. If you see
    web2: shared folder errors, please make sure the guest additions within the
    web2: virtual machine match the version of VirtualBox you have installed on
    web2: your host and reload your VM.
    web2: 
    web2: Guest Additions Version: 7.0.12
    web2: VirtualBox Version: 6.1
==> web2: Setting hostname...
==> web2: Configuring and enabling network interfaces...
==> web2: Running provisioner: shell...
    web2: Running: inline script
==> database1: Box 'generic/debian12' could not be found. Attempting to find and install...
    database1: Box Provider: virtualbox
    database1: Box Version: >= 0
==> database1: Loading metadata for box 'generic/debian12'
    database1: URL: https://vagrantcloud.com/api/v2/vagrant/generic/debian12
==> database1: Adding box 'generic/debian12' (v4.3.12) for provider: virtualbox (amd64)
==> database1: Importing base box 'generic/debian12'...
==> database1: Matching MAC address for NAT networking...
==> database1: Checking if box 'generic/debian12' version '4.3.12' is up to date...
==> database1: Setting the name of the VM: vm_database1_1705932894269_2807
==> database1: Fixed port collision for 22 => 2222. Now on port 2209.
==> database1: Clearing any previously set network interfaces...
==> database1: Preparing network interfaces based on configuration...
    database1: Adapter 1: nat
    database1: Adapter 2: intnet
    database1: Adapter 5: hostonly
==> database1: Forwarding ports...
    database1: 22 (guest) => 2209 (host) (adapter 1)
==> database1: Running 'pre-boot' VM customizations...
==> database1: Booting VM...
==> database1: Waiting for machine to boot. This may take a few minutes...
    database1: SSH address: 127.0.0.1:2209
    database1: SSH username: vagrant
    database1: SSH auth method: private key
    database1: Warning: Connection reset. Retrying...
    database1: 
    database1: Vagrant insecure key detected. Vagrant will automatically replace
    database1: this with a newly generated keypair for better security.
    database1: 
    database1: Inserting generated public key within guest...
    database1: Removing insecure key from the guest if it's present...
    database1: Key inserted! Disconnecting and reconnecting using new SSH key...
==> database1: Machine booted and ready!
==> database1: Checking for guest additions in VM...
    database1: The guest additions on this VM do not match the installed version of
    database1: VirtualBox! In most cases this is fine, but in rare cases it can
    database1: prevent things such as shared folders from working properly. If you see
    database1: shared folder errors, please make sure the guest additions within the
    database1: virtual machine match the version of VirtualBox you have installed on
    database1: your host and reload your VM.
    database1: 
    database1: Guest Additions Version: 7.0.12
    database1: VirtualBox Version: 6.1
==> database1: Setting hostname...
==> database1: Configuring and enabling network interfaces...
==> database1: Running provisioner: shell...
    database1: Running: inline script
==> database2: Box 'generic/debian12' could not be found. Attempting to find and install...
    database2: Box Provider: virtualbox
    database2: Box Version: >= 0
==> database2: Loading metadata for box 'generic/debian12'
    database2: URL: https://vagrantcloud.com/api/v2/vagrant/generic/debian12
==> database2: Adding box 'generic/debian12' (v4.3.12) for provider: virtualbox (amd64)
==> database2: Importing base box 'generic/debian12'...
==> database2: Matching MAC address for NAT networking...
==> database2: Checking if box 'generic/debian12' version '4.3.12' is up to date...
==> database2: Setting the name of the VM: vm_database2_1705932985414_36551
==> database2: Fixed port collision for 22 => 2222. Now on port 2210.
==> database2: Clearing any previously set network interfaces...
==> database2: Preparing network interfaces based on configuration...
    database2: Adapter 1: nat
    database2: Adapter 2: intnet
    database2: Adapter 5: hostonly
==> database2: Forwarding ports...
    database2: 22 (guest) => 2210 (host) (adapter 1)
==> database2: Running 'pre-boot' VM customizations...
==> database2: Booting VM...
==> database2: Waiting for machine to boot. This may take a few minutes...
    database2: SSH address: 127.0.0.1:2210
    database2: SSH username: vagrant
    database2: SSH auth method: private key
    database2: Warning: Connection reset. Retrying...
    database2: 
    database2: Vagrant insecure key detected. Vagrant will automatically replace
    database2: this with a newly generated keypair for better security.
    database2: 
    database2: Inserting generated public key within guest...
    database2: Removing insecure key from the guest if it's present...
    database2: Key inserted! Disconnecting and reconnecting using new SSH key...
==> database2: Machine booted and ready!
==> database2: Checking for guest additions in VM...
    database2: The guest additions on this VM do not match the installed version of
    database2: VirtualBox! In most cases this is fine, but in rare cases it can
    database2: prevent things such as shared folders from working properly. If you see
    database2: shared folder errors, please make sure the guest additions within the
    database2: virtual machine match the version of VirtualBox you have installed on
    database2: your host and reload your VM.
    database2: 
    database2: Guest Additions Version: 7.0.12
    database2: VirtualBox Version: 6.1
==> database2: Setting hostname...
==> database2: Configuring and enabling network interfaces...
==> database2: Running provisioner: shell...
    database2: Running: inline script
==> backup1: Box 'generic/debian12' could not be found. Attempting to find and install...
    backup1: Box Provider: virtualbox
    backup1: Box Version: >= 0
==> backup1: Loading metadata for box 'generic/debian12'
    backup1: URL: https://vagrantcloud.com/api/v2/vagrant/generic/debian12
==> backup1: Adding box 'generic/debian12' (v4.3.12) for provider: virtualbox (amd64)
==> backup1: Importing base box 'generic/debian12'...
==> backup1: Matching MAC address for NAT networking...
==> backup1: Checking if box 'generic/debian12' version '4.3.12' is up to date...
==> backup1: Setting the name of the VM: vm_backup1_1705933071411_85575
==> backup1: Fixed port collision for 22 => 2222. Now on port 2211.
==> backup1: Clearing any previously set network interfaces...
==> backup1: Preparing network interfaces based on configuration...
    backup1: Adapter 1: nat
    backup1: Adapter 2: intnet
    backup1: Adapter 5: hostonly
==> backup1: Forwarding ports...
    backup1: 22 (guest) => 2211 (host) (adapter 1)
==> backup1: Running 'pre-boot' VM customizations...
==> backup1: Booting VM...
==> backup1: Waiting for machine to boot. This may take a few minutes...
    backup1: SSH address: 127.0.0.1:2211
    backup1: SSH username: vagrant
    backup1: SSH auth method: private key
    backup1: Warning: Connection reset. Retrying...
    backup1: 
    backup1: Vagrant insecure key detected. Vagrant will automatically replace
    backup1: this with a newly generated keypair for better security.
    backup1: 
    backup1: Inserting generated public key within guest...
    backup1: Removing insecure key from the guest if it's present...
    backup1: Key inserted! Disconnecting and reconnecting using new SSH key...
==> backup1: Machine booted and ready!
==> backup1: Checking for guest additions in VM...
    backup1: The guest additions on this VM do not match the installed version of
    backup1: VirtualBox! In most cases this is fine, but in rare cases it can
    backup1: prevent things such as shared folders from working properly. If you see
    backup1: shared folder errors, please make sure the guest additions within the
    backup1: virtual machine match the version of VirtualBox you have installed on
    backup1: your host and reload your VM.
    backup1: 
    backup1: Guest Additions Version: 7.0.12
    backup1: VirtualBox Version: 6.1
==> backup1: Setting hostname...
==> backup1: Configuring and enabling network interfaces...
==> backup1: Running provisioner: shell...
    backup1: Running: inline script
==> log1: Box 'generic/debian12' could not be found. Attempting to find and install...
    log1: Box Provider: virtualbox
    log1: Box Version: >= 0
==> log1: Loading metadata for box 'generic/debian12'
    log1: URL: https://vagrantcloud.com/api/v2/vagrant/generic/debian12
==> log1: Adding box 'generic/debian12' (v4.3.12) for provider: virtualbox (amd64)
==> log1: Importing base box 'generic/debian12'...
==> log1: Matching MAC address for NAT networking...
==> log1: Checking if box 'generic/debian12' version '4.3.12' is up to date...
==> log1: Setting the name of the VM: vm_log1_1705933164748_16934
==> log1: Fixed port collision for 22 => 2222. Now on port 2212.
==> log1: Clearing any previously set network interfaces...
==> log1: Preparing network interfaces based on configuration...
    log1: Adapter 1: nat
    log1: Adapter 2: intnet
    log1: Adapter 5: hostonly
==> log1: Forwarding ports...
    log1: 22 (guest) => 2212 (host) (adapter 1)
==> log1: Running 'pre-boot' VM customizations...
==> log1: Booting VM...
==> log1: Waiting for machine to boot. This may take a few minutes...
    log1: SSH address: 127.0.0.1:2212
    log1: SSH username: vagrant
    log1: SSH auth method: private key
    log1: Warning: Connection reset. Retrying...
    log1: Warning: Remote connection disconnect. Retrying...
    log1: 
    log1: Vagrant insecure key detected. Vagrant will automatically replace
    log1: this with a newly generated keypair for better security.
    log1: 
    log1: Inserting generated public key within guest...
    log1: Removing insecure key from the guest if it's present...
    log1: Key inserted! Disconnecting and reconnecting using new SSH key...
==> log1: Machine booted and ready!
==> log1: Checking for guest additions in VM...
    log1: The guest additions on this VM do not match the installed version of
    log1: VirtualBox! In most cases this is fine, but in rare cases it can
    log1: prevent things such as shared folders from working properly. If you see
    log1: shared folder errors, please make sure the guest additions within the
    log1: virtual machine match the version of VirtualBox you have installed on
    log1: your host and reload your VM.
    log1: 
    log1: Guest Additions Version: 7.0.12
    log1: VirtualBox Version: 6.1
==> log1: Setting hostname...
==> log1: Configuring and enabling network interfaces...
==> log1: Running provisioner: shell...
    log1: Running: inline script

```

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