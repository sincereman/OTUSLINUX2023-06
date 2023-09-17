# Lesson  09 - SystemD

## Домашнее задание

### Systemd - создание unit-файла

Цель:

Научиться редактировать существующие и создавать новые unit-файлы.

Описание/Пошаговая инструкция выполнения домашнего задания:

Для выполнения домашнего задания используйте методичку
Systemd https://drive.google.com/file/d/1yVi3sJjl9maOCN_Z6cUyPj4rzo0CpudR/view?usp=sharing
Выполнить следующие задания и подготовить развёртывание результата выполнения с использованием Vagrant и Vagrant shell provisioner (или Ansible, на Ваше усмотрение):


   1.  Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/sysconfig или в /etc/default).

   2. Установить spawn-fcgi и переписать init-скрипт на unit-файл (имя service должно называться так же: spawn-fcgi).
   
   3. Дополнить unit-файл httpd (он же apache2) возможностью запустить несколько инстансов сервера с разными конфигурационными файлами.


## Описание выполнения домашнего задания


Создадим vagarntfile


```shell

# -*- mode: ruby -*- 
# vi: set ft=ruby : vsa
Vagrant.configure(2) do |config| 
  config.vm.box = "generic/centos8"
  config.vm.box_version = "4.2.16"
  config.vm.provider "virtualbox" do |v| 
      v.memory = 1024 
      v.cpus = 2
  end 
  config.vm.define "systemd" do |systemd| 
    systemd.vm.network "private_network", ip: "192.168.56.10",  virtualbox__intnet: "net1" 
    systemd.vm.hostname = "systemd"
    systemd.vm.provision "shell", path: "lesson09.sh"
  end 
end


```

### Задание 1 
Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/sysconfig или в /etc/default).


Создадим скрипт lesson09.sh

```shell

#!/bin/bash

echo "Create watchlogfile"

cat > /etc/sysconfig/watchlog << EOF
# Configuration file for my watchlog service
# Place it to /etc/sysconfig
# File and word in that file that we will be monit
WORD=ALERT
LOG=/var/log/watchlog.log
EOF

echo "Create a log file"

cat > /var/log/watchlog.log << 'EOF'
String1
String2
ALERT
String3
EOF

echo "Create a script watchlog.sh"

cat > /opt/watchlog.sh << 'EOF'
#!/bin/bash
WORD=$1
LOG=$2
DATE=`date`
if grep $WORD $LOG &> /dev/null
then
logger "$DATE: I found word, Master!"
else
exit 0
fi
EOF

echo "Make an executive"

chmod +x /opt/watchlog.sh


echo "Create a  watchlog.service"

cat > /lib/systemd/system/watchlog.service << 'EOF'
[Unit]
Description=My watchlog service
[Service]
User=root
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG
EOF


echo "Create a  watchlog.timer"

cat >> /lib/systemd/system/watchlog.timer << 'EOF'
[Unit]
Description=Run watchlog script every 30 second
[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service
[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload
systemctl enable watchlog.timer
systemctl start watchlog.timer


```

Запустим VM

```shell

vagrant up && vagrant ssh



```shell

[root@systemd vagrant]# systemctl status watchlog.timer 
● watchlog.timer - Run watchlog script every 30 second
   Loaded: loaded (/usr/lib/systemd/system/watchlog.timer; enabled; vendor preset: disabled)
   Active: active (waiting) since Mon 2023-08-07 14:14:05 UTC; 19min ago
  Trigger: Mon 2023-08-07 14:33:44 UTC; 26s left

Aug 07 14:14:05 systemd systemd[1]: Started Run watchlog script every 30 second.
[root@systemd vagrant]# systemctl status watchlog.service
● watchlog.service - My watchlog service
   Loaded: loaded (/usr/lib/systemd/system/watchlog.service; static; vendor preset: disabled)
   Active: inactive (dead) since Mon 2023-08-07 14:33:14 UTC; 9s ago
  Process: 4305 ExecStart=/opt/watchlog.sh $WORD $LOG (code=exited, status=0/SUCCESS)
 Main PID: 4305 (code=exited, status=0/SUCCESS)

Aug 07 14:33:14 systemd systemd[1]: Starting My watchlog service...


[root@systemd vagrant]# systemctl list-timers 
NEXT                         LEFT          LAST                         PASSED    UNIT                         ACTIVATES
Mon 2023-08-07 14:29:02 UTC  25s left      Mon 2023-08-07 14:28:32 UTC  4s ago    watchlog.timer               watchlog.service
Mon 2023-08-07 14:30:00 UTC  1min 23s left Mon 2023-08-07 14:20:22 UTC  8min ago  sysstat-collect.timer        sysstat-collect.service
Mon 2023-08-07 15:00:00 UTC  31min left    Mon 2023-08-07 14:13:29 UTC  15min ago mlocate-updatedb.timer       mlocate-updatedb.service
Mon 2023-08-07 15:08:10 UTC  39min left    n/a                          n/a       dnf-makecache.timer          dnf-makecache.service
Tue 2023-08-08 00:00:00 UTC  9h left       Mon 2023-08-07 14:13:29 UTC  15min ago unbound-anchor.timer         unbound-anchor.service
Tue 2023-08-08 00:07:00 UTC  9h left       n/a                          n/a       sysstat-summary.timer        sysstat-summary.service
Tue 2023-08-08 14:28:18 UTC  23h left      Mon 2023-08-07 14:28:18 UTC  18s ago   systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.service

7 timers listed.
Pass --all to see loaded but inactive timers, too.
[root@systemd vagrant]# tail -f /var/log/messages 
Aug  7 14:28:01 systemd root[4213]: Mon Aug  7 14:28:01 UTC 2023: I found word, Master!
Aug  7 14:28:01 systemd systemd[1]: watchlog.service: Succeeded.
Aug  7 14:28:01 systemd systemd[1]: Started My watchlog service.
Aug  7 14:28:18 systemd systemd[1]: Starting Cleanup of Temporary Directories...
Aug  7 14:28:18 systemd systemd[1]: systemd-tmpfiles-clean.service: Succeeded.
Aug  7 14:28:18 systemd systemd[1]: Started Cleanup of Temporary Directories.
Aug  7 14:28:32 systemd systemd[1]: Starting My watchlog service...
Aug  7 14:28:32 systemd root[4265]: Mon Aug  7 14:28:32 UTC 2023: I found word, Master!
Aug  7 14:28:32 systemd systemd[1]: watchlog.service: Succeeded.
Aug  7 14:28:32 systemd systemd[1]: Started My watchlog service.
Aug  7 14:29:39 systemd systemd[1]: Starting My watchlog service...
Aug  7 14:29:40 systemd root[4279]: Mon Aug  7 14:29:40 UTC 2023: I found word, Master!
Aug  7 14:29:40 systemd systemd[1]: watchlog.service: Succeeded.
Aug  7 14:29:40 systemd systemd[1]: Started My watchlog service.


```
Выполнено


# Задание 2 
Установить spawn-fcgi и переписать init-скрипт на unit-файл (имя service должно называться так же: spawn-fcgi).

Из репозитория epel установить spawn-fcgi и переписать init-скрипт на unit-файл
Установим необходимый софт...

Дополним наш скрипт lesson09.sh

``` shell

echo "Add package"
yum install -y -q epel-release
yum install -y -q spawn-fcgi php-cli httpd

echo "Add settings  spawn-fcgi..."

echo "OPTIONS=-u apache -g apache -s /var/run/spawn-fcgi/php-fcgi.sock -S -M 0600 -C 32 -F 1 -P /var/run/spawn-fcgi/spawn-fcgi.pid -- /usr/bin/php-cgi" >> /etc/sysconfig/spawn-fcgi

echo "Create Unit-файл for spawn-fcgi..."

cat > /etc/systemd/system/spawn-fcgi.service << 'EOF'
[Unit]
Description=spawn-fcgi
After=syslog.target
[Service]
Type=forking
User=apache
Group=apache
EnvironmentFile=/etc/sysconfig/spawn-fcgi
PIDFile=/var/run/spawn-fcgi/spawn-fcgi.pid
RuntimeDirectory=spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi $OPTIONS
ExecStop=
[Install]
WantedBy=multi-user.target
EOF

echo "Add a right"

chmod 664 /etc/systemd/system/spawn-fcgi.service

echo " Start a service spawn-fcgi.service"

systemctl daemon-reload
systemctl enable --now spawn-fcgi.service
```

Проверим работу сервиса

```shell
vagrant up && vagrant ssh


systemctl status spawn-fcgi.service
```
Вывод

```shell

[root@systemd vagrant]# systemctl status spawn-fcgi.service
● spawn-fcgi.service - spawn-fcgi
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2023-08-07 14:43:40 UTC; 12s ago
  Process: 6823 ExecStart=/usr/bin/spawn-fcgi $OPTIONS (code=exited, status=0/SUCCESS)
 Main PID: 6826 (php-cgi)
    Tasks: 33 (limit: 4951)
   Memory: 18.8M
   CGroup: /system.slice/spawn-fcgi.service
           ├─6826 /usr/bin/php-cgi
           ├─6831 /usr/bin/php-cgi
           ├─6832 /usr/bin/php-cgi
           ├─6833 /usr/bin/php-cgi
           ├─6834 /usr/bin/php-cgi
           ├─6835 /usr/bin/php-cgi
           ├─6836 /usr/bin/php-cgi
           ├─6837 /usr/bin/php-cgi
           ├─6838 /usr/bin/php-cgi
           ├─6839 /usr/bin/php-cgi
           ├─6840 /usr/bin/php-cgi
           ├─6841 /usr/bin/php-cgi
           ├─6842 /usr/bin/php-cgi
           ├─6843 /usr/bin/php-cgi
           ├─6844 /usr/bin/php-cgi
           ├─6845 /usr/bin/php-cgi
           ├─6846 /usr/bin/php-cgi
           ├─6847 /usr/bin/php-cgi
           ├─6848 /usr/bin/php-cgi
           ├─6849 /usr/bin/php-cgi
           ├─6850 /usr/bin/php-cgi
           ├─6851 /usr/bin/php-cgi
           ├─6852 /usr/bin/php-cgi
           ├─6853 /usr/bin/php-cgi
           ├─6854 /usr/bin/php-cgi
           ├─6855 /usr/bin/php-cgi
           ├─6856 /usr/bin/php-cgi
           ├─6857 /usr/bin/php-cgi
           ├─6858 /usr/bin/php-cgi
           ├─6859 /usr/bin/php-cgi
           ├─6860 /usr/bin/php-cgi
           ├─6861 /usr/bin/php-cgi
           └─6862 /usr/bin/php-cgi

Aug 07 14:43:40 systemd systemd[1]: Starting spawn-fcgi...
Aug 07 14:43:40 systemd systemd[1]: Started spawn-fcgi.
```

Выполнено.


### Задание 3 

Дополнить unit-файл httpd (он же apache2) возможностью запустить несколько инстансов сервера с разными конфигурационными файлами.


Как и ранее дополним файл lesson09.sh

```shell

yum -y install httpd

```

Скопируем и откорректируем файл сервиса httpd.service

```shell

cp /usr/lib/systemd/system/httpd.service /etc/systemd/system/httpd@.service
sed -i 's*Environment=LANG=C*Environment=LANG=C\nEnvironmentFile=/etc/sysconfig/httpd-%i*g' /etc/systemd/system/httpd@.service
cat /etc/systemd/system/httpd@.service

```

Вывод

```shell

[root@systemd vagrant]# cat /etc/systemd/system/httpd@.service
# See httpd.service(8) for more information on using the httpd service.

# Modifying this file in-place is not recommended, because changes
# will be overwritten during package upgrades.  To customize the
# behaviour, run "systemctl edit httpd" to create an override unit.

# For example, to pass additional options (such as -D definitions) to
# the httpd binary at startup, create an override unit (as is done by
# systemctl edit) and enter the following:

#	[Service]
#	Environment=OPTIONS=-DMY_DEFINE

[Unit]
Description=The Apache HTTP Server
Wants=httpd-init.service
After=network.target remote-fs.target nss-lookup.target httpd-init.service
Documentation=man:httpd.service(8)

[Service]
Type=notify
Environment=LANG=C
EnvironmentFile=/etc/sysconfig/httpd-%i

ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
# Send SIGWINCH for graceful stop
KillSignal=SIGWINCH
KillMode=mixed
PrivateTmp=true

[Install]
WantedBy=multi-user.target


```
Скопируем и изменим файлы настройки сервиса httpd.service (тут начались сложности.так как оказалось что в RHEL 8 нет файла указанного в методичке))

```shell
cat > /etc/sysconfig/httpd-conf1 << 'EOF'
OPTIONS=-f /etc/httpd/conf/httpd1.conf
EOF

cat > /etc/sysconfig/httpd-conf2 << 'EOF'
OPTIONS=-f /etc/httpd/conf/httpd2.conf
EOF


echo "Copy and settings file  httpd serice "

cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd1.conf
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd2.conf


# Use different ports
sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd1.conf
sed -i 's/Listen 80/Listen 8008/' /etc/httpd/conf/httpd2.conf

# Use different PID

echo "PidFile /var/run/httpd/httpd1.pid" >> /etc/httpd/conf/httpd1.conf
echo "PidFile /var/run/httpd/httpd2.pid" >> /etc/httpd/conf/httpd2.conf

#Запустим два инстанса httpd

#тут сработала защита от нестандартных портов
#поменял на разрешенные 8080 и 8008 так как semanage не хотел срабатывать


systemctl daemon-reload
systemctl enable --now httpd@conf1.service
systemctl enable --now httpd@conf2.service


#Проверим статус сервисов

systemctl status httpd@conf1.service
systemctl status httpd@conf2.service

netstat -tulnp | grep 8080
netstat -tulnp | grep 8008
```

Вывод

```shell
    systemd: Copy and settings file  httpd serice
    systemd: Created symlink /etc/systemd/system/multi-user.target.wants/httpd@conf1.service → /etc/systemd/system/httpd@.service.
    systemd: Created symlink /etc/systemd/system/multi-user.target.wants/httpd@conf2.service → /etc/systemd/system/httpd@.service.
    systemd: ● httpd@conf1.service - The Apache HTTP Server
    systemd:    Loaded: loaded (/etc/systemd/system/httpd@.service; enabled; vendor preset: disabled)
    systemd:    Active: active (running) since Tue 2023-08-08 13:16:01 UTC; 479ms ago
    systemd:      Docs: man:httpd.service(8)
    systemd:  Main PID: 4833 (httpd)
    systemd:    Status: "Started, listening on: port 80"
    systemd:     Tasks: 213 (limit: 4951)
    systemd:    Memory: 24.8M
    systemd:    CGroup: /system.slice/system-httpd.slice/httpd@conf1.service
    systemd:            ├─4833 /usr/sbin/httpd -DFOREGROUND
    systemd:            ├─4835 /usr/sbin/httpd -DFOREGROUND
    systemd:            ├─4836 /usr/sbin/httpd -DFOREGROUND
    systemd:            ├─4837 /usr/sbin/httpd -DFOREGROUND
    systemd:            └─4838 /usr/sbin/httpd -DFOREGROUND
    systemd: 
    systemd: Aug 08 13:16:01 systemd systemd[1]: Starting The Apache HTTP Server...
    systemd: Aug 08 13:16:01 systemd httpd[4833]: AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppress this message
    systemd: Aug 08 13:16:01 systemd systemd[1]: Started The Apache HTTP Server.
    systemd: Aug 08 13:16:01 systemd httpd[4833]: Server configured, listening on: port 80
    systemd: ● httpd@conf2.service - The Apache HTTP Server
    systemd:    Loaded: loaded (/etc/systemd/system/httpd@.service; enabled; vendor preset: disabled)
    systemd:    Active: active (running) since Tue 2023-08-08 13:16:02 UTC; 57ms ago
    systemd:      Docs: man:httpd.service(8)
    systemd:  Main PID: 5071 (httpd)
    systemd:    Status: "Started, listening on: port 8008"
    systemd:     Tasks: 23 (limit: 4951)
    systemd:    Memory: 10.2M
    systemd:    CGroup: /system.slice/system-httpd.slice/httpd@conf2.service
    systemd:            ├─5071 /usr/sbin/httpd -f /etc/httpd/conf/httpd2.conf -DFOREGROUND
    systemd:            ├─5074 /usr/sbin/httpd -f /etc/httpd/conf/httpd2.conf -DFOREGROUND
    systemd:            ├─5076 /usr/sbin/httpd -f /etc/httpd/conf/httpd2.conf -DFOREGROUND
    systemd:            ├─5077 /usr/sbin/httpd -f /etc/httpd/conf/httpd2.conf -DFOREGROUND
    systemd:            └─5078 /usr/sbin/httpd -f /etc/httpd/conf/httpd2.conf -DFOREGROUND
    systemd: 
    systemd: Aug 08 13:16:01 systemd systemd[1]: Starting The Apache HTTP Server...
    systemd: Aug 08 13:16:02 systemd httpd[5071]: AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppress this message
    systemd: Aug 08 13:16:02 systemd systemd[1]: Started The Apache HTTP Server.
    systemd: Aug 08 13:16:02 systemd httpd[5071]: Server configured, listening on: port 8008
    systemd: tcp6       0      0 :::8008                 :::*                    LISTEN      5071/httpd

```
Задание 3 выполнено