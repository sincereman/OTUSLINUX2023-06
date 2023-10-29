## Домашнее задание - Backup

Настраиваем бэкапы
Описание/Пошаговая инструкция выполнения домашнего задания:

Для выполнения домашнего задания используйте методичку
https://docs.google.com/document/d/1L0VtVCn2tXmC0Pirlfhnr6rEpOANbP-C/edit?usp=share_link&ouid=104106368295333385634&rtpof=true&sd=true
Что нужно сделать?
Настроить стенд Vagrant с двумя виртуальными машинами: backup_server и client.
Настроить удаленный бекап каталога /etc c сервера client при помощи borgbackup. Резервные копии должны соответствовать следующим критериям:

    директория для резервных копий /var/backup. Это должна быть отдельная точка монтирования. В данном случае для демонстрации размер не принципиален, достаточно будет и 2GB;
    репозиторий дле резервных копий должен быть зашифрован ключом или паролем - на ваше усмотрение;
    имя бекапа должно содержать информацию о времени снятия бекапа;
    глубина бекапа должна быть год, хранить можно по последней копии на конец месяца, кроме последних трех. Последние три месяца должны содержать копии на каждый день. Т.е. должна быть правильно настроена политика удаления старых бэкапов;
    резервная копия снимается каждые 5 минут. Такой частый запуск в целях демонстрации;
    написан скрипт для снятия резервных копий. Скрипт запускается из соответствующей Cron джобы, либо systemd timer-а - на ваше усмотрение;
    настроено логирование процесса бекапа. Для упрощения можно весь вывод перенаправлять в logger с соответствующим тегом. Если настроите не в syslog, то обязательна ротация логов.
    Запустите стенд на 30 минут.
    Убедитесь что резервные копии снимаются.
    Остановите бекап, удалите (или переместите) директорию /etc и восстановите ее из бекапа.
    Для сдачи домашнего задания ожидаем настроенные стенд, логи процесса бэкапа и описание процесса восстановления.
    Формат сдачи ДЗ - vagrant + ansible
    В чат ДЗ отправьте ссылку на ваш git-репозиторий. Обычно мы проверяем ДЗ в течение 48 часов.
    Если возникнут вопросы, обращайтесь к студентам, преподавателям и наставникам в канал группы в Telegram.
    Удачи при выполнении!


## Выполнение.

Prerequistes

Сначала создадим ключ доступа на backupserver



```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson25-Backup/vm/ansible/rsa-key$ ssh-keygen -t rsa -f ./rsa-key
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in ./id_rsa
Your public key has been saved in ./id_rsa.pub
The key fingerprint is:
SHA256:aVRLDHFaaIytVhGpJPqulXnjAB2jCH47IxJ5BlMfDo4 sincere@sincere-ubuntuotus
The key's randomart image is:
+--[RSA 256]--+
|  o .  +=O=      |
| + +..o B*..     |
|E ..=o =o .      |
|o=.o o+. .       |
|+.=o..  S        |
| +..oo .         |
|.. == o          |
|. ..++ .         |
|  ..  .          |
+----[SHA256]-----+


```

Создадим Vagrantfile

```shell

# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
  :dataserver => {
        :box_name => "debian/bullseye64",
        :vm_name => "dataserver",
        :net => [
                   [ "192.168.11.150",  2,  "255.255.255.0",  "backup-net"],
                   #подсеть 192.168.56.0/24 - для связи с vagrant
                   [ "192.168.56.10", 8, "255.255.255.0",    "mgmt"],
                ]
  },
  :backupserver => {
        :box_name => "debian/bullseye64",
        :vm_name => "backupserver",
        :net => [
                   [ "192.168.11.160",  2,  "255.255.255.0",  "backup-net"],
                   [ "192.168.56.11",  8, "255.255.255.0",    "mgmt"],
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

Создадим структуру для ansible


```shell
ansible/
├── ansible.cfg
├── inventories
│   └── hosts
├── playbooks
│   ├── allhosts.yml
│   ├── backupserver.yml
│   └── dataserver.yml
├── roles
│   ├── backupserver
│   │   ├── files
│   │   │   └── backup_borg.pub
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── tasks
│   │   │   └── main.yml
│   │   └── vars
│   │       └── main.yml
│   └── dataserver
│       ├── files
│       │   ├── backup_borg
│       │   ├── borg-backup.service
│       │   ├── borg-backup.sh
│       │   └── borg-backup.timer
│       ├── handlers
│       │   └── main.yml
│       ├── tasks
│       │   └── main.yml
│       └── vars
│           └── main.yml
└── rsa-key
    ├── backup_borg
    └── backup_borg.pub



```

Заполним файл hosts

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson25-Backup/vm$ python3 v2a.py -o ansible/inventories/hosts

```


Заметки - очень долго искал подход к генерации ключей на сервере с дальнейшим переносом на сервер..
В итоге не получалось и решил остановиться на предопределенной паре.


Ниже ansible log

<details><summary> ansible log </summary>

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson25-Backup/vm/ansible$ ansible-playbook playbooks/allhosts.yml 

PLAY [Playbook of "dataserver"] ***********************************************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************************************
[WARNING]: Platform linux on host dataserver is using the discovered Python interpreter at /usr/bin/python3, but future installation of another Python interpreter could change this. See
https://docs.ansible.com/ansible/2.9/reference_appendices/interpreter_discovery.html for more information.
ok: [dataserver]

TASK [../roles/dataserver : set timezone] *************************************************************************************************************************************************************************
changed: [dataserver]

TASK [../roles/dataserver : Synchronize datetime | Install chrony] ************************************************************************************************************************************************
ok: [dataserver]

TASK [../roles/dataserver : Synchronize datetime | Turn on chronyd] ***********************************************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
ok: [dataserver]

TASK [../roles/dataserver : Install borgbackup] *******************************************************************************************************************************************************************
changed: [dataserver]

TASK [../roles/dataserver : Copy publickey for borg] **************************************************************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
changed: [dataserver]

TASK [../roles/dataserver : Copy privatekey for borg] *************************************************************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
changed: [dataserver]

TASK [../roles/dataserver : Config for borg] **********************************************************************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
changed: [dataserver]

TASK [../roles/dataserver : Add Borg Service config] **************************************************************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
changed: [dataserver]

TASK [../roles/dataserver : add default gateway for Routers] ******************************************************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
changed: [dataserver]

TASK [../roles/dataserver : borg-backup] **************************************************************************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
changed: [dataserver]

RUNNING HANDLER [../roles/dataserver : systemctl daemon reload] ***************************************************************************************************************************************************
ok: [dataserver]

PLAY [Playbook of "backupserver"] *********************************************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************************************
[WARNING]: Platform linux on host backupserver is using the discovered Python interpreter at /usr/bin/python3, but future installation of another Python interpreter could change this. See
https://docs.ansible.com/ansible/2.9/reference_appendices/interpreter_discovery.html for more information.
ok: [backupserver]

TASK [../roles/backupserver : set timezone] ***********************************************************************************************************************************************************************
changed: [backupserver]

TASK [../roles/backupserver : Synchronize datetime | Install chrony] **********************************************************************************************************************************************
ok: [backupserver]

TASK [../roles/backupserver : Synchronize datetime | Turn on chronyd] *********************************************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
ok: [backupserver]

TASK [../roles/backupserver : Install borgbackup] *****************************************************************************************************************************************************************
changed: [backupserver]

TASK [../roles/backupserver : Ensure group "borg" exists] *********************************************************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
changed: [backupserver]

TASK [../roles/backupserver : Add the user 'borg' with a primary group of 'borg'] *********************************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
changed: [backupserver]

TASK [../roles/backupserver : Save the user_info, we need them for the home_dir] **********************************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
ok: [backupserver]

TASK [../roles/backupserver : Ensure directory exist] *************************************************************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
changed: [backupserver]

TASK [../roles/backupserver : Ensure directory exist] *************************************************************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
changed: [backupserver]

TASK [../roles/backupserver : Create a file if it does not exist] *************************************************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
changed: [backupserver]

TASK [../roles/backupserver : Copy publickey for borg] ************************************************************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
changed: [backupserver]

TASK [../roles/backupserver : Add authorized_keys strings] ********************************************************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
changed: [backupserver]

PLAY RECAP ********************************************************************************************************************************************************************************************************
backupserver               : ok=13   changed=9    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
dataserver                 : ok=12   changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   



```

</details>


К сожалению придется немного добавить интерактива

Заходим на сервер dataserver и вводим руками команду для первоначальной инициализации и ввода паролей. 
Команду на неинтерактивную парольную фразу не нашел (

```shell    
vagrant ssh dataserver

borg init --encryption=repokey borg@192.168.11.160:/var/backup/

systemctl restart borg-backup
```

В нашем случае парольная фраза 123




```shell


sincere@sincere-ubuntuotus:~/vagrantdocs/lesson25-Backup/vm$ vagrant ssh dataserver
Linux dataserver 5.10.0-26-amd64 #1 SMP Debian 5.10.197-1 (2023-09-29) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Sun Oct 29 22:48:01 2023 from 10.0.2.2
vagrant@dataserver:~$ sudo -s
root@dataserver:/home/vagrant# borg init --encryption=repokey borg@192.168.11.160:/var/backup/
The authenticity of host '192.168.11.160 (192.168.11.160)' can't be established.
ECDSA key fingerprint is SHA256:kMnxTLsiV+kWRi88pvPijua0pOeO7n4bV6Dac4lJgUg.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Remote: Warning: Permanently added '192.168.11.160' (ECDSA) to the list of known hosts.
Enter new passphrase: 
Enter same passphrase again: 
Do you want your passphrase to be displayed for verification? [yN]: n

By default repositories initialized with this version will produce security
errors if written to with an older version (up to and including Borg 1.0.8).

If you want to use these older versions, you can disable the check by running:
borg upgrade --disable-tam ssh://borg@192.168.11.160/var/backup

See https://borgbackup.readthedocs.io/en/stable/changes.html#pre-1-0-9-manifest-spoofing-vulnerability for details about the security implications.

IMPORTANT: you will need both KEY AND PASSPHRASE to access this repo!
Use "borg key export" to export the key, optionally in printable format.
Write down the passphrase. Store both at safe place(s).

root@dataserver:/home/vagrant# systemctl restart borg-backup
root@dataserver:/home/vagrant# systemctl status borg-backup
● borg-backup.service - Automated Borg Backup
     Loaded: loaded (/etc/systemd/system/borg-backup.service; enabled; vendor preset: enabled)
     Active: inactive (dead) since Sun 2023-10-29 22:54:41 MSK; 1s ago
    Process: 5847 ExecStart=/etc/borg-backup.sh (code=exited, status=0/SUCCESS)
   Main PID: 5847 (code=exited, status=0/SUCCESS)
        CPU: 1.850s

Oct 29 22:54:39 dataserver borg-backup.sh[5848]:                        Original size      Compressed size    Deduplicated size
Oct 29 22:54:39 dataserver borg-backup.sh[5848]: This archive:                1.59 MB            641.76 kB            640.18 kB
Oct 29 22:54:39 dataserver borg-backup.sh[5848]: All archives:                1.59 MB            641.76 kB            640.18 kB
Oct 29 22:54:39 dataserver borg-backup.sh[5848]:                        Unique chunks         Total chunks
Oct 29 22:54:39 dataserver borg-backup.sh[5848]: Chunk index:                     401                  410
Oct 29 22:54:39 dataserver borg-backup.sh[5848]: ------------------------------------------------------------------------------
Oct 29 22:54:40 dataserver borg-backup.sh[5854]: dataserver-2023-10-29_22:54:37       Sun, 2023-10-29 22:54:38 [369d642dcd80ebe7c18b12e18d3b57dab1b251de0328f0cb38c6d1fead876ad3]
Oct 29 22:54:41 dataserver systemd[1]: borg-backup.service: Succeeded.
Oct 29 22:54:41 dataserver systemd[1]: Finished Automated Borg Backup.
Oct 29 22:54:41 dataserver systemd[1]: borg-backup.service: Consumed 1.850s CPU time.


root@dataserver:/home/vagrant# systemctl list-timers --all
NEXT                        LEFT          LAST                        PASSED      UNIT                         ACTIVATES
Sun 2023-10-29 23:05:00 MSK 3min 1s left  n/a                         n/a         borg-backup.timer            borg-backup.service
Mon 2023-10-30 00:00:00 MSK 58min left    n/a                         n/a         logrotate.timer              logrotate.service
Mon 2023-10-30 00:00:00 MSK 58min left    n/a                         n/a         man-db.timer                 man-db.service
Mon 2023-10-30 00:18:29 MSK 1h 16min left n/a                         n/a         fstrim.timer                 fstrim.service
Mon 2023-10-30 06:48:28 MSK 7h left       n/a                         n/a         apt-daily-upgrade.timer      apt-daily-upgrade.service
Mon 2023-10-30 16:36:54 MSK 17h left      n/a                         n/a         apt-daily.timer              apt-daily.service
Mon 2023-10-30 22:58:56 MSK 23h left      Sun 2023-10-29 22:58:56 MSK 3min 1s ago systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.service
Sun 2023-11-05 03:10:10 MSK 6 days left   n/a                         n/a         e2scrub_all.timer            e2scrub_all.service

```



Проверим наши бэкапы

```shell

root@dataserver:/home/vagrant# borg list borg@192.168.11.160:/var/backup/
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

root@dataserver:~/restore# borg extract borg@192.168.11.160:/var/backup/::dataserver-2023-10-29_23:05:05 etc/hostname
Enter passphrase for key ssh://borg@192.168.11.160/var/backup: 
root@dataserver:~/restore# ls
etc
root@dataserver:~/restore# ls -la
total 12
drwxr-xr-x 3 root root 4096 Oct 29 23:16 .
drwx------ 6 root root 4096 Oct 29 23:15 ..
drwx------ 2 root root 4096 Oct 29 23:16 etc
root@dataserver:~/restore# cp ./etc/hostname /etc/
root@dataserver:~/restore# cat /etc/hostname 
dataserver
root@dataserver:~/restore# 


```

Работа выполнена.