# Lesson 26 - PXE Server

## Домашнее заданиt - Настройка PXE сервера для автоматической установки

### Цель:

Отрабатываем навыки установки и настройки DHCP, TFTP, PXE загрузчика и автоматической загрузки

Описание/Пошаговая инструкция выполнения домашнего задания:

Для выполнения домашнего задания используйте методичку
https://docs.google.com/document/d/1f5I8vbWAk8ah9IFpAQWN3dcWDHMqXzGb/edit?usp=share_link&ouid=104106368295333385634&rtpof=true&sd=true
Что нужно сделать?

    Следуя шагам из документа https://docs.centos.org/en-US/8-docs/advanced-install/assembly_preparing-for-a-network-install установить и настроить загрузку по сети для дистрибутива CentOS8.
    В качестве шаблона воспользуйтесь репозиторием https://github.com/nixuser/virtlab/tree/main/centos_pxe.
    Поменять установку из репозитория NFS на установку из репозитория HTTP.
    Настроить автоматическую установку для созданного kickstart файла (*) Файл загружается по HTTP.
    Задание со звездочкой *
    автоматизировать процесс установки Cobbler cледуя шагам из документа https://cobbler.github.io/quickstart/.
    Формат сдачи ДЗ - vagrant + ansible
    В чат ДЗ отправьте ссылку на ваш git-репозиторий. Обычно мы проверяем ДЗ в течение 48 часов.
    Если возникнут вопросы, обращайтесь к студентам, преподавателям и наставникам в канал группы в Telegram.
    Удачи при выполнении!


### Критерии оценки:

Статус "Принято" ставится при выполнении следующих условий:

    Ссылка на репозиторий github.
    Vagrantfile с шагами установки необходимых компонентов
    Исходный код scripts для настройки сервера (если необходимо)
    Если какие-то шаги невозможно или сложно автоматизировать, то инструкции по ручным шагам для настройки
    Задание со звездочкой выполняется по желанию.

# Выполнение

Скачаем пример настройки стенда  PXE сервера по ссылке в методичке..

Ожидаемо, даже с учетом правок из методички не взлетело, дабы не тратить время на поиск чужих ошибок будем делать сразу версию с ansible

## Ansible


Скорректируем Vagrantfile


```ruby

# -*- mode: ruby -*-
# vi: set ft=ruby :

# ТРЕБУЕТСЯ ВЫПОЛНИТЬ ЧТОБЫ ВЛЕЗ ISO!!!!  vagrant plugin install vagrant-disksize - чтобы увеличить раздел для  box

Vagrant.configure("2") do |config|

    config.vm.define "pxeserver" do |server|
        config.vm.box = 'centos9/stream'
        config.vm.box_url = 'https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-Vagrant-9-20230116.0.x86_64.vagrant-virtualbox.box'
        config.vm.box_download_checksum = '7a08a97ce54ea55d3294c69353c57db7414512264cdb30377b82748dc2f9f894'
        config.vm.box_download_checksum_type = 'sha256'
        config.disksize.size = '30GB'
            server.vm.host_name = 'pxeserver'
            server.vm.network :private_network,
                            ip: "10.0.0.20",
                            virtualbox__intnet: 'pxenet'

            # server.vm.network "forwarded_port", guest: 80, host: 8081

            server.vm.provider "virtualbox" do |vb|
                vb.memory = "1024"
                vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
            end

        
        # config.vm.network "forwarded_port", guest: 80, host: 8888

        # Change Size SDA1
        config.vm.provision "shell", inline: <<-SHELL
                yum install -y cloud-utils-growpart
                parted /dev/sda1 print free
                echo "LSBLK"
                lsblk
                parted /dev/sda print free
                echo 1 > /sys/block/sda/device/rescan
                parted /dev/sda print free
                growpart /dev/sda 1
                resize2fs /dev/sda1
                echo "LSBLK"
                lsblk
                fdisk -l
        SHELL

            # Use ansible to install server
        config.vm.provision :ansible do |ansible|
            ansible.playbook = "playbooks/pxeserver.yml"
        end

    end

    ## Client

 
    # Cent OS 8.2
    # config used from this
    # https://github.com/eoli3n/vagrant-pxe/blob/master/client/Vagrantfile
    config.vm.define "pxeclient" do |pxeclient|
        pxeclient.vm.box = 'centos/7'                       # <------ изначально стоит Сentos 7
        pxeclient.vm.host_name = 'pxeclient'
        pxeclient.vm.network :private_network, ip: "10.0.0.21"
        pxeclient.vm.provider :virtualbox do |vb|
            vb.memory = "2048"
            vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]          

        end
    end
            
end


```


Понимаю, что для проверки многовато листинга. но с учетом недоработок (устареванием) в методичках приходится возвращаться к своми скриптам и смотреть как на самом деле нужно сделать, так что мне очень полезно для освежения памяти



```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson26/centos_pxe_ansible/vm$ vagrant up
Bringing machine 'pxeserver' up with 'virtualbox' provider...
Bringing machine 'pxeclient' up with 'virtualbox' provider...
==> pxeserver: Importing base box 'centos9/stream'...
==> pxeserver: Matching MAC address for NAT networking...
==> pxeserver: Setting the name of the VM: vm_pxeserver_1698231780105_33854
==> pxeserver: Clearing any previously set network interfaces...
==> pxeserver: Preparing network interfaces based on configuration...
    pxeserver: Adapter 1: nat
    pxeserver: Adapter 2: intnet
==> pxeserver: Forwarding ports...
    pxeserver: 22 (guest) => 2222 (host) (adapter 1)
==> pxeserver: Running 'pre-boot' VM customizations...
==> pxeserver: Resized disk: old 10240 MB, req 30720 MB, new 30720 MB
==> pxeserver: You may need to resize the filesystem from within the guest.
==> pxeserver: Booting VM...
==> pxeserver: Waiting for machine to boot. This may take a few minutes...
    pxeserver: SSH address: 127.0.0.1:2222
    pxeserver: SSH username: vagrant
    pxeserver: SSH auth method: private key
    pxeserver: 
    pxeserver: Vagrant insecure key detected. Vagrant will automatically replace
    pxeserver: this with a newly generated keypair for better security.
    pxeserver: 
    pxeserver: Inserting generated public key within guest...
    pxeserver: Removing insecure key from the guest if it's present...
    pxeserver: Key inserted! Disconnecting and reconnecting using new SSH key...
==> pxeserver: Machine booted and ready!
==> pxeserver: Checking for guest additions in VM...
    pxeserver: No guest additions were detected on the base box for this VM! Guest
    pxeserver: additions are required for forwarded ports, shared folders, host only
    pxeserver: networking, and more. If SSH fails on this machine, please install
    pxeserver: the guest additions and repackage the box to continue.
    pxeserver: 
    pxeserver: This is not an error message; everything may continue to work properly,
    pxeserver: in which case you may ignore this message.
==> pxeserver: Setting hostname...
==> pxeserver: Configuring and enabling network interfaces...
==> pxeserver: Rsyncing folder: /home/sincere/vagrantdocs/lesson26/centos_pxe_ansible/vm/ => /vagrant
==> pxeserver: Running provisioner: shell...
    pxeserver: Running: inline script
    pxeserver: CentOS Stream 9 - BaseOS                        351 kB/s | 7.9 MB     00:22
    pxeserver: CentOS Stream 9 - AppStream                     289 kB/s |  18 MB     01:03
    pxeserver: CentOS Stream 9 - Extras packages               9.9 kB/s |  15 kB     00:01
    pxeserver: Dependencies resolved.
    pxeserver: ================================================================================
    pxeserver:  Package                    Architecture Version          Repository       Size
    pxeserver: ================================================================================
    pxeserver: Installing:
    pxeserver:  cloud-utils-growpart       x86_64       0.33-1.el9       appstream        35 k
    pxeserver: 
    pxeserver: Transaction Summary
    pxeserver: ================================================================================
    pxeserver: Install  1 Package
    pxeserver: 
    pxeserver: Total download size: 35 k
    pxeserver: Installed size: 75 k
    pxeserver: Downloading Packages:
    pxeserver: cloud-utils-growpart-0.33-1.el9.x86_64.rpm       76 kB/s |  35 kB     00:00
    pxeserver: --------------------------------------------------------------------------------
    pxeserver: Total                                            30 kB/s |  35 kB     00:01
    pxeserver: CentOS Stream 9 - AppStream                     1.6 MB/s | 1.6 kB     00:00
    pxeserver: Importing GPG key 0x8483C65D:
    pxeserver:  Userid     : "CentOS (CentOS Official Signing Key) <security@centos.org>"
    pxeserver:  Fingerprint: 99DB 70FA E1D7 CE22 7FB6 4882 05B5 55B3 8483 C65D
    pxeserver:  From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
    pxeserver: Key imported successfully
    pxeserver: Running transaction check
    pxeserver: Transaction check succeeded.
    pxeserver: Running transaction test
    pxeserver: Transaction test succeeded.
    pxeserver: Running transaction
    pxeserver:   Preparing        :                                                        1/1
    pxeserver:   Installing       : cloud-utils-growpart-0.33-1.el9.x86_64                 1/1
    pxeserver:   Running scriptlet: cloud-utils-growpart-0.33-1.el9.x86_64                 1/1
    pxeserver:   Verifying        : cloud-utils-growpart-0.33-1.el9.x86_64                 1/1
    pxeserver: 
    pxeserver: Installed:
    pxeserver:   cloud-utils-growpart-0.33-1.el9.x86_64
    pxeserver: 
    pxeserver: Complete!
    pxeserver: Model: Unknown (unknown)
    pxeserver: Disk /dev/sda1: 10.7GB
    pxeserver: Sector size (logical/physical): 512B/512B
    pxeserver: Partition Table: loop
    pxeserver: Disk Flags:
    pxeserver: 
    pxeserver: Number  Start  End     Size    File system  Flags
    pxeserver:  1      0.00B  10.7GB  10.7GB  ext4
    pxeserver: 
    pxeserver: LSBLK
    pxeserver: NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINTS
    pxeserver: sda      8:0    0  30G  0 disk
    pxeserver: └─sda1   8:1    0  10G  0 part /
    pxeserver: Model: ATA VBOX HARDDISK (scsi)
    pxeserver: Disk /dev/sda: 32.2GB
    pxeserver: Sector size (logical/physical): 512B/512B
    pxeserver: Partition Table: msdos
    pxeserver: Disk Flags:
    pxeserver: 
    pxeserver: Number  Start   End     Size    Type     File system  Flags
    pxeserver:         1024B   1049kB  1048kB           Free Space
    pxeserver:  1      1049kB  10.7GB  10.7GB  primary  ext4         boot
    pxeserver:         10.7GB  32.2GB  21.5GB           Free Space
    pxeserver: 
    pxeserver: Model: ATA VBOX HARDDISK (scsi)
    pxeserver: Disk /dev/sda: 32.2GB
    pxeserver: Sector size (logical/physical): 512B/512B
    pxeserver: Partition Table: msdos
    pxeserver: Disk Flags:
    pxeserver: 
    pxeserver: Number  Start   End     Size    Type     File system  Flags
    pxeserver:         1024B   1049kB  1048kB           Free Space
    pxeserver:  1      1049kB  10.7GB  10.7GB  primary  ext4         boot
    pxeserver:         10.7GB  32.2GB  21.5GB           Free Space
    pxeserver: 
    pxeserver: CHANGED: partition=1 start=2048 old: size=20969472 end=20971519 new: size=62912479 end=62914526
    pxeserver: resize2fs 1.46.5 (30-Dec-2021)
    pxeserver: Filesystem at /dev/sda1 is mounted on /; on-line resizing required
    pxeserver: old_desc_blocks = 2, new_desc_blocks = 4
    pxeserver: The filesystem on /dev/sda1 is now 7864059 (4k) blocks long.
    pxeserver: 
    pxeserver: LSBLK
    pxeserver: NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINTS
    pxeserver: sda      8:0    0  30G  0 disk
    pxeserver: └─sda1   8:1    0  30G  0 part /
    pxeserver: Disk /dev/sda: 30 GiB, 32212254720 bytes, 62914560 sectors
    pxeserver: Disk model: VBOX HARDDISK
    pxeserver: Units: sectors of 1 * 512 = 512 bytes
    pxeserver: Sector size (logical/physical): 512 bytes / 512 bytes
    pxeserver: I/O size (minimum/optimal): 512 bytes / 512 bytes
    pxeserver: Disklabel type: dos
    pxeserver: Disk identifier: 0xe69163bf
    pxeserver: 
    pxeserver: Device     Boot Start      End  Sectors Size Id Type
    pxeserver: /dev/sda1  *     2048 62914526 62912479  30G 83 Linux
==> pxeclient: Importing base box 'centos/9'...
==> pxeclient: Matching MAC address for NAT networking...
==> pxeclient: Setting the name of the VM: vm_pxeclient_1698231953835_44230
==> pxeclient: Fixed port collision for 22 => 2222. Now on port 2200.
==> pxeclient: Clearing any previously set network interfaces...
The IP address configured for the host-only network is not within the
allowed ranges. Please update the address used to be within the allowed
ranges and run the command again.

  Address: 10.0.0.21
  Ranges: 192.168.56.0/21

Valid ranges can be modified in the /etc/vbox/networks.conf file. For
more information including valid format see:

  https://www.virtualbox.org/manual/ch06.html#network_hostonly



```



Не для этого ДЗ, а для архитектуры сетей очень пригодится модуль vagrant vagranttoansible, доуcтановим его и используем в этом дз тоже

apt install python3-pip

pip install vagranttoansible



```shell 
Collecting vagranttoansible
  Downloading vagranttoansible-1.0.2-py2.py3-none-any.whl (7.0 kB)
Collecting stormssh==0.6.9
  Downloading stormssh-0.6.9.tar.gz (89 kB)
     |████████████████████████████████| 89 kB 1.2 MB/s 
Collecting flask
  Downloading flask-3.0.0-py3-none-any.whl (99 kB)
     |████████████████████████████████| 99 kB 4.8 MB/s 
Requirement already satisfied: paramiko in /usr/lib/python3/dist-packages (from stormssh==0.6.9->vagranttoansible) (2.6.0)
Requirement already satisfied: six in /usr/lib/python3/dist-packages (from stormssh==0.6.9->vagranttoansible) (1.14.0)
Collecting termcolor
  Downloading termcolor-2.3.0-py3-none-any.whl (6.9 kB)
Collecting blinker>=1.6.2
  Downloading blinker-1.6.3-py3-none-any.whl (13 kB)
Collecting click>=8.1.3
  Downloading click-8.1.7-py3-none-any.whl (97 kB)
     |████████████████████████████████| 97 kB 5.8 MB/s 
Collecting Werkzeug>=3.0.0
  Downloading werkzeug-3.0.0-py3-none-any.whl (226 kB)
     |████████████████████████████████| 226 kB 11.6 MB/s 
Collecting itsdangerous>=2.1.2
  Downloading itsdangerous-2.1.2-py3-none-any.whl (15 kB)
Collecting Jinja2>=3.1.2
  Downloading Jinja2-3.1.2-py3-none-any.whl (133 kB)
     |████████████████████████████████| 133 kB 12.3 MB/s 
Collecting importlib-metadata>=3.6.0; python_version < "3.10"an
  Downloading importlib_metadata-6.8.0-py3-none-any.whl (22 kB)
Collecting MarkupSafe>=2.1.1
  Downloading MarkupSafe-2.1.3-cp38-cp38-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (25 kB)
Requirement already satisfied: zipp>=0.5 in /usr/lib/python3/dist-packages (from importlib-metadata>=3.6.0; python_version < "3.10"->flask->stormssh==0.6.9->vagranttoansible) (1.0.0)
Building wheels for collected packages: stormssh
  Building wheel for stormssh (setup.py) ... done
  Created wheel for stormssh: filename=stormssh-0.6.9-py3-none-any.whl size=93468 sha256=3b75a6f654dbe9557f4e0029d100374c4d55e17cd99eb4ea3028a8b2172449eb
  Stored in directory: /home/sincere/.cache/pip/wheels/5f/67/01/72e8663066acec5e72fe7570414efce0980f3ae79786ccdfdc
Successfully built stormssh
Installing collected packages: blinker, click, MarkupSafe, Werkzeug, itsdangerous, Jinja2, importlib-metadata, flask, termcolor, stormssh, vagranttoansible
  WARNING: The script flask is installed in '/home/sincere/.local/bin' which is not on PATH.
  Consider adding this directory to PATH or, if you prefer to suppress this warning, use --no-warn-script-location.
  WARNING: The script storm is installed in '/home/sincere/.local/bin' which is not on PATH.file[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import
name 'environmentfilter' from 'jinja2.filters' (/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot
import name 'environmentfilter' from 'jinja2.filters' (/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Consider using the file module with state=directory rather than running 'mkdir'.  If you need to use command because file
is insufficient you can add 'warn: false' to this command task or set 'command_warnings=False' in ansible.cfg to get rid of this
message.
  Consider adding this directory to PATH or, if you prefer to suppress this warning, use --no-warn-script-location.
  WARNING: The script vagranttoansible is installed in '/home/sincere/.local/bin' which is not on PATH.
  Consider adding this directory to PATH or, if you prefer to suppress this warning, use --no-warn-script-location.
Successfully installed Jinja2-3.1.2 MarkupSafe-2.1.3 Werkzeug-3.0.0 blinker-1.6.3 click-8.1.7 flask-3.0.0 importlib-metadata-6.8.0 itsdangerous-2.1.2 stormssh-0.6.9 termcolor-2.3.0 vagranttoansible-1.0.2

```


Смотрим, что же у нас получилось

PXE Server  с диском в 30Gb
PXE Client  с диском 10Gb
заходим в настройки клиента - удаляем диск в 10gb и создаем 30gb иначе не хватит места
меняем порядок загрузки. отмечаем net, в настройках  сети меняем nat на pxenet




Сформируем файл hosts в inventories


```shell
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson26/centos_pxe_ansible/ansible$ python3 v2a.py -o inventories/hosts
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson26/centos_pxe_ansible/ansible$ cat inventories/hosts
pxeserver ansible_ssh_host=127.0.0.1 ansible_ssh_user=vagrant ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_private_key_file=/home/sincere/vagrantdocs/lesson26/centos_pxe_ansible/ansible/.vagrant/machines/pxeserver/virtualbox/private_key ansible_ssh_port=2222 ansible_ssh_transfer_method=scp
```


Создадим структуру по ansible

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson26/centos_pxe_ansible/ansible$ tree
.
├── ansible.cfg
├── inventories
│   └── hosts
├── playbooks
│   └── pxeserver.yml
├── roles
│   └── pxeserver
│       ├── files
│       │   ├── etc
│       │   │   ├── dhcp
│       │   │   │   └── dhcpd.conf
│       │   │   └── nginx
│       │   │       └── nginx.conf
│       │   ├── home
│       │   │   └── vagrant
│       │   │       └── cfg
│       │   │           └── ks.cfg
│       │   ├── iso
│       │   │   ├── initrd.img
│       │   │   ├── minimal.iso.README.txt
│       │   │   └── vmlinuz
│       │   └── var
│       │       └── lib
│       │           └── tftpboot
│       │               └── pxelinux
│       │                   ├── images
│       │                   │   └── CentOS-8
│       │                   │       ├── initrd.img
│       │                   │       └── vmlinuz
│       │                   ├── ldlinux.c32
│       │                   ├── libcom32.c32
│       │                   ├── libmenu.c32
│       │                   ├── libutil.c32
│       │                   ├── menu.c32
│       │                   ├── pxelinux.0
│       │                   ├── pxelinux.cfg
│       │                   │   └── default
│       │                   └── vesamenu.c32
│       ├── handlers
│       │   └── main.yml
│       ├── tasks
│       │   └── main.yml
│       └── vars
│           └── main.yml
└── Vagrantfile

22 directories, 23 files

```


Образ iso вынесен выше каталога ansible, в противном случае github переполнится.


Выполнение

```shell 

incere@sincere-ubuntuotus:~/vagrantdocs/lesson26/centos_pxe_ansible/ansible$ apt update vagrant
E: The update command takes no arguments
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson26/centos_pxe_ansible/ansible$ vagrant -v
Vagrant 2.4.0
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson26/centos_pxe_ansible/ansible$ ansible-playbook playbooks/pxeserver.yml 

PLAY [Playbook of "PXE server"] ******************************************************************************************************

TASK [Gathering Facts] ***************************************************************************************************************
ok: [pxeserver]

TASK [../roles/pxeserver : Install EPEL Repo package from standart repo] *************************************************************
ok: [pxeserver]

TASK [../roles/pxeserver : Install DHCP-server] **************************************************************************************

ok: [pxeserver]

TASK [../roles/pxeserver : Install tftp-server] **************************************************************************************

ok: [pxeserver]

TASK [../roles/pxeserver : Install nginx] ********************************************************************************************

ok: [pxeserver]

TASK [../roles/pxeserver : Configure nginx] ******************************************************************************************

ok: [pxeserver]

TASK [../roles/pxeserver : Firewall and SELinix configure] ***************************************************************************
changed: [pxeserver]

TASK [../roles/pxeserver : Set /etc/dhcp/dhcpd.conf] *********************************************************************************
ok: [pxeserver]

TASK [../roles/pxeserver : Create a directory if it does not exist] ******************************************************************

ok: [pxeserver]

TASK [../roles/pxeserver : Create a directory if it does not exist] ******************************************************************

ok: [pxeserver]

TASK [../roles/pxeserver : Create a directory if it does not exist] ******************************************************************
)
ok: [pxeserver]

TASK [../roles/pxeserver : Copy files from syslinux-tftpboot-6.04-4.el8.noarch.rpm] **************************************************

ok: [pxeserver] => (item=ldlinux.c32)
ok: [pxeserver] => (item=libcom32.c32)
ok: [pxeserver] => (item=libmenu.c32)
ok: [pxeserver] => (item=libutil.c32)
ok: [pxeserver] => (item=menu.c32)
ok: [pxeserver] => (item=pxelinux.0)
ok: [pxeserver] => (item=vesamenu.c32)

TASK [../roles/pxeserver : Copy pxelinux.cfg/default] ********************************************************************************

ok: [pxeserver]

TASK [../roles/pxeserver : Copy initrd.img and vmlinuz] ******************************************************************************

ok: [pxeserver] => (item=initrd.img)
ok: [pxeserver] => (item=vmlinuz)

TASK [../roles/pxeserver : Copy ISO] *************************************************************************************************

ok: [pxeserver] => (item=centos-stream8-boot.iso)

TASK [../roles/pxeserver : Mount `centos-stream8-boot.iso`] **************************************************************************

changed: [pxeserver]

TASK [../roles/pxeserver : Copy ks.cfg] **********************************************************************************************

ok: [pxeserver]

RUNNING HANDLER [../roles/pxeserver : systemctl-restart-dhcpd] ***********************************************************************
changed: [pxeserver]

RUNNING HANDLER [../roles/pxeserver : restart nginx] *********************************************************************************
changed: [pxeserver]

PLAY RECAP ***************************************************************************************************************************
pxeserver                  : ok=19   changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

```


Немного затем эту часть переписал, внес ansible-playbook в конфиг Vagrant


С чем пришлось столкнуться.


 - Поменял путь в сервисе tftpd (учтено в ansible) - так как все настройки перенесены в каталог nginx

 - kernel-panic на клиенте при установке по сети, если количество процессоров меньше 2. Связано с особенностями виртуализации на моей системе.

 - По label Auto install NFS - смешанный режим (чтобы показать обе части задания) - Файл kickstart берется по http, образ по nfs.

 - В папке и папке /ansible/roles/pxeserver/files/iso - лежатт заглушки нужных файлов - перед использованием нужно взять из ISO образа нормальные файлы

Итоги установки системы на скриншотах в папке files - https://github.com/sincereman/OTUSLINUX2023-06/tree/master/lesson26/centos_pxe_ansible/files.

Спасибо!
















