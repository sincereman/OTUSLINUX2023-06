# Описание домашнего задания

Определить алгоритм с наилучшим сжатием

Определить какие алгоритмы сжатия поддерживает zfs (gzip, zle, lzjb, lz4);

Создать 4 файловых системы на каждой применить свой алгоритм сжатия;

Для сжатия использовать либо текстовый файл, либо группу файлов:

Определить настройки пула

С помощью команды zfs import собрать pool ZFS;

Командами zfs определить настройки:

    - размер хранилища;

    - тип pool;

    - значение recordsize;

    - какое сжатие используется;

    - какая контрольная сумма используется.

Работа со снапшотами

скопировать файл из удаленной директории.   https://drive.google.com/file/d/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG/view?usp=sharing 

восстановить файл локально. zfs receive

найти зашифрованное сообщение в файле secret_message


# Выполнение домашнего задания

Создаем каталог lesson05
 
```shell
mkdir lesson05
cd lesson 05
```
Создаем VM

```shell

vagrant init

```
Меняем содержимое на 

<details><summary>Текст Vagrantfile</summary>

```shell 

# -*- mode: ruby -*-
# vim: set ft=ruby :
disk_controller = 'IDE' # MacOS. This setting is OS dependent. Details https://github.com/hashicorp/vagrant/issues/8105


MACHINES = {
  :zfs => {
        :box_name => "centos/7",
        :box_version => "2004.01",
    :disks => {
        :sata1 => {
            :dfile => './sata1.vdi',
            :size => 512,
            :port => 1
        },
        :sata2 => {
            :dfile => './sata2.vdi',
            :size => 512, # Megabytes
            :port => 2
        },
        :sata3 => {
            :dfile => './sata3.vdi',
            :size => 512,
            :port => 3
        },
        :sata4 => {
            :dfile => './sata4.vdi',
            :size => 512, 
            :port => 4
        },
        :sata5 => {
            :dfile => './sata5.vdi',
            :size => 512,
            :port => 5
        },
        :sata6 => {
            :dfile => './sata6.vdi',
            :size => 512,
            :port => 6
        },
        :sata7 => {
            :dfile => './sata7.vdi',
            :size => 512, 
            :port => 7
        },
        :sata8 => {
            :dfile => './sata8.vdi',
            :size => 512, 
            :port => 8
        },
    }
        
  },
}


Vagrant.configure("2") do |config|


  MACHINES.each do |boxname, boxconfig|


      config.vm.define boxname do |box|


        box.vm.box = boxconfig[:box_name]
        box.vm.box_version = boxconfig[:box_version]


        box.vm.host_name = "zfs"


        box.vm.provider :virtualbox do |vb|
              vb.customize ["modifyvm", :id, "--memory", "1024"]
              needsController = false
        boxconfig[:disks].each do |dname, dconf|
              unless File.exist?(dconf[:dfile])
              vb.customize ['createhd', '--filename', dconf[:dfile], '--variant', 'Fixed', '--size', dconf[:size]]
         needsController =  true
         end
        end
            if needsController == true
                vb.customize ["storagectl", :id, "--name", "SATA", "--add", "sata" ]
                boxconfig[:disks].each do |dname, dconf|
                vb.customize ['storageattach', :id,  '--storagectl', 'SATA', '--port', dconf[:port], '--device', 0, '--type', 'hdd', '--medium', dconf[:dfile]]
                end
             end
          end
        box.vm.provision "shell", inline: <<-SHELL
          #install zfs repo
          yum install -y http://download.zfsonlinux.org/epel/zfs-release.el7_8.noarch.rpm
          #import gpg key 
          rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
          #install DKMS style packages for correct work ZFS
          yum install -y epel-release kernel-devel zfs
          #change ZFS repo
          yum-config-manager --disable zfs
          yum-config-manager --enable zfs-kmod
          yum install -y zfs
          #Add kernel module zfs
          modprobe zfs
          #install wget
          yum install -y wget
      SHELL


    end
  end
end
</details>

```
</details>


Поднимаем машинку и входим в нее

```shell

vagrant up
vagrant ssh

```
Проверяем что у нас в системе с дисками по умолчанию


```shell

sudo -i

[root@zfs vagrant]# df -TH
Filesystem     Type      Size  Used Avail Use% Mounted on
devtmpfs       devtmpfs  512M     0  512M   0% /dev
tmpfs          tmpfs     520M     0  520M   0% /dev/shm
tmpfs          tmpfs     520M  7.0M  513M   2% /run
tmpfs          tmpfs     520M     0  520M   0% /sys/fs/cgroup
/dev/sda1      xfs        43G  7.8G   36G  18% /
tmpfs          tmpfs     104M     0  104M   0% /run/user/1000
[root@zfs vagrant]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk 
`-sda1   8:1    0   40G  0 part /
sdb      8:16   0  512M  0 disk 
sdc      8:32   0  512M  0 disk 
sdd      8:48   0  512M  0 disk 
sde      8:64   0  512M  0 disk 
sdf      8:80   0  512M  0 disk 
sdg      8:96   0  512M  0 disk 
sdh      8:112  0  512M  0 disk 
sdi      8:128  0  512M  0 disk 

```

## 1. Определить алгоритм с наилучшим сжатием

Создаем ZPOOL из указанных ниже  дисков

```shell

[root@zfs ~]# zpool create otus1 mirror /dev/sdb /dev/sdc
[root@zfs ~]# zpool create otus2 mirror /dev/sdd /dev/sde
[root@zfs ~]# zpool create otus3 mirror /dev/sdf /dev/sdg
[root@zfs ~]# zpool create otus4 mirror /dev/sdh /dev/sdi

```
Смотрим что получилось


```shell
[root@zfs ~]# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus2   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus3   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus4   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -

[root@zfs ~]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk 
`-sda1   8:1    0   40G  0 part /
sdb      8:16   0  512M  0 disk 
|-sdb1   8:17   0  502M  0 part 
`-sdb9   8:25   0    8M  0 part 
sdc      8:32   0  512M  0 disk 
|-sdc1   8:33   0  502M  0 part 
`-sdc9   8:41   0    8M  0 part 
sdd      8:48   0  512M  0 disk 
|-sdd1   8:49   0  502M  0 part 
`-sdd9   8:57   0    8M  0 part 
sde      8:64   0  512M  0 disk 
|-sde1   8:65   0  502M  0 part 
`-sde9   8:73   0    8M  0 part 
sdf      8:80   0  512M  0 disk 
|-sdf1   8:81   0  502M  0 part 
`-sdf9   8:89   0    8M  0 part 
sdg      8:96   0  512M  0 disk 
|-sdg1   8:97   0  502M  0 part 
`-sdg9   8:105  0    8M  0 part 
sdh      8:112  0  512M  0 disk 
|-sdh1   8:113  0  502M  0 part 
`-sdh9   8:121  0    8M  0 part 
sdi      8:128  0  512M  0 disk 
|-sdi1   8:129  0  502M  0 part 
`-sdi9   8:137  0    8M  0 part 

```

Добавим разные алгоритмы сжатия в каждую файловую систему:
Алгоритм lzjb: zfs set compression=lzjb otus1
Алгоритм lz4:  zfs set compression=lz4 otus2
Алгоритм gzip: zfs set compression=gzip-9 otus3
Алгоритм zle:  zfs set compression=zle otus4

```shell
[root@zfs ~]# zfs set compression=lzjb otus1
[root@zfs ~]# zfs set compression=lz4 otus2
[root@zfs ~]# zfs set compression=gzip-9 otus3
[root@zfs ~]# zfs set compression=zle otus4

```

Проверяем, что настройки применились

```shell

[root@zfs ~]# zfs get all | grep compression
otus1  compression           lzjb                   local
otus2  compression           lz4                    local
otus3  compression           gzip-9                 local
otus4  compression           zle                    local


```
И видим первые изменения

```shell

[root@zfs ~]# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   480M   122K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus2   480M   122K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus3   480M   122K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus4   480M   122K   480M        -         -     0%     0%  1.00x    ONLINE  -



```


Скачиваем контрольный файл для проверки сжатия

``` shell
[root@zfs ~]# wget  https://mirrors.edge.kernel.org/pub/linux/kernel/v6.x/linux-6.0.1.tar.gz --no-check-certificate
--2023-07-14 13:38:03--  https://mirrors.edge.kernel.org/pub/linux/kernel/v6.x/linux-6.0.1.tar.gz
Resolving mirrors.edge.kernel.org (mirrors.edge.kernel.org)... 147.75.199.223, 2604:1380:45d1:ec00::1
Connecting to mirrors.edge.kernel.org (mirrors.edge.kernel.org)|147.75.199.223|:443... connected.
WARNING: cannot verify mirrors.edge.kernel.org's certificate, issued by '/C=US/O=Let\'s Encrypt/CN=R3':
  Issued certificate has expired.
HTTP request sent, awaiting response... 200 OK
Length: 214062310 (204M) [application/x-gzip]
Saving to: 'linux-6.0.1.tar.gz'

100%[==========================================================================================>] 214,062,310 3.65MB/s   in 95s    

2023-07-14 13:39:39 (2.15 MB/s) - 'linux-6.0.1.tar.gz' saved [214062310/214062310]

```
Распакуем

```shell

tar -xf linux-6.0.1.tar.gz

```
Скопируем папку из папки с ядром в каждый zpool (все ядро оче большое и не влезает в наши 480мб  + очень долго идет процесс)
```shell
[root@zfs ~]# for i in {1..4}; do cp -r ./linux-6.0.1/arch /otus$i ; done

[root@zfs ~]# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   480M  59.6M   420M        -         -     0%    12%  1.00x    ONLINE  -
otus2   480M  53.1M   427M        -         -     0%    11%  1.00x    ONLINE  -
otus3   480M  39.0M   441M        -         -     0%     8%  1.00x    ONLINE  -
otus4   480M   111M   369M        -         -     2%    23%  1.00x    ONLINE  -


[root@zfs ~]# zfs list
NAME    USED  AVAIL     REFER  MOUNTPOINT
otus1  59.6M   292M     59.5M  /otus1
otus2  53.1M   299M     53.0M  /otus2
otus3  39.0M   313M     38.9M  /otus3
otus4   111M   241M      111M  /otus4

[root@zfs ~]# zfs get all | grep compressratio | grep -v ref
otus1  compressratio         2.12x                  -
otus2  compressratio         2.37x                  -
otus3  compressratio         3.37x                  -
otus4  compressratio         1.09x                  -


```

Видим что на разделе otus3 - максимально эффективный алгоритм сжатия.
otus3  compression           gzip-9                 local

Значит что gzip9 - сжимает максимально сильно.

## 2.Определить настройки пула



Скачиваем файл

```shell
wget -O archive.tar.gz --no-check-certificate 'https://drive.google.com/u/0/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg&export=download'



Saving to: 'archive.tar.gz'

100%[==========================================================================================>] 7,275,140   7.47MB/s   in 0.9s   

2023-07-14 14:40:55 (7.47 MB/s) - 'archive.tar.gz' saved [7275140/7275140]

```

Распакуем

```shell

[root@zfs ~]# tar -xzvf archive.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb

```

Проверяем можем ли импортировать

``` shell


[root@zfs ~]# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
 action: The pool can be imported using its name or numeric identifier.
 config:

	otus                         ONLINE
	  mirror-0                   ONLINE
	    /root/zpoolexport/filea  ONLINE
	    /root/zpoolexport/fileb  ONLINE


```
Можно импортировать

```shell

[root@zfs ~]# zpool import -d zpoolexport/ otus
[root@zfs ~]# zpool status
  pool: otus
 state: ONLINE
  scan: none requested
config:

	NAME                         STATE     READ WRITE CKSUM
	otus                         ONLINE       0     0     0
	  mirror-0                   ONLINE       0     0     0
	    /root/zpoolexport/filea  ONLINE       0     0     0
	    /root/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors

  pool: otus1
 state: ONLINE
  scan: none requested
config:

	NAME        STATE     READ WRITE CKSUM
	otus1       ONLINE       0     0     0
	  mirror-0  ONLINE       0     0     0
	    sdb     ONLINE       0     0     0
	    sdc     ONLINE       0     0     0

errors: No known data errors

  pool: otus2
 state: ONLINE
  scan: none requested
config:

	NAME        STATE     READ WRITE CKSUM
	otus2       ONLINE       0     0     0
	  mirror-0  ONLINE       0     0     0
	    sdd     ONLINE       0     0     0
	    sde     ONLINE       0     0     0

errors: No known data errors

  pool: otus3
 state: ONLINE
  scan: none requested
config:

	NAME        STATE     READ WRITE CKSUM
	otus3       ONLINE       0     0     0
	  mirror-0  ONLINE       0     0     0
	    sdf     ONLINE       0     0     0
	    sdg     ONLINE       0     0     0

errors: No known data errors

  pool: otus4
 state: ONLINE
  scan: none requested
config:

	NAME        STATE     READ WRITE CKSUM
	otus4       ONLINE       0     0     0
	  mirror-0  ONLINE       0     0     0
	    sdh     ONLINE       0     0     0
	    sdi     ONLINE       0     0     0

errors: No known data errors
```


Определяем настройки pool`а

```shell

[root@zfs ~]# zpool get all otus
NAME  PROPERTY                       VALUE                          SOURCE
otus  size                           480M                           -
otus  capacity                       0%                             -
otus  altroot                        -                              default
otus  health                         ONLINE                         -
otus  guid                           6554193320433390805            -
otus  version                        -                              default
otus  bootfs                         -                              default
otus  delegation                     on                             default
otus  autoreplace                    off                            default
otus  cachefile                      -                              default
otus  failmode                       wait                           default
otus  listsnapshots                  off                            default
otus  autoexpand                     off                            default
otus  dedupditto                     0                              default
otus  dedupratio                     1.00x                          -
otus  free                           478M                           -
otus  allocated                      2.09M                          -
otus  readonly                       off                            -
otus  ashift                         0                              default
otus  comment                        -                              default
otus  expandsize                     -                              -
otus  freeing                        0                              -
otus  fragmentation                  0%                             -
otus  leaked                         0                              -
otus  multihost                      off                            default
otus  checkpoint                     -                              -
otus  load_guid                      7599489621311287678            -
otus  autotrim                       off                            default
otus  feature@async_destroy          enabled                        local
otus  feature@empty_bpobj            active                         local
otus  feature@lz4_compress           active                         local
otus  feature@multi_vdev_crash_dump  enabled                        local
otus  feature@spacemap_histogram     active                         local
otus  feature@enabled_txg            active                         local
otus  feature@hole_birth             active                         local
otus  feature@extensible_dataset     active                         local
otus  feature@embedded_data          active                         local
otus  feature@bookmarks              enabled                        local
otus  feature@filesystem_limits      enabled                        local
otus  feature@large_blocks           enabled                        local
otus  feature@large_dnode            enabled                        local
otus  feature@sha512                 enabled                        local
otus  feature@skein                  enabled                        local
otus  feature@edonr                  enabled                        local
otus  feature@userobj_accounting     active                         local
otus  feature@encryption             enabled                        local
otus  feature@project_quota          active                         local
otus  feature@device_removal         enabled                        local
otus  feature@obsolete_counts        enabled                        local
otus  feature@zpool_checkpoint       enabled                        local
otus  feature@spacemap_v2            active                         local
otus  feature@allocation_classes     enabled                        local
otus  feature@resilver_defer         enabled                        local
otus  feature@bookmark_v2            enabled                        local

```

Можем запросить отедльный параметр командой zfs get *available* otus


    - размер хранилища;

    Размер: zfs get available otus
[root@zfs ~]# zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -

    - тип pool;

    [root@zfs ~]# zfs get type otus
NAME  PROPERTY  VALUE       SOURCE
otus  type      filesystem  -

    - значение recordsize;

    [root@zfs ~]# zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local

    - какое сжатие используется;

    [root@zfs ~]# zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local

    - какая контрольная сумма используется.

[root@zfs ~]# zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local



# 3. Работа со снапшотами


Скачиваем файл

```shell

[root@zfs ~]# wget -O otus_task2.file --no-check-certificate "https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&export=download"
--2023-07-14 14:57:23--  https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&export=download
Resolving drive.google.com (drive.google.com)... 173.194.222.194, 2a00:1450:4010:c0b::c2
Connecting to drive.google.com (drive.google.com)|173.194.222.194|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://drive.google.com/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&export=download [following]
--2023-07-14 14:57:24--  https://drive.google.com/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&export=download
Reusing existing connection to drive.google.com:443.
HTTP request sent, awaiting response... 303 See Other
Location: https://doc-00-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/18h8qdb7robbirno1uouk72qqd0l1fpb/1689346575000/16189157874053420687/*/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG?e=download&uuid=d81987bd-f529-461b-b3e3-501f3529c872 [following]
Warning: wildcards not supported in HTTP.
--2023-07-14 14:57:27--  https://doc-00-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/18h8qdb7robbirno1uouk72qqd0l1fpb/1689346575000/16189157874053420687/*/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG?e=download&uuid=d81987bd-f529-461b-b3e3-501f3529c872
Resolving doc-00-bo-docs.googleusercontent.com (doc-00-bo-docs.googleusercontent.com)... 142.251.36.33, 2a00:1450:400e:810::2001
Connecting to doc-00-bo-docs.googleusercontent.com (doc-00-bo-docs.googleusercontent.com)|142.251.36.33|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 5432736 (5.2M) [application/octet-stream]
Saving to: 'otus_task2.file'

100%[==========================================================================================>] 5,432,736   5.88MB/s   in 0.9s   

2023-07-14 14:57:29 (5.88 MB/s) - 'otus_task2.file' saved [5432736/5432736]

```

Восстанавливаем файловую систему


```shell

[root@zfs ~]# zfs receive otus/test@today < otus_task2.file

[root@zfs ~]# zfs list
NAME             USED  AVAIL     REFER  MOUNTPOINT
otus            4.93M   347M       25K  /otus
otus/hometask2  1.88M   347M     1.88M  /otus/hometask2
otus/test       2.83M   347M     2.83M  /otus/test
otus1           59.6M   292M     59.5M  /otus1
otus2           53.1M   299M     53.0M  /otus2
otus3           39.0M   313M     38.9M  /otus3
otus4            111M   241M      111M  /otus4



```
Ищем файл


```shell

[root@zfs ~]# find /otus/test -name "secret_message"
/otus/test/task1/file_mess/secret_message


```

Смотрим содержимое файла


```shell

[root@zfs ~]# cat /otus/test/task1/file_mess/secret_message
https://github.com/sindresorhus/awesome


```

Готовый Vagrant file

<details><summary>Vagrantfile</summary>


```shell
# -*- mode: ruby -*-
# vim: set ft=ruby :
disk_controller = 'IDE' # MacOS. This setting is OS dependent. Details https://github.com/hashicorp/vagrant/issues/8105


MACHINES = {
  :zfs => {
        :box_name => "centos/7",
        :box_version => "2004.01",
    :disks => {
        :sata1 => {
            :dfile => './sata1.vdi',
            :size => 512,
            :port => 1
        },
        :sata2 => {
            :dfile => './sata2.vdi',
            :size => 512, # Megabytes
            :port => 2
        },
        :sata3 => {
            :dfile => './sata3.vdi',
            :size => 512,
            :port => 3
        },
        :sata4 => {
            :dfile => './sata4.vdi',
            :size => 512, 
            :port => 4
        },
        :sata5 => {
            :dfile => './sata5.vdi',
            :size => 512,
            :port => 5
        },
        :sata6 => {
            :dfile => './sata6.vdi',
            :size => 512,
            :port => 6
        },
        :sata7 => {
            :dfile => './sata7.vdi',
            :size => 512, 
            :port => 7
        },
        :sata8 => {
            :dfile => './sata8.vdi',
            :size => 512, 
            :port => 8
        },
    }
        
  },
}


Vagrant.configure("2") do |config|


  MACHINES.each do |boxname, boxconfig|


      config.vm.define boxname do |box|


        box.vm.box = boxconfig[:box_name]
        box.vm.box_version = boxconfig[:box_version]


        box.vm.host_name = "zfsscript"


        box.vm.provider :virtualbox do |vb|
              vb.customize ["modifyvm", :id, "--memory", "1024"]
              needsController = false
        boxconfig[:disks].each do |dname, dconf|
              unless File.exist?(dconf[:dfile])
              vb.customize ['createhd', '--filename', dconf[:dfile], '--variant', 'Fixed', '--size', dconf[:size]]
         needsController =  true
         end
        end
            if needsController == true
                vb.customize ["storagectl", :id, "--name", "SATA", "--add", "sata" ]
                boxconfig[:disks].each do |dname, dconf|
                vb.customize ['storageattach', :id,  '--storagectl', 'SATA', '--port', dconf[:port], '--device', 0, '--type', 'hdd', '--medium', dconf[:dfile]]
                end
             end
          end
        box.vm.provision "shell",
             name: "scriptzfs",
             path: "scriptzfs.sh"
        end
  end
end

```

</details>

Script File

```shell

#!/bin/bash
yum install -y yum-utils


#install zfs repo
yum install -y http://download.zfsonlinux.org/epel/zfs-release.el7_8.noarch.rpm
#import gpg key 
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
#install DKMS style packages for correct work ZFS
yum install -y epel-release kernel-devel zfs
#change ZFS repo
yum-config-manager --disable zfs
yum-config-manager --enable zfs-kmod
yum install -y zfs
#Add kernel module zfs
modprobe zfs
#install wget
yum install -y wget

```


Конец ДЗ
