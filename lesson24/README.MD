# Домашнее задание - Logs

Настраиваем центральный сервер для сбора логов

## Цель:

научится проектировать централизованный сбор логов;
рассмотреть особенности разных платформ для сбора логов.

## Описание/Пошаговая инструкция выполнения домашнего задания:

Для выполнения домашнего задания используйте методичку
https://docs.google.com/document/d/16UBAMu4LYqvRv6PmCeHcmOampMrIZavH/edit?usp=share_link&ouid=104106368295333385634&rtpof=true&sd=true
Что нужно сделать?

    в вагранте поднимаем 2 машины web и log
    на web поднимаем nginx
    на log настраиваем центральный лог сервер на любой системе на выбор

    journald;
    rsyslog;
    elk.

    настраиваем аудит, следящий за изменением конфигов нжинкса
    Все критичные логи с web должны собираться и локально и удаленно.
    Все логи с nginx должны уходить на удаленный сервер (локально только критичные).
    Логи аудита должны также уходить на удаленную систему.
    Формат сдачи ДЗ - vagrant + ansible
    развернуть еще машину elk*

    таким образом настроить 2 центральных лог системы elk и какую либо еще;
    в elk должны уходить только логи нжинкса;
    во вторую систему все остальное.



## Описание выполнения ДЗ

Традиционно создаем Vagrantfile


```shell

# -*- mode: ruby -*-
# vim: set ft=ruby :
node_list = [
    { :host => "rsyslog-server", :box => "centos/8",
        :gui => false, :ip => "192.168.56.20" , :cpu => 2 ,:ram => 2028 },
    { :host => "rsyslog-client1", :box => "centos/8",
        :gui => false, :ip => "192.168.56.21" , :cpu => 1 ,:ram => 1024 },
    { :host => "rsyslog-client2", :box => "centos/8",
        :gui => false, :ip => "192.168.56.22" , :cpu => 1 ,:ram => 1024 },
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

<details><summary>Listing Vagarant</summary>

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson24/rsyslog/vm$ vagrant up
Bringing machine 'rsyslog-server' up with 'virtualbox' provider...
Bringing machine 'rsyslog-client1' up with 'virtualbox' provider...
Bringing machine 'rsyslog-client2' up with 'virtualbox' provider...
==> rsyslog-server: Importing base box 'centos/8'...
==> rsyslog-server: Matching MAC address for NAT networking...
==> rsyslog-server: Checking if box 'centos/8' version '2011.0' is up to date...
==> rsyslog-server: There was a problem while downloading the metadata for your box
==> rsyslog-server: to check for updates. This is not an error, since it is usually due
==> rsyslog-server: to temporary network problems. This is just a warning. The problem
==> rsyslog-server: encountered was:
==> rsyslog-server: 
==> rsyslog-server: The requested URL returned error: 404
==> rsyslog-server: 
==> rsyslog-server: If you want to check for box updates, verify your network connection
==> rsyslog-server: is valid and try again.
==> rsyslog-server: Setting the name of the VM: rsyslog-server
==> rsyslog-server: Clearing any previously set network interfaces...
==> rsyslog-server: Preparing network interfaces based on configuration...
    rsyslog-server: Adapter 1: nat
    rsyslog-server: Adapter 2: hostonly
==> rsyslog-server: Forwarding ports...
    rsyslog-server: 22 (guest) => 2222 (host) (adapter 1)
==> rsyslog-server: Running 'pre-boot' VM customizations...
==> rsyslog-server: Booting VM...
==> rsyslog-server: Waiting for machine to boot. This may take a few minutes...
    rsyslog-server: SSH address: 127.0.0.1:2222
    rsyslog-server: SSH username: vagrant
    rsyslog-server: SSH auth method: private key
    rsyslog-server: 
    rsyslog-server: Vagrant insecure key detected. Vagrant will automatically replace
    rsyslog-server: this with a newly generated keypair for better security.
    rsyslog-server: 
    rsyslog-server: Inserting generated public key within guest...
    rsyslog-server: Removing insecure key from the guest if it's present...
    rsyslog-server: Key inserted! Disconnecting and reconnecting using new SSH key...
==> rsyslog-server: Machine booted and ready!
==> rsyslog-server: Checking for guest additions in VM...
    rsyslog-server: No guest additions were detected on the base box for this VM! Guest
    rsyslog-server: additions are required for forwarded ports, shared folders, host only
    rsyslog-server: networking, and more. If SSH fails on this machine, please install
    rsyslog-server: the guest additions and repackage the box to continue.
    rsyslog-server: 
    rsyslog-server: This is not an error message; everything may continue to work properly,
    rsyslog-server: in which case you may ignore this message.
==> rsyslog-server: Setting hostname...
==> rsyslog-server: Configuring and enabling network interfaces...
==> rsyslog-server: Rsyncing folder: /home/sincere/vagrantdocs/lesson24/rsyslog/vm/ => /vagrant
==> rsyslog-server: Running provisioner: shell...
    rsyslog-server: Running: inline script
==> rsyslog-client1: Importing base box 'centos/8'...
==> rsyslog-client1: Matching MAC address for NAT networking...
==> rsyslog-client1: Checking if box 'centos/8' version '2011.0' is up to date...
==> rsyslog-client1: Setting the name of the VM: rsyslog-client1
==> rsyslog-client1: Fixed port collision for 22 => 2222. Now on port 2200.
==> rsyslog-client1: Clearing any previously set network interfaces...
==> rsyslog-client1: Preparing network interfaces based on configuration...
    rsyslog-client1: Adapter 1: nat
    rsyslog-client1: Adapter 2: hostonly
==> rsyslog-client1: Forwarding ports...
    rsyslog-client1: 22 (guest) => 2200 (host) (adapter 1)
==> rsyslog-client1: Running 'pre-boot' VM customizations...
==> rsyslog-client1: Booting VM...
==> rsyslog-client1: Waiting for machine to boot. This may take a few minutes...
    rsyslog-client1: SSH address: 127.0.0.1:2200
    rsyslog-client1: SSH username: vagrant
    rsyslog-client1: SSH auth method: private key
    rsyslog-client1: 
    rsyslog-client1: Vagrant insecure key detected. Vagrant will automatically replace
    rsyslog-client1: this with a newly generated keypair for better security.
    rsyslog-client1: 
    rsyslog-client1: Inserting generated public key within guest...
    rsyslog-client1: Removing insecure key from the guest if it's present...
    rsyslog-client1: Key inserted! Disconnecting and reconnecting using new SSH key...
==> rsyslog-client1: Machine booted and ready!
==> rsyslog-client1: Checking for guest additions in VM...
    rsyslog-client1: No guest additions were detected on the base box for this VM! Guest
    rsyslog-client1: additions are required for forwarded ports, shared folders, host only
    rsyslog-client1: networking, and more. If SSH fails on this machine, please install
    rsyslog-client1: the guest additions and repackage the box to continue.
    rsyslog-client1: 
    rsyslog-client1: This is not an error message; everything may continue to work properly,
    rsyslog-client1: in which case you may ignore this message.
==> rsyslog-client1: Setting hostname...
==> rsyslog-client1: Configuring and enabling network interfaces...
==> rsyslog-client1: Rsyncing folder: /home/sincere/vagrantdocs/lesson24/rsyslog/vm/ => /vagrant
==> rsyslog-client1: Running provisioner: shell...
    rsyslog-client1: Running: inline script
==> rsyslog-client2: Importing base box 'centos/8'...
==> rsyslog-client2: Matching MAC address for NAT networking...
==> rsyslog-client2: Checking if box 'centos/8' version '2011.0' is up to date...
==> rsyslog-client2: Setting the name of the VM: rsyslog-client2
==> rsyslog-client2: Fixed port collision for 22 => 2222. Now on port 2201.
==> rsyslog-client2: Clearing any previously set network interfaces...
==> rsyslog-client2: Preparing network interfaces based on configuration...
    rsyslog-client2: Adapter 1: nat
    rsyslog-client2: Adapter 2: hostonly
==> rsyslog-client2: Forwarding ports...
    rsyslog-client2: 22 (guest) => 2201 (host) (adapter 1)
==> rsyslog-client2: Running 'pre-boot' VM customizations...
==> rsyslog-client2: Booting VM...
==> rsyslog-client2: Waiting for machine to boot. This may take a few minutes...
    rsyslog-client2: SSH address: 127.0.0.1:2201
    rsyslog-client2: SSH username: vagrant
    rsyslog-client2: SSH auth method: private key
    rsyslog-client2: 
    rsyslog-client2: Vagrant insecure key detected. Vagrant will automatically replace
    rsyslog-client2: this with a newly generated keypair for better security.
    rsyslog-client2: 
    rsyslog-client2: Inserting generated public key within guest...
    rsyslog-client2: Removing insecure key from the guest if it's present...
    rsyslog-client2: Key inserted! Disconnecting and reconnecting using new SSH key...
==> rsyslog-client2: Machine booted and ready!
==> rsyslog-client2: Checking for guest additions in VM...
    rsyslog-client2: No guest additions were detected on the base box for this VM! Guest
    rsyslog-client2: additions are required for forwarded ports, shared folders, host only
    rsyslog-client2: networking, and more. If SSH fails on this machine, please install
    rsyslog-client2: the guest additions and repackage the box to continue.
    rsyslog-client2: 
    rsyslog-client2: This is not an error message; everything may continue to work properly,
    rsyslog-client2: in which case you may ignore this message.
==> rsyslog-client2: Setting hostname...
==> rsyslog-client2: Configuring and enabling network interfaces...
==> rsyslog-client2: Rsyncing folder: /home/sincere/vagrantdocs/lesson24/rsyslog/vm/ => /vagrant
==> rsyslog-client2: Running provisioner: shell...
    rsyslog-client2: Running: inline script

```

Подготовка каталогов

```shell

.
├── README.MD
└── rsyslog
    ├── ansible
    │   ├── ansible.cfg
    │   ├── inventories
    │   │   └── hosts
    │   ├── playbooks
    │   │   ├── client.yml
    │   │   ├── server.yml
    │   │   └─
    │   └── roles
    │       ├── client
    │       │   ├── files
    │       │   │   └── etc
    │       │   │       ├── nginx
    │       │   │       │   └── nginx.conf
    │       │   │       └── rsyslog
    │       │   │           ├── rsyslog.conf
    │       │   │           └── template
    │       │   │               └── all_logs.conf
    │       │   ├── handlers
    │       │   │   └── main.yml
    │       │   ├── tasks
    │       │   │   └── main.yml
    │       │   └── vars
    │       │       └── main.yml
    │       ├── server
    │       │   ├── files
    │       │   │   └── etc
    │       │   │       └── rsyslog
    │       │   │           ├── rsyslog.conf
    │       │   │           └── template
    │       │   │               └── otus.conf
    │       │   ├── handlers
    │       │   │   └── main.yml
    │       │   ├── tasks
    │       │   │   └── main.yml
    │       │   └── vars
    │       │       └── main.yml
    └── vm
        └── Vagrantfile







sincere@sincere-ubuntuotus:~/vagrantdocs/lesson24/rsyslog/vm$ cd ..
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson24/rsyslog$ cd ansible/

```

```shell

Запуск playbook - отдельно для серверов и клиента

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson24/rsyslog/ansible$ ansible-playbook playbooks/server.yml

PLAY [Playbook of server initialization] **************************************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************************************
ok: [rsyslog-server]

TASK [../roles/server : Set time zone] ****************************************************************************************************************************************************************************
changed: [rsyslog-server]

TASK [../roles/server : Update Repo url] **************************************************************************************************************************************************************************
changed: [rsyslog-server] => (item=sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo)
changed: [rsyslog-server] => (item=sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo)
[WARNING]: Consider using the replace, lineinfile or template module rather than running 'sed'.  If you need to use command because replace, lineinfile or template is insufficient you can add 'warn: false' to
this command task or set 'command_warnings=False' in ansible.cfg to get rid of this message.

TASK [../roles/server : Synchronize datetime | Install chrony] ****************************************************************************************************************************************************
changed: [rsyslog-server]

TASK [../roles/server : Synchronize datetime | Turn on chronyd] ***************************************************************************************************************************************************
ok: [rsyslog-server]

TASK [../roles/server : Install the latest version of Rsyslog] ****************************************************************************************************************************************************
changed: [rsyslog-server]

TASK [../roles/server : Install the SEManage] *********************************************************************************************************************************************************************
changed: [rsyslog-server]

TASK [../roles/server : Remove file /etc/rsyslog.d/] **************************************************************************************************************************************************************
changed: [rsyslog-server] => (item=absent)
changed: [rsyslog-server] => (item=directory)

TASK [../roles/server : Remove file /var/log/rsyslog/] ************************************************************************************************************************************************************
ok: [rsyslog-server] => (item=absent)
changed: [rsyslog-server] => (item=directory)

TASK [../roles/server : Copy ./rsyslog.conf to /etc/rsyslog.conf] *************************************************************************************************************************************************
changed: [rsyslog-server]

TASK [../roles/server : Rsyslog Template Otus Style] **************************************************************************************************************************************************************
changed: [rsyslog-server]

TASK [../roles/server : Rsyslog | open TCP ports] *****************************************************************************************************************************************************************
changed: [rsyslog-server] => (item=semanage port -m -t syslogd_port_t -p tcp 514)
changed: [rsyslog-server] => (item=iptables -A INPUT -p tcp --dport 514 -j ACCEPT)
changed: [rsyslog-server] => (item=exit 0)

TASK [../roles/server : Restart service rsyslog, in all cases] ****************************************************************************************************************************************************
changed: [rsyslog-server]

TASK [../roles/server : check if rsyslog has port 514 open] *******************************************************************************************************************************************************
changed: [rsyslog-server]

TASK [../roles/server : Check port] *******************************************************************************************************************************************************************************
skipping: [rsyslog-server]

RUNNING HANDLER [../roles/server : systemctl daemon reload] *******************************************************************************************************************************************************
ok: [rsyslog-server]

RUNNING HANDLER [../roles/server : service restart rsyslog] *******************************************************************************************************************************************************
changed: [rsyslog-server]

PLAY RECAP ********************************************************************************************************************************************************************************************************
rsyslog-server             : ok=16   changed=13   unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson24/rsyslog/ansible$ ansible-playbook playbooks/client.yml

PLAY [Playbook of client (node exporter) initialization] **********************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************************************
ok: [rsyslog-client1]
ok: [rsyslog-client2]

TASK [../roles/client : Set time zone] ****************************************************************************************************************************************************************************
changed: [rsyslog-client2]
changed: [rsyslog-client1]

TASK [../roles/client : Update Repo url] **************************************************************************************************************************************************************************
changed: [rsyslog-client1] => (item=sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo)
changed: [rsyslog-client2] => (item=sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo)
changed: [rsyslog-client2] => (item=sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo)
[WARNING]: Consider using the replace, lineinfile or template module rather than running 'sed'.  If you need to use command because replace, lineinfile or template is insufficient you can add 'warn: false' to
this command task or set 'command_warnings=False' in ansible.cfg to get rid of this message.
changed: [rsyslog-client1] => (item=sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo)

TASK [../roles/client : Synchronize datetime | Install chrony] ****************************************************************************************************************************************************
changed: [rsyslog-client2]
changed: [rsyslog-client1]

TASK [../roles/client : Synchronize datetime | Turn on chronyd] ***************************************************************************************************************************************************
ok: [rsyslog-client1]
ok: [rsyslog-client2]

TASK [../roles/client : Install the latest version of Rsyslog] ****************************************************************************************************************************************************
changed: [rsyslog-client2]
changed: [rsyslog-client1]

TASK [../roles/client : Remove file /etc/rsyslog.d/] **************************************************************************************************************************************************************
changed: [rsyslog-client2] => (item=absent)
changed: [rsyslog-client1] => (item=absent)
changed: [rsyslog-client2] => (item=directory)
changed: [rsyslog-client1] => (item=directory)

TASK [../roles/client : Remove file /var/log/rsyslog/] ************************************************************************************************************************************************************
ok: [rsyslog-client2] => (item=absent)
ok: [rsyslog-client1] => (item=absent)
changed: [rsyslog-client2] => (item=directory)
changed: [rsyslog-client1] => (item=directory)

TASK [../roles/client : Copy ./rsyslog.conf to /etc/rsyslog.conf] *************************************************************************************************************************************************
ok: [rsyslog-client1]
ok: [rsyslog-client2]

TASK [../roles/client : Rsyslog simple template] ******************************************************************************************************************************************************************
changed: [rsyslog-client1]
changed: [rsyslog-client2]

TASK [../roles/client : Restart service rsyslog, in all cases] ****************************************************************************************************************************************************
changed: [rsyslog-client2]
changed: [rsyslog-client1]

TASK [../roles/client : Install EPEL-repository] ******************************************************************************************************************************************************************
changed: [rsyslog-client2]
changed: [rsyslog-client1]

TASK [../roles/client : Nginx | Install Nginx package from EPEL-repository] ***************************************************************************************************************************************
changed: [rsyslog-client1]
changed: [rsyslog-client2]

TASK [../roles/client : Nginx | Configure Nginx with remote access logging] ***************************************************************************************************************************************
changed: [rsyslog-client1]
changed: [rsyslog-client2]

RUNNING HANDLER [../roles/client : systemctl daemon reload] *******************************************************************************************************************************************************
ok: [rsyslog-client2]
ok: [rsyslog-client1]

RUNNING HANDLER [../roles/client : service restart rsyslog] *******************************************************************************************************************************************************
changed: [rsyslog-client1]
changed: [rsyslog-client2]

RUNNING HANDLER [../roles/client : enable nginx] ******************************************************************************************************************************************************************
changed: [rsyslog-client1]
changed: [rsyslog-client2]

RUNNING HANDLER [../roles/client : service restart nginx] *********************************************************************************************************************************************************
changed: [rsyslog-client2]
changed: [rsyslog-client1]

PLAY RECAP ********************************************************************************************************************************************************************************************************
rsyslog-client1            : ok=18   changed=14   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
rsyslog-client2            : ok=18   changed=14   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

```

Проверка


```shell


[vagrant@rsyslog-server ~]$ tree /etc/rsyslog.d/
/etc/rsyslog.d/
└── otus.conf

0 directories, 1 file

[vagrant@rsyslog-server ~]$ cat /etc/rsyslog.d/otus.conf 

$template RemoteLogs,"/var/log/rsyslog/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs


[vagrant@rsyslog-server ~]$ sudo tree /var/log/rsyslog/
/var/log/rsyslog/
├── rsyslog-client1
│   ├── ansible-copy.log
│   ├── ansible-dnf.log
│   ├── ansible-stat.log
│   ├── ansible-systemd.log
│   ├── chronyd.log
│   ├── groupadd.log
│   ├── nginx.log
│   ├── rsyslogd.log
│   ├── sshd.log
│   ├── sudo.log
│   ├── systemd.log
│   ├── systemd-logind.log
│   └── useradd.log
├── rsyslog-client2
│   ├── anacron.log
│   ├── ansible-copy.log
│   ├── ansible-dnf.log
│   ├── ansible-stat.log
│   ├── ansible-systemd.log
│   ├── groupadd.log
│   ├── nginx.log
│   ├── rsyslogd.log
│   ├── sshd.log
│   ├── sudo.log
│   ├── systemd.log
│   ├── systemd-logind.log
│   └── useradd.log
└── rsyslog-server
    ├── ansible-command.log
    ├── ansible-systemd.log
    ├── rsyslogd.log
    ├── sshd.log
    ├── sudo.log
    ├── systemd.log
    └── systemd-logind.log

[root@rsyslog-server ~]# grep -r "error" /var/log/rsyslog
/var/log/rsyslog/rsyslog-server/sudo.log:Oct  3 13:24:00 rsyslog-server sudo[26212]: vagrant : TTY=pts/0 ; PWD=/home/vagrant ; USER=root ; COMMAND=/bin/grep -R /var/log/rsyslog/rsyslog-client1 /var/log/rsyslog/rsyslog-client2 /var/log/rsyslog/rsyslog-server error
/var/log/rsyslog/rsyslog-server/sudo.log:Oct  3 13:24:21 rsyslog-server sudo[26215]: vagrant : TTY=pts/0 ; PWD=/home/vagrant ; USER=root ; COMMAND=/bin/grep /var/log/rsyslog/rsyslog-client1 /var/log/rsyslog/rsyslog-client2 /var/log/rsyslog/rsyslog-server error
/var/log/rsyslog/rsyslog-server/sudo.log:Oct  3 13:24:36 rsyslog-server sudo[26218]: vagrant : TTY=pts/0 ; PWD=/home/vagrant ; USER=root ; COMMAND=/bin/grep ./var/log/rsyslog/* error
/var/log/rsyslog/rsyslog-server/sudo.log:Oct  3 13:25:20 rsyslog-server sudo[26230]: vagrant : TTY=pts/0 ; PWD=/home/vagrant ; USER=root ; COMMAND=/bin/grep -R /var/log/ error
/var/log/rsyslog/rsyslog-server/sudo.log:Oct  3 13:25:27 rsyslog-server sudo[26233]: vagrant : TTY=pts/0 ; PWD=/home/vagrant ; USER=root ; COMMAND=/bin/grep -R /var/log/anaconda /var/log/audit /var/log/btmp /var/log/chrony /var/log/cron /var/log/dnf.librepo.log /var/log/dnf.log /var/log/dnf.rpm.log /var/log/hawkey.log /var/log/lastlog /var/log/maillog /var/log/messages /var/log/private /var/log/qemu-ga /var/log/rsyslog /var/log/samba /var/log/secure /var/log/spooler /var/log/sssd /var/log/tuned /var/log/wtmp error

```

Rsyslog сервер с клиентами в базовой конфигурации работает

Донастройка под требования задания

Доработка nginx

```shell

http {
    server {
        listen       {{ nginx_listen_port }} default_server;
        server_name  default_server;
        root         /usr/share/nginx/html;

        error_log /var/log/nginx/error.log crit;
        error_log syslog:server={{ rsyslog_server }}:{{ rsyslog_server_syslog_port }},tag=nginx_error;
        access_log syslog:server={{ rsyslog_server }}:{{ rsyslog_server_syslog_port }},facility=local5,tag=nginx_access,severity=info;
        location / {
        }
    }


```

вывод

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson24$ cd rsyslog/ansible/
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson24/rsyslog/ansible$ ansible-playbook playbooks/client.yml -t configure-nginx

PLAY [Playbook of client (node exporter) initialization] **********************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************************************
ok: [rsyslog-client2]
ok: [rsyslog-client1]

TASK [../roles/client : Nginx | Configure Nginx with remote access logging] ***************************************************************************************************************************************
changed: [rsyslog-client2]
changed: [rsyslog-client1]

RUNNING HANDLER [../roles/client : systemctl daemon reload] *******************************************************************************************************************************************************
ok: [rsyslog-client2]
ok: [rsyslog-client1]

RUNNING HANDLER [../roles/client : service restart rsyslog] *******************************************************************************************************************************************************
changed: [rsyslog-client2]
changed: [rsyslog-client1]

RUNNING HANDLER [../roles/client : enable nginx] ******************************************************************************************************************************************************************
ok: [rsyslog-client1]
ok: [rsyslog-client2]

RUNNING HANDLER [../roles/client : service restart nginx] *********************************************************************************************************************************************************
changed: [rsyslog-client1]
changed: [rsyslog-client2]

PLAY RECAP ********************************************************************************************************************************************************************************************************
rsyslog-client1            : ok=6    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
rsyslog-client2            : ok=6    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  


```

Удалим файлик

```shell


[root@rsyslog-client1 ~]# rm /usr/share/nginx/html/poweredby.png 
rm: remove regular file '/usr/share/nginx/html/poweredby.png'? yes


[root@rsyslog-server ~]# cat  /var/log/rsyslog/rsyslog-client1/nginx_access.log 
Oct  3 13:58:19 rsyslog-client1 nginx_access: 192.168.56.1 - - [03/Oct/2023:13:58:19 +0300] "\x16\x03\x01\x02\x00\x01\x00\x01\xFC\x03\x03*\xDB\xFF\x93\x90\xD2\xC4\xDD\xF4s\xBE\xEB\xFF\x8E\xE2\x04|\xE7\x99\xFC\x11j\xCE\xC2\x87\x5C\xCD\x18\x8DX\x0BV \x84_^\xF1\x81S\x17\xF4\xE8[\x19\x04\x03\x91sw\xF3\xDAso\x80\xEA\xB8z\x01]*B\xCF'2\x88\x00\x22\x13\x01\x13\x03\x13\x02\xC0+\xC0/\xCC\xA9\xCC\xA8\xC0,\xC00\xC0" 400 173 "-" "-"
Oct  3 13:58:24 rsyslog-client1 nginx_access: 192.168.56.1 - - [03/Oct/2023:13:58:24 +0300] "GET / HTTP/1.1" 200 4057 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/117.0"
Oct  3 13:58:24 rsyslog-client1 nginx_access: 192.168.56.1 - - [03/Oct/2023:13:58:24 +0300] "GET /nginx-logo.png HTTP/1.1" 200 368 "http://192.168.56.21:8080/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/117.0"
Oct  3 13:58:24 rsyslog-client1 nginx_access: 192.168.56.1 - - [03/Oct/2023:13:58:24 +0300] "GET /poweredby.png HTTP/1.1" 200 4148 "http://192.168.56.21:8080/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/117.0"
Oct  3 13:58:24 rsyslog-client1 nginx_access: 192.168.56.1 - - [03/Oct/2023:13:58:24 +0300] "GET /favicon.ico HTTP/1.1" 404 169 "http://192.168.56.21:8080/" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/117.0"
Oct  3 14:01:15 rsyslog-client1 nginx_access: 192.168.56.1 - - [03/Oct/2023:14:01:15 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/117.0"
Oct  3 14:01:17 rsyslog-client1 nginx_access: 192.168.56.1 - - [03/Oct/2023:14:01:17 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/117.0"
[root@rsyslog-server ~]# cat  /var/log/rsyslog/rsyslog-client1/nginx_error.log 
Oct  3 13:58:24 rsyslog-client1 nginx_error: 2023/10/03 13:58:24 [error] 27733#0: *3 open() "/usr/share/nginx/html/favicon.ico" failed (2: No such file or directory), client: 192.168.56.1, server: default_server, request: "GET /favicon.ico HTTP/1.1", host: "192.168.56.21:8080", referrer: "http://192.168.56.21:8080/"

```

Добавим модули в конфиг server.yml


```shell


  # Configure Audit


- name: Add line to audit rules about nginx.conf
  ansible.builtin.lineinfile:
    path: /etc/audit/rules.d/audit.rules
    state: present
    regexp: '^-w /etc/nginx/nginx.conf -p wa -k nginx_conf'
    line: '-w /etc/nginx/nginx.conf -p wa -k nginx_conf'
  tags:
    - audit-configure
    - configure-nginx

- name: Add line to audit rules about default.d
  ansible.builtin.lineinfile:
    path: /etc/audit/rules.d/audit.rules
    state: present
    regexp: '^-w /etc/nginx/default.d/ -p wa -k nginx_conf'
    line: '-w /etc/nginx/default.d/ -p wa -k nginx_conf'
  notify:
    - service auditd restart
  tags:
    - audit-configure
    - configure-nginx


- name: Install audispd-plugins
  yum:
    name: audispd-plugins
    state: latest
  tags:
    - audit-configure


- name: Add line logformat to auditd.conf
  ansible.builtin.lineinfile:
    path: /etc/audit/auditd.conf
    state: present
    regexp: "log_format ="
    line: "log_format = RAW"
  notify:
    - service restart auditd
  tags:
    - audit-configure
    - configure-nginx

- name: Add line hosts to auditd.conf
  ansible.builtin.lineinfile:
    path: /etc/audit/auditd.conf
    state: present
    regexp: "name_format = "
    line: "name_format = hostname"
  notify:
    - service restart auditd
  tags:
    - audit-configure
    - configure-nginx

- name: Add line tcplisten to auditd.conf
  ansible.builtin.lineinfile:
    path: /etc/audit/auditd.conf
    state: present
    regexp: "##tcp_listen_port = 60"
    line: "tcp_listen_port = 60"
  notify:
    - service restart auditd
  tags:
    - audit-configure
    - configure-nginx

- name: Add line change active to /etc/audit/plugins.d/au-remote.conf
  ansible.builtin.lineinfile:
    path: /etc/audit/plugins.d/au-remote.conf
    state: present
    regexp: "active = no"
    line: "active = yes"
  notify:
    - service restart auditd
  tags:
    - audit-configure
    - configure-nginx

- name: Add line remoteserver to auditd.conf
  ansible.builtin.lineinfile:
    path: /etc/audit/audisp-remote.conf 
    state: present
    regexp: "remote_server = "
    line: "remote_server = {{ rsyslog_server }}"
  notify:
    - service restart auditd
  tags:
    - audit-configure
    - configure-nginx




```
<details><summary>log ansible</summary>

```shell 

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson24/rsyslog/ansible$ ansible-playbook playbooks/client.yml -t audit-configure

PLAY [Playbook of client (node exporter) initialization] **********************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************************************
ok: [rsyslog-client2]
ok: [rsyslog-client1]

TASK [../roles/client : Add line to audit rules about nginx.conf] *************************************************************************************************************************************************
ok: [rsyslog-client2]
ok: [rsyslog-client1]

TASK [../roles/client : Add line to audit rules about default.d] **************************************************************************************************************************************************
ok: [rsyslog-client2]
ok: [rsyslog-client1]

TASK [../roles/client : Install audispd-plugins] ******************************************************************************************************************************************************************
ok: [rsyslog-client2]
ok: [rsyslog-client1]

TASK [../roles/client : Add line logformat to auditd.conf] ********************************************************************************************************************************************************
ok: [rsyslog-client1]
ok: [rsyslog-client2]

TASK [../roles/client : Add line hosts to auditd.conf] ************************************************************************************************************************************************************
ok: [rsyslog-client1]
ok: [rsyslog-client2]

TASK [../roles/client : Add line tcplisten to auditd.conf] ********************************************************************************************************************************************************
ok: [rsyslog-client2]
ok: [rsyslog-client1]

TASK [../roles/client : Add line change active to /etc/audit/plugins.d/au-remote.conf] ****************************************************************************************************************************
ok: [rsyslog-client2]
ok: [rsyslog-client1]

TASK [../roles/client : Add line remoteserver to auditd.conf] *****************************************************************************************************************************************************
ok: [rsyslog-client2]
ok: [rsyslog-client1]

PLAY RECAP ********************************************************************************************************************************************************************************************************
rsyslog-client1            : ok=9    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
rsyslog-client2            : ok=9    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

</details>



Проверка

```shell
[root@rsyslog-client1 ~]# cat /etc/audit/rules.d/audit.rules 
## First rule - delete all
-D

## Increase the buffers to survive stress events.
## Make this bigger for busy systems
-b 8192

## This determine how long to wait in burst of events
--backlog_wait_time 60000

## Set failure mode to syslog
-f 1

-w /etc/nginx/nginx.conf -p wa -k nginx_conf
-w /etc/nginx/default.d/ -p wa -k nginx_conf


[root@rsyslog-client1 ~]# grep nginx_conf /var/log/audit/audit.log
type=CONFIG_CHANGE msg=audit(1696334856.657:2995): auid=4294967295 ses=4294967295 subj=system_u:system_r:unconfined_service_t:s0 op=add_rule key="nginx_conf" list=4 res=1AUID="unset"
type=CONFIG_CHANGE msg=audit(1696334856.657:2996): auid=4294967295 ses=4294967295 subj=system_u:system_r:unconfined_service_t:s0 op=add_rule key="nginx_conf" list=4 res=1AUID="unset"



[root@rsyslog-client1 ~]# chmod +x /etc/nginx/nginx.conf
[root@rsyslog-client1 ~]# chmod -x /etc/nginx/nginx.conf
[root@rsyslog-client1 ~]# ausearch -f /etc/nginx/nginx.conf
----
time->Tue Oct  3 15:11:00 2023
type=PROCTITLE msg=audit(1696335060.197:2998): proctitle=63686D6F64002B78002F6574632F6E67696E782F6E67696E782E636F6E66
type=PATH msg=audit(1696335060.197:2998): item=0 name="/etc/nginx/nginx.conf" inode=17486497 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 nametype=NORMAL cap_fp=0 cap_fi=0 cap_fe=0 cap_fver=0 cap_frootid=0
type=CWD msg=audit(1696335060.197:2998): cwd="/root"
type=SYSCALL msg=audit(1696335060.197:2998): arch=c000003e syscall=268 success=yes exit=0 a0=ffffff9c a1=55a6267c8320 a2=1ed a3=ffffffff items=1 ppid=26955 pid=29639 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=8 comm="chmod" exe="/usr/bin/chmod" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="nginx_conf"
----
time->Tue Oct  3 15:11:03 2023
type=PROCTITLE msg=audit(1696335063.741:2999): proctitle=63686D6F64002D78002F6574632F6E67696E782F6E67696E782E636F6E66
type=PATH msg=audit(1696335063.741:2999): item=0 name="/etc/nginx/nginx.conf" inode=17486497 dev=08:01 mode=0100755 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 nametype=NORMAL cap_fp=0 cap_fi=0 cap_fe=0 cap_fver=0 cap_frootid=0
type=CWD msg=audit(1696335063.741:2999): cwd="/root"
type=SYSCALL msg=audit(1696335063.741:2999): arch=c000003e syscall=268 success=yes exit=0 a0=ffffff9c a1=55e13a233320 a2=1a4 a3=ffffffff items=1 ppid=26955 pid=29640 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=8 comm="chmod" exe="/usr/bin/chmod" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="nginx_conf"
[root@rsyslog-client1 ~]# 


[root@rsyslog-client1 ~]# cat /etc/audit/audisp-remote.conf 
#
# This file controls the configuration of the audit remote 
# logging subsystem, audisp-remote.
#

remote_server = 192.168.56.20
port = 60
##local_port =
transport = tcp
queue_file = /var/spool/audit/remote.log
mode = immediate
queue_depth = 10240
format = managed
network_retry_time = 1
max_tries_per_record = 3
max_time_per_record = 5
heartbeat_timeout = 0 

network_failure_action = stop
disk_low_action = ignore
disk_full_action = warn_once
disk_error_action = warn_once
remote_ending_action = reconnect
generic_error_action = syslog
generic_warning_action = syslog
queue_error_action = stop
overflow_action = syslog
startup_failure_action = warn_once_continue

##krb5_principal = 
##krb5_client_name = auditd
##krb5_key_file = /etc/audisp/audisp-remote.key
[root@rsyslog-client1 ~]# cat /etc/audit/plugins.d/au-remote.conf 

# This file controls the audispd data path to the
# remote event logger. This plugin will send events to
# a remote machine (Central Logger).

active = yes
direction = out
path = /sbin/audisp-remote
type = always
#args =
format = string


```

Повторить весь процесс git clone repository
cd vm
vagrant up
cd ../ansible
ansible-playbook playbooks/server.yml
ansible-playbook playbooks/client.yml


Задание выполнено.









