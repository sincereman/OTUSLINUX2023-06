# Дисковая подсистема Linux

## Домашнее задание: Работа с mdadm.

Добавить в Vagrantfile еще дисков сломать/починить raid собрать R0/R5/R10 на выбор прописать собранный рейд в конф, чтобы рейд собирался при загрузке создать GPT раздел и 5 партиций.
в качестве проверки принимаются - измененный Vagrantfile, скрипт для создания рейда, конф для автосборки рейда при загрузке.
доп. задание - Vagrantfile, который сразу собирает систему с подключенным рейдом перенесети работающую систему с одним диском на RAID 1. Даунтайм на загрузку с нового диска предполагается. В качестве проверики принимается вывод команды lsblk до и после и описание хода решения (можно воспользовать утилитой Script).

## Критерии оценки:

Статус "Принято" ставится при выполнении следующего условия:
    • сдан Vagrantfile и скрипт для сборки, который можно запустить на поднятом образе 
Доп. задание выполняется по желанию 


## Ход задания
### 1. Конфигурируем базовый Vagrantfile

```shell
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson02/mdadm$ cat 

Vagrantfile 
# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
  :otuslinuxlesson02 => {
        :box_name => "centos/7",
        :ip_addr => '192.168.56.10',
	:disks => {
		:sata1 => {
			:dfile => './sata1.vdi',
			:size => 100,
			:port => 1
		},
		:sata2 => {
                        :dfile => './sata2.vdi',
                        :size => 100, # Megabytes
			:port => 2
		},
                :sata3 => {
                        :dfile => './sata3.vdi',
                        :size => 100,
                        :port => 3
                },
                :sata4 => {
                        :dfile => './sata4.vdi',
                        :size => 100, # Megabytes
                        :port => 4
                },
                :sata5 => {
                        :dfile => './sata5.vdi',
                        :size => 100, # Megabytes
                        :port => 5
                }

	}

		
  },
}

Vagrant.configure("2") do |config|

  MACHINES.each do |boxname, boxconfig|

      config.vm.define boxname do |box|

          box.vm.box = boxconfig[:box_name]
          box.vm.host_name = boxname.to_s

          #box.vm.network "forwarded_port", guest: 3260, host: 3260+offset

          box.vm.network "private_network", ip: boxconfig[:ip_addr]

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
	      mkdir -p ~root/.ssh
              cp ~vagrant/.ssh/auth* ~root/.ssh
              yum install https://repo.ius.io/ius-release-el7.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm 
#Попытка решить проблему с ключами - неудачная
              yum update
	      yum install -y mdadm smartmontools hdparm gdisk
  	  SHELL

      end
  end
end
```


При инсталяции ругается на GPG ключи. но устанавливается.

### 2. Входим в систему

```shell
vagrant ssh
```

### 3. Смотрим состояние дисковой подсистемы

```shell

Вывод:

[root@otuslinuxlesson02 vagrant]# sudo lshw -short | grep disk
/0/100/1.1/0.0.0    /dev/sda   disk        42GB VBOX HARDDISK
/0/100/d/0          /dev/sdb   disk        104MB VBOX HARDDISK
/0/100/d/1          /dev/sdc   disk        104MB VBOX HARDDISK
/0/100/d/2          /dev/sdd   disk        104MB VBOX HARDDISK
/0/100/d/3          /dev/sde   disk        104MB VBOX HARDDISK
/0/100/d/0.0.0      /dev/sdf   disk        104MB VBOX HARDDISK

```

Диски на месте  - размер соответствует

Пробуем занулить суперблоки

```shell

sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
mdadm: Unrecognised md component device - /dev/sdb
mdadm: Unrecognised md component device - /dev/sdc
mdadm: Unrecognised md component device - /dev/sdd
mdadm: Unrecognised md component device - /dev/sde
mdadm: Unrecognised md component device - /dev/sdf

```


 Гугл говорит, что это нормально для новых дисков.

### 4. Собираем массив

```shell
sudo mdadm --create --verbose /dev/md0 -l 5 -n 5 /dev/sd{b,c,d,e,f}
mdadm: layout defaults to left-symmetric
mdadm: layout defaults to left-symmetric
mdadm: chunk size defaults to 512K
mdadm: size set to 100352K
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.

```


### 5. Проверяем

RAID5 собрался

```shell

[root@otuslinuxlesson02 vagrant]# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid5 sdf[5] sde[3] sdd[2] sdc[1] sdb[0]
      401408 blocks super 1.2 level 5, 512k chunk, algorithm 2 [5/5] [UUUUU]
      
unused devices: <none>

[root@otuslinuxlesson02 vagrant]# sudo mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Fri Jun 30 12:26:43 2023
        Raid Level : raid5
        Array Size : 401408 (392.00 MiB 411.04 MB)
     Used Dev Size : 100352 (98.00 MiB 102.76 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Fri Jun 30 12:26:50 2023
             State : clean 
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinuxlesson02:0  (local to host otuslinuxlesson02)
              UUID : 777fe7a4:b534cf18:6a387563:3a10daa5
            Events : 18

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
       5       8       80        4      active sync   /dev/sdf

```

### 6. Смотри характеристики массива

```shell
 [root@otuslinuxlesson02 vagrant]# sudo mdadm --detail --scan --verbose
ARRAY /dev/md0 level=raid5 num-devices=5 metadata=1.2 name=otuslinuxlesson02:0 UUID=777fe7a4:b534cf18:6a387563:3a10daa5
   devices=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf

```

Дополнительно создать каталог

```shell
sudo mkdir /etc/mdadm
sudo -s #поднять права
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | sudo awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
```


Вывод

```shell
[root@otuslinuxlesson02 vagrant]# cat /etc/mdadm/mdadm.conf 
DEVICE partitions
ARRAY /dev/md0 level=raid5 num-devices=5 metadata=1.2 name=otuslinuxlesson02:0 UUID=777fe7a4:b534cf18:6a387563:3a10daa5
```


### 7. Готовый скрипт для создания RAID5 

```shell

#!/bin/bash
sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
sudo mdadm --create --verbose /dev/md0 -l 5 -n 5 /dev/sd{b,c,d,e,f}
sudo mkdir /etc/mdadm
sudo -s
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
sudo mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf

```


### 8. Сломаем RAID 5

Сломать

```shell
[root@otuslinuxlesson02 vagrant]# sudo mdadm /dev/md0 --fail /dev/sdf
mdadm: set /dev/sdf faulty in /dev/md0
```

Починить

```shell

[root@otuslinuxlesson02 vagrant]# sudo mdadm /dev/md0 --remove /dev/sdf
mdadm: hot removed /dev/sdf from /dev/md0
[root@otuslinuxlesson02 vagrant]# sudo mdadm /dev/md0 --add /dev/sdf
mdadm: added /dev/sdf
[root@otuslinuxlesson02 vagrant]# sudo mdadm --zero-superblock --force /dev/sdf
```

Ребилд

```shell
[root@otuslinuxlesson02 vagrant]# sudo mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Fri Jun 30 12:26:43 2023
        Raid Level : raid5
        Array Size : 401408 (392.00 MiB 411.04 MB)
     Used Dev Size : 100352 (98.00 MiB 102.76 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Mon Jul  3 12:10:16 2023
             State : clean, degraded, recovering 
    Active Devices : 4
   Working Devices : 5
    Failed Devices : 0
     Spare Devices : 1

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

    Rebuild Status : 1% complete

              Name : otuslinuxlesson02:0  (local to host otuslinuxlesson02)
              UUID : 777fe7a4:b534cf18:6a387563:3a10daa5
            Events : 48

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
       5       8       80        4      spare rebuilding   /dev/sdf
```

Починился

```shell
[root@otuslinuxlesson02 vagrant]# sudo mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Fri Jun 30 12:26:43 2023
        Raid Level : raid5
        Array Size : 401408 (392.00 MiB 411.04 MB)
     Used Dev Size : 100352 (98.00 MiB 102.76 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Mon Jul  3 12:10:19 2023
             State : clean 
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinuxlesson02:0  (local to host otuslinuxlesson02)
              UUID : 777fe7a4:b534cf18:6a387563:3a10daa5
            Events : 65

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
       5       8       80        4      active sync   /dev/sdf
```



### 9. Создать GPT раздел, пять партиций и смонтировать их на диск

```shell
sudo -s
sudo parted -s /dev/md0 mklabel gpt 

[root@otuslinuxlesson02 vagrant]# sudo parted -a optimal /dev/md0 mkpart primary ext4 0% 20%
Warning: The resulting partition is not properly aligned for best performance.
Ignore/Cancel? Ignore                                                     
Information: You may need to update /etc/fstab.
```

Ругается на выравнивнивание

Проверить вот так при автосборке
```shell
sudo parted -a optimal /dev/md0 mkpart primary ext4 2048KiB 20%

[root@otuslinuxlesson02 vagrant]# sudo parted /dev/md0 mkpart primary ext4 20% 40%
Information: You may need to update /etc/fstab.

[root@otuslinuxlesson02 vagrant]# sudo parted /dev/md0 mkpart primary ext4 40% 60%
Information: You may need to update /etc/fstab.

[root@otuslinuxlesson02 vagrant]# sudo parted /dev/md0 mkpart primary ext4 60% 80%
Information: You may need to update /etc/fstab.

[root@otuslinuxlesson02 vagrant]# sudo parted /dev/md0 mkpart primary ext4 80% 100%
Information: You may need to update /etc/fstab.
```

Создаем файловую систему

```shell
[root@otuslinuxlesson02 vagrant]# for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
mke2fs 1.42.9 (28-Dec-2013)
/dev/md0p1 alignment is offset by 506880 bytes.
This may result in very poor performance, (re)-partitioning suggested.
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=2048 blocks
20080 inodes, 80264 blocks
4013 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33685504
10 block groups
8192 blocks per group, 8192 fragments per group
2008 inodes per group
Superblock backups stored on blocks: 
	8193, 24577, 40961, 57345, 73729

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done 

mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=2048 blocks
19520 inodes, 77824 blocks
3891 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33685504
10 block groups
8192 blocks per group, 8192 fragments per group
1952 inodes per group
Superblock backups stored on blocks: 
	8193, 24577, 40961, 57345, 73729

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done 

mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=2048 blocks
20480 inodes, 81920 blocks
4096 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33685504
10 block groups
8192 blocks per group, 8192 fragments per group
2048 inodes per group
Superblock backups stored on blocks: 
	8193, 24577, 40961, 57345, 73729

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done 

mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=2048 blocks
20000 inodes, 79872 blocks
3993 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33685504
10 block groups
8192 blocks per group, 8192 fragments per group
2000 inodes per group
Superblock backups stored on blocks: 
	8193, 24577, 40961, 57345, 73729

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done 

mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=2048 blocks
20000 inodes, 79852 blocks
3992 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33685504
10 block groups
8192 blocks per group, 8192 fragments per group
2000 inodes per group
Superblock backups stored on blocks: 
	8193, 24577, 40961, 57345, 73729

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done 
```

Создаем точки монтирования

```shell
[root@otuslinuxlesson02 vagrant]# sudo mkdir -p /raid/part{1,2,3,4,5}
```

Монтируем


```shell
[root@otuslinuxlesson02 vagrant]# for i in $(seq 1 5); do sudo mount /dev/md0p$i /raid/part$i; done
mount: /dev/md0p1 is already mounted or /raid/part1 busy
       /dev/md0p1 is already mounted on /raid/part1
mount: /dev/md0p5 is already mounted or /raid/part5 busy
       /dev/md0p5 is already mounted on /raid/part5
```

Изменим fstab

```shell

[root@otuslinuxlesson02 vagrant]# for i in $(seq 1 5); do sudo echo '/dev/md0p'$i' /raid/part'$i' ext4    defaults    1 2' | sudo tee -a /etc/fstab; done
/dev/md0p1 /raid/part1 ext4    defaults    1 2
/dev/md0p2 /raid/part2 ext4    defaults    1 2
/dev/md0p3 /raid/part3 ext4    defaults    1 2
/dev/md0p4 /raid/part4 ext4    defaults    1 2
/dev/md0p5 /raid/part5 ext4    defaults    1 2

```

Тут было ручное размонтирование и проверка монтирования через fstab

```shell

sudo mount -a
```


### 10. Готовый скрипт для создания рэйд массива и создания партиций

```shell

#!/bin/bash

echo "Start create RAID 5" 

	      echo "Start create RAID 5"
              echo "Erase superblocks"
              sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
              echo "Create RAID 5"
              sudo mdadm --create --verbose /dev/md0 -l 5 -n 5 /dev/sd{b,c,d,e,f} 
              echo "Wait a little time to create RAID"              
              sleep 5
              sudo mkdir /etc/mdadm
              sudo -s
              echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
              echo "MDADM.conf"
              sudo mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
              cat /etc/mdadm/mdadm.conf
              echo "Create partition"
              sudo parted -s /dev/md0 mklabel gpt
              sudo parted /dev/md0 mkpart primary ext4 2048KiB 20%
              sudo parted /dev/md0 mkpart primary ext4 20% 40%
              sudo parted /dev/md0 mkpart primary ext4 40% 60%
              sudo parted /dev/md0 mkpart primary ext4 60% 80%
              sudo parted /dev/md0 mkpart primary ext4 80% 100%
              echo "Create Filesystem"
              for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
              sudo mkdir -p /raid/part{1,2,3,4,5}
              echo "Mount part to folders"
              for i in $(seq 1 5); do sudo mount /dev/md0p$i /raid/part$i; done
              echo "Create /etc/fstab"
              for i in $(seq 1 5); do sudo echo '/dev/md0p'$i' /raid/part'$i' ext4    defaults 1 2' | sudo tee -a /etc/fstab; done
              sleep 5
              cat /etc/fstab
              cat /proc/mdstat

```


Собственно все, осталось задание со звездочкой. Но сначала нужно послушать урок)))