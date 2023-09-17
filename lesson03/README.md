# Домашнее задание

## Работа с LVM
Описание/Пошаговая инструкция выполнения домашнего задания:

### Для выполнения домашнего задания используйте методичку
Работа с LVM https://drive.google.com/file/d/1DMxzJ6ctD0-I0My-iJJEGaeLDnIs13zj/view?usp=share_link
### Что нужно сделать?
на имеющемся образе (centos/7 1804.2)
https://gitlab.com/otus_linux/stands-03-lvm
/dev/mapper/VolGroup00-LogVol00 38G 738M 37G 2% /

    уменьшить том под / до 8G
    выделить том под /home
    выделить том под /var (/var - сделать в mirror)
    для /home - сделать том для снэпшотов
    прописать монтирование в fstab (попробовать с разными опциями и разными файловыми системами на выбор)
    Работа со снапшотами:

    сгенерировать файлы в /home/
    снять снэпшот
    удалить часть файлов
    восстановиться со снэпшота
    (залоггировать работу можно утилитой script, скриншотами и т.п.)
    Задание со звездочкой*
    на нашей куче дисков попробовать поставить btrfs/zfs:
    с кешем и снэпшотами
    разметить здесь каталог /opt
    Если возникнут вопросы, обращайтесь к студентам, преподавателям и наставникам в канал группы в Telegram.
    Удачи при выполнении!


### Критерии оценки:

Статус "Принято" ставится при выполнении основной части.
Задание со звездочкой выполняется по желанию.


## Выполнение

На имеющемся образе centos/7 - v. 1804.2

```shell
git clone https://gitlab.com/otus_linux/stands-03-lvm
cd stands-03-lvm
vagrant up

Немного пришлось подкорректировать сеть в Vagrantfiles

vagrant ssh
```


### 1. Уменьшить том под / до 8G


Согласно методичке добавляем пакет xfsdump

```shell
sudo yum install xfsdump
```
Посмотрим вывод lsblk

```shell
[vagrant@lvm ~]$ lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk 
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 
```

По выводу определяем, что текущий корневой раздел  / находится на sda3

Подготовим временный том для / раздела на sdb:


```shell

Поднимаем права до root
[vagrant@lvm ~]$ sudo -s

Создаем physical volume
[root@lvm vagrant]# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.

Создаем Volume Group  vg_root

[root@lvm vagrant]# vgcreate vg_root /dev/sdb
  Volume group "vg_root" successfully created

Создаем logical volume для нового root

[root@lvm vagrant]# lvcreate -n lv_root -l +100%FREE /dev/vg_root
  Logical volume "lv_root" created.
```

Создаем файловую систему

```shell

[root@lvm vagrant]# mkfs.xfs /dev/vg_root/lv_root 
meta-data=/dev/vg_root/lv_root   isize=512    agcount=4, agsize=655104 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2620416, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

```
Монтируем

```shell
mount /dev/vg_root/lv_root /mnt
```

Клонируем данным с sda3

```shell

xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt

[root@lvm vagrant]# xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
xfsdump: using file dump (drive_simple) strategy
xfsdump: version 3.1.7 (dump format 3.0)
xfsdump: level 0 dump of lvm:/
xfsdump: dump date: Tue Jul  4 07:43:27 2023
xfsdump: session id: e26a0eb5-e93e-4cac-bf52-430286d6f299
xfsdump: session label: ""
xfsrestore: using file dump (drive_simple) strategy
xfsrestore: version 3.1.7 (dump format 3.0)
xfsrestore: searching media for dump
xfsdump: ino map phase 1: constructing initial dump list
xfsdump: ino map phase 2: skipping (no pruning necessary)
xfsdump: ino map phase 3: skipping (only one dump stream)
xfsdump: ino map construction complete
xfsdump: estimated dump size: 865455488 bytes
xfsdump: creating dump session media file 0 (media 0, file 0)
xfsdump: dumping ino map
xfsdump: dumping directories
xfsrestore: examining media file 0
xfsrestore: dump description: 
xfsrestore: hostname: lvm
xfsrestore: mount point: /
xfsrestore: volume: /dev/mapper/VolGroup00-LogVol00
xfsrestore: session time: Tue Jul  4 07:43:27 2023
xfsrestore: level: 0
xfsrestore: session label: ""
xfsrestore: media label: ""
xfsrestore: file system id: b60e9498-0baa-4d9f-90aa-069048217fee
xfsrestore: session id: e26a0eb5-e93e-4cac-bf52-430286d6f299
xfsrestore: media id: 42489fd3-05a2-4c2d-8d76-a38f0f784d49
xfsrestore: searching media for directory dump
xfsrestore: reading directories
xfsdump: dumping non-directory files
xfsrestore: 2728 directories and 23678 entries processed
xfsrestore: directory post-processing
xfsrestore: restoring non-directory files
xfsdump: ending media file
xfsdump: media file size 842430784 bytes
xfsdump: dump size (non-dir files) : 829220888 bytes
xfsdump: dump complete: 29 seconds elapsed
xfsdump: Dump Status: SUCCESS
xfsrestore: restore complete: 29 seconds elapsed
xfsrestore: Restore Status: SUCCESS

```
Проверяем что в /mnt

```shell
ls /mnt
bin  boot  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  vagrant  var
[root@lvm vagrant]# 
```

Перекофигурируем загрузчик grub для загрузки с нового места

Затем переконфигурируем grub для того, чтобы при старте перейти в новый /
Сымитируем текущий root -> сделаем в него chroot и обновим grub:

Прописываем соответствие базовых разделов
```shell
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
```

Прописываем новый корень

```shell
[root@lvm vagrant]# chroot /mnt/
```

Переконфигурируем grub2

```shell
[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done

```

Обновляем initrd

```shell
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;
s/.img//g"` --force; done

и был большой вывод

...
*** Store current command line parameters ***
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***

```

Для того, чтобы при загрузке был смонтирован нужны root нужно в файле
/boot/grub2/grub.cfg заменить rd.lvm.lv=VolGroup00/LogVol00 на rd.lvm.lv=vg_root/lv_root

[root@lvm vagrant]# cat /boot/grub2/grub.cfg | grep 'LogVol00'
	linux16 /vmlinuz-3.10.0-862.2.3.el7.x86_64 root=/dev/mapper/vg_root-lv_root ro no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=VolGroup00/LogVol00 rd.lvm.lv=VolGroup00/LogVol01 rhgb quiet 

```shell
Напишем команду изменяющую точку монтирования

sed -i 's|rd.lvm.lv=VolGroup00/LogVol00|rd.lvm.lv=vg_root/lv_root|g' /boot/grub2/grub.cfg

Проверим вывод

[root@lvm vagrant]# cat /boot/grub2/grub.cfg | grep 'vg_root'
	linux16 /vmlinuz-3.10.0-862.2.3.el7.x86_64 root=/dev/mapper/vg_root-lv_root ro no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=vg_root/lv_root rd.lvm.lv=VolGroup00/LogVol01 rhgb quiet 

```
Перезагружаемся

```shell
reboot
```

Видим что загрузились с нового места

```shell


[vagrant@lvm ~]$ sudo -s
[root@lvm vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol00 253:2    0 37.5G  0 lvm  
sdb                       8:16   0   10G  0 disk 
└─vg_root-lv_root       253:0    0   10G  0 lvm  /
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 

```

Теперь нам нужно изменить размер старой VG и вернуть на него рут. Для этого удаляем
старый LV размеров в 40G и создаем новый на 8G:


Удаляем logical volume

```shell
[root@lvm vagrant]# lvremove /dev/VolGroup00/LogVol00
Do you really want to remove active logical volume VolGroup00/LogVol00? [y/n]: y
  Logical volume "LogVol00" successfully removed
```

Создаем новый logical volume 8Gb

```shell
[root@lvm vagrant]# lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
WARNING: xfs signature detected on /dev/VolGroup00/LogVol00 at offset 0. Wipe it? [y/n]: y
  Wiping xfs signature on /dev/VolGroup00/LogVol00.
  Logical volume "LogVol00" created.
```

Создаем FS, монтируем, копируем содержимое / обратно

```shell

mkfs.xfs /dev/VolGroup00/LogVol00
mount /dev/VolGroup00/LogVol00 /mnt
xfsdump -J - /dev/vg_root/lv_root | xfsrestore -J - /mnt
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
chroot /mnt/
grub2-mkconfig -o /boot/grub2/grub.cfg
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;
s/.img//g"` --force; done

```
Вывод команд

```shell
[root@lvm vagrant]# mkfs.xfs /dev/VolGroup00/LogVol00
meta-data=/dev/VolGroup00/LogVol00 isize=512    agcount=4, agsize=524288 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2097152, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
[root@lvm vagrant]# mount /dev/VolGroup00/LogVol00 /mnt
[root@lvm vagrant]# xfsdump -J - /dev/vg_root/lv_root | xfsrestore -J - /mnt
xfsdump: using file dump (drive_simple) strategy
xfsdump: version 3.1.7 (dump format 3.0)
xfsdump: level 0 dump of lvm:/
xfsdump: dump date: Tue Jul  4 08:26:08 2023
xfsdump: session id: 4bf10f26-7d18-4897-b109-7f29580f60be
xfsdump: session label: ""
xfsrestore: using file dump (drive_simple) strategy
xfsrestore: version 3.1.7 (dump format 3.0)
xfsrestore: searching media for dump
xfsdump: ino map phase 1: constructing initial dump list
xfsdump: ino map phase 2: skipping (no pruning necessary)
xfsdump: ino map phase 3: skipping (only one dump stream)
xfsdump: ino map construction complete
xfsdump: estimated dump size: 864068544 bytes
xfsdump: creating dump session media file 0 (media 0, file 0)
xfsdump: dumping ino map
xfsdump: dumping directories
xfsrestore: examining media file 0
xfsrestore: dump description: 
xfsrestore: hostname: lvm
xfsrestore: mount point: /
xfsrestore: volume: /dev/mapper/vg_root-lv_root
xfsrestore: session time: Tue Jul  4 08:26:08 2023
xfsrestore: level: 0
xfsrestore: session label: ""
xfsrestore: media label: ""
xfsrestore: file system id: 0e3f04b7-671d-48b1-bf61-b28a07d1e819
xfsrestore: session id: 4bf10f26-7d18-4897-b109-7f29580f60be
xfsrestore: media id: ca618859-86b1-4731-ae63-ae6a01d5208d
xfsrestore: searching media for directory dump
xfsrestore: reading directories
xfsdump: dumping non-directory files
xfsrestore: 2732 directories and 23683 entries processed
xfsrestore: directory post-processing
xfsrestore: restoring non-directory files
xfsdump: ending media file
xfsdump: media file size 841015512 bytes
xfsdump: dump size (non-dir files) : 827801920 bytes
xfsdump: dump complete: 31 seconds elapsed
xfsdump: Dump Status: SUCCESS
xfsrestore: restore complete: 32 seconds elapsed
xfsrestore: Restore Status: SUCCESS
[root@lvm vagrant]# for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
[root@lvm vagrant]# chroot /mnt/
[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done
[root@lvm /]# cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;
> s/.img//g"` --force; done
Executing: /sbin/dracut -v initramfs-3.10.0-862.2.3.el7.x86_64.img 3.10.0-862.2.3.el7.x86_64 --force
dracut module 'busybox' will not be installed, because command 'busybox' could not be found!
dracut module 'crypt' will not be installed, because command 'cryptsetup' could not be found!
dracut module 'dmraid' will not be installed, because command 'dmraid' could not be found!
dracut module 'dmsquash-live-ntfs' will not be installed, because command 'ntfs-3g' could not be found!
dracut module 'multipath' will not be installed, because command 'multipath' could not be found!
dracut module 'busybox' will not be installed, because command 'busybox' could not be found!
dracut module 'crypt' will not be installed, because command 'cryptsetup' could not be found!
dracut module 'dmraid' will not be installed, because command 'dmraid' could not be found!
dracut module 'dmsquash-live-ntfs' will not be installed, because command 'ntfs-3g' could not be found!
dracut module 'multipath' will not be installed, because command 'multipath' could not be found!
*** Including module: bash ***
*** Including module: nss-softokn ***
*** Including module: i18n ***
*** Including module: drm ***
*** Including module: plymouth ***
*** Including module: dm ***
Skipping udev rule: 64-device-mapper.rules
Skipping udev rule: 60-persistent-storage-dm.rules
Skipping udev rule: 55-dm.rules
*** Including module: kernel-modules ***
Omitting driver floppy
*** Including module: lvm ***
Skipping udev rule: 64-device-mapper.rules
Skipping udev rule: 56-lvm.rules
Skipping udev rule: 60-persistent-storage-lvm.rules
*** Including module: qemu ***
*** Including module: resume ***
*** Including module: rootfs-block ***
*** Including module: terminfo ***
*** Including module: udev-rules ***
Skipping udev rule: 40-redhat-cpu-hotplug.rules
Skipping udev rule: 91-permissions.rules
*** Including module: biosdevname ***
*** Including module: systemd ***
*** Including module: usrmount ***
*** Including module: base ***
*** Including module: fs-lib ***
*** Including module: shutdown ***
*** Including modules done ***
*** Installing kernel module dependencies and firmware ***
*** Installing kernel module dependencies and firmware done ***
*** Resolving executable dependencies ***
*** Resolving executable dependencies done***
*** Hardlinking files ***
*** Hardlinking files done ***
*** Stripping files ***
*** Stripping files done ***
*** Generating early-microcode cpio image contents ***
*** No early-microcode cpio image needed ***
*** Store current command line parameters ***
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***
```

### Создаем VAR  на LVM Mirror

Пока не перезагружаемся и не выходим из под chroot - мы можем заодно перенести /varВыделить том под /var в зеркало


На свободных дисках создаем зеркало:


```shell
pvcreate /dev/sdc /dev/sdd
vgcreate vg_var /dev/sdc /dev/sdd
lvcreate -L 950M -m1 -n lv_var vg_var

```

Вывод команды

```shell
[root@lvm boot]# pvcreate /dev/sdc /dev/sdd
  Physical volume "/dev/sdc" successfully created.
  Physical volume "/dev/sdd" successfully created.
[root@lvm boot]# vgcreate vg_var /dev/sdc /dev/sdd
  Volume group "vg_var" successfully created
[root@lvm boot]# lvcreate -L 950M -m1 -n lv_var vg_var
  Rounding up size to full physical extent 952.00 MiB
  Logical volume "lv_var" created.
```

Создаем на нем ФС и перемещаем туда /var:

```shell
#Создаем FS
mkfs.ext4 /dev/vg_var/lv_var
mount /dev/vg_var/lv_var /mnt
#Копируем содержимое
cp -aR /var/* /mnt/ # rsync -avHPSAX /var/ /mnt/
#Перемещаем старый VAR
mkdir /tmp/oldvar && mv /var/* /tmp/oldvar

#Монтируем новый var в каталог /var:
umount /mnt
mount /dev/vg_var/lv_var /var
```

Вывод

```shell
[root@lvm boot]# #Создаем FS
[root@lvm boot]# mkfs.ext4 /dev/vg_var/lv_var
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
60928 inodes, 243712 blocks
12185 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=249561088
8 block groups
32768 blocks per group, 32768 fragments per group
7616 inodes per group
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

[root@lvm boot]# mount /dev/vg_var/lv_var /mnt
[root@lvm boot]# #Копируем содержимое
[root@lvm boot]# cp -aR /var/* /mnt/ # rsync -avHPSAX /var/ /mnt/
[root@lvm boot]# #Перемещаем старый VAR
[root@lvm boot]# mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
[root@lvm boot]# 
[root@lvm boot]#Монтируем новый var в каталог /var:
[root@lvm boot]# umount /mnt
[root@lvm boot]# mount /dev/vg_var/lv_var /var
```


```shell

#Правим fstab для автоматического монтирования /var:
echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab

Запись в fstab

blkid | grep var: | awk '{print $2}'
UUID="9769185a-3a03-4826-979a-cc7658f969c2"

```
Перезагружаемся

```shell
exit
reboot
```

```shell
#После чего можно успешно перезагружаться в новый (уменьшенный root) и удалять
#временную Volume Group:
sudo -s
#Удаляем промежуточный root
lvremove -y /dev/vg_root/lv_root
#Удаляем промежуточный Volume Group
vgremove -y /dev/vg_root
#Удаляем Physical Volume
pvremove -y /dev/sdb
```

Вывод команды

```shell

[root@lvm vagrant]# sudo -s
[root@lvm vagrant]# #Удаляем промежуточный root
[root@lvm vagrant]# lvremove /dev/vg_root/lv_root
Do you really want to remove active logical volume vg_root/lv_root? [y/n]: y
  WARNING: Invalid input '#  Volum...'.
Do you really want to remove active logical volume vg_root/lv_root? [y/n]: y
  Logical volume "lv_root" successfully removed


```

Посмотрим что получилось

```shell
[root@lvm vagrant]# lsblk
NAME                     MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                        8:0    0   40G  0 disk 
├─sda1                     8:1    0    1M  0 part 
├─sda2                     8:2    0    1G  0 part /boot
└─sda3                     8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00  253:0    0    8G  0 lvm  /
  └─VolGroup00-LogVol01  253:1    0  1.5G  0 lvm  [SWAP]
sdb                        8:16   0   10G  0 disk 
sdc                        8:32   0    2G  0 disk 
├─vg_var-lv_var_rmeta_0  253:3    0    4M  0 lvm  
│ └─vg_var-lv_var        253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_0 253:4    0  952M  0 lvm  
  └─vg_var-lv_var        253:7    0  952M  0 lvm  /var
sdd                        8:48   0    1G  0 disk 
├─vg_var-lv_var_rmeta_1  253:5    0    4M  0 lvm  
│ └─vg_var-lv_var        253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_1 253:6    0  952M  0 lvm  
  └─vg_var-lv_var        253:7    0  952M  0 lvm  /var
sde                        8:64   0    1G  0 disk 

```

### Выделить том под /home


```shell

lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
mkfs.xfs /dev/VolGroup00/LogVol_Home
mount /dev/VolGroup00/LogVol_Home /mnt/
cp -aR /home/* /mnt/
rm -rf /home/*
mount /mnt
mount /dev/VolGroup00/LogVol_Home /home/

```

Вывод


```shell
[root@lvm vagrant]# lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
  Logical volume "LogVol_Home" created.
[root@lvm vagrant]# mkfs.xfs /dev/VolGroup00/LogVol_Home
meta-data=/dev/VolGroup00/LogVol_Home isize=512    agcount=4, agsize=131072 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=524288, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
[root@lvm vagrant]# mount /dev/VolGroup00/LogVol_Home /mnt/
[root@lvm vagrant]# cp -aR /home/* /mnt/
[root@lvm vagrant]# rm -rf /home/*
[root@lvm vagrant]# mount /mnt
mount: /dev/mapper/VolGroup00-LogVol_Home is already mounted or /mnt busy
       /dev/mapper/VolGroup00-LogVol_Home is already mounted on /mnt
[root@lvm vagrant]# mount /dev/VolGroup00/LogVol_Home /home/

```home

Правим fstab для автоматического монтирования /home

```shell
echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab

#[root@lvm vagrant]# echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0"
#UUID="8fdd459e-f9b0-4456-b1ed-37d4e1bdfeee" /home xfs defaults 0 0
```

###  Работаем со снэпшотами

```shell

#Генерим тестовые файлы
touch /home/file{1..20}

#Создаем shapshot -L размер -s snapshot -n name

lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home


```
Вывод

```shell
[root@lvm vagrant]# touch /home/file{1..20}
[root@lvm vagrant]# 
[root@lvm vagrant]# #Создаем shapshot -L размер -s snapshot -n name
[root@lvm vagrant]# 
[root@lvm vagrant]# lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home
  Rounding up size to full physical extent 128.00 MiB
  Logical volume "home_snap" created.

```

Удалим часть файлов для имитации

```shell
ls /home


#Удаляем файлы с 11 по 20
rm -f /home/file{11..20}

ls /home

```
Вывод

```shell

[root@lvm vagrant]# ls /home
file1   file11  file13  file15  file17  file19  file20  file4  file6  file8  vagrant
file10  file12  file14  file16  file18  file2   file3   file5  file7  file9
[root@lvm vagrant]# 
[root@lvm vagrant]# 
[root@lvm vagrant]# #Удаляем файлы с 11 по 20
[root@lvm vagrant]# rm -f /home/file{11..20}
[root@lvm vagrant]# ls /home
file1  file10  file2  file3  file4  file5  file6  file7  file8  file9  vagrant

```

Восстанавливаем

```shell

#Отмонтируем home
umount /home
#Принудительно umount -l /dev/VolGroup00/LogVol_Home
#Восстанавливаемся из snapshot`а
lvconvert --merge /dev/VolGroup00/home_snap

#Монтируем раздел обратно

mount /home

```
Вывод

```shell

[root@lvm vagrant]# #Отмонтируем home
[root@lvm vagrant]# umount /home
[root@lvm vagrant]# 
[root@lvm vagrant]# #Восстанавливаемся из snapshot`а
[root@lvm vagrant]# lvconvert --merge /dev/VolGroup00/home_snap
  Delaying merge since origin is open.
  Merging of snapshot VolGroup00/home_snap will occur on next activation of VolGroup00/LogVol_Home.
[root@lvm vagrant]# 
[root@lvm vagrant]# #Монтируем раздел обратно
[root@lvm vagrant]# 
[root@lvm vagrant]# mount /home
```

#*


Добавляем диск sdb в VG vg_var

```shell
[root@lvm vagrant]# vgextend /dev/vg_var /dev/sdb
  Volume group "vg_var" successfully extended
```

Создаем LV для кэша

```shell
[root@lvm vagrant]# lvcreate --type cache-pool vg_var/cache01 -L 100M /dev/sdb
  Logical volume "cache01" created.

```

Привязываем кэш к нужному lv


```shell
[root@lvm vagrant]# lvconvert --type cache vg_var/lv_var --cachepool /dev/vg_var/cache01
Do you want wipe existing metadata of cache pool vg_var/cache01? [y/n]: y


  Logical volume vg_var/lv_var is now cached.
[root@lvm vagrant]# lvs
  LV          VG         Attr       LSize   Pool      Origin         Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00    VolGroup00 -wi-ao----   8.00g                                                                 
  LogVol01    VolGroup00 -wi-ao----   1.50g                                                                 
  LogVol_Home VolGroup00 -wi-ao----   2.00g                                                                 
  lv_var      vg_var     Cwi-aoC--- 952.00m [cache01] [lv_var_corig] 0.56   0.73            0.00  
```

Кэш создался


А теперь уберем кэш

```shell
[root@lvm vagrant]# lvconvert --uncache /dev/vg_var/lv_var 
  Logical volume "cache01" successfully removed
  Logical volume vg_var/lv_var is not cached.

```
Проверяем, что кэша больше нет 


```shell
[root@lvm vagrant]# lvs --segments -v
  LV          VG         Attr       Start SSize   #Str Type   Stripe Chunk
  LogVol00    VolGroup00 -wi-ao----    0    8.00g    1 linear     0     0 
  LogVol01    VolGroup00 -wi-ao----    0    1.50g    1 linear     0     0 
  LogVol_Home VolGroup00 -wi-ao----    0    2.00g    1 linear     0     0 
  lv_var      vg_var     rwi-aor---    0  952.00m    2 raid1      0     0 

[root@lvm vagrant]# lsblk
NAME                       MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                          8:0    0   40G  0 disk 
├─sda1                       8:1    0    1M  0 part 
├─sda2                       8:2    0    1G  0 part /boot
└─sda3                       8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00    253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01    253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol_Home 253:8    0    2G  0 lvm  /home
sdb                          8:16   0   10G  0 disk 
sdc                          8:32   0    2G  0 disk 
├─vg_var-lv_var_rmeta_0    253:2    0    4M  0 lvm  
│ └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_0   253:3    0  952M  0 lvm  
  └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
sdd                          8:48   0    1G  0 disk 
├─vg_var-lv_var_rmeta_1    253:4    0    4M  0 lvm  
│ └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_1   253:5    0  952M  0 lvm  
  └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
sde                          8:64   0    1G  0 disk 

```

ФИНИШ
