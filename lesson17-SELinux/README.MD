# Домашнее задание   - Практика с SELinux


## Цель:

Тренируем умение работать с SELinux: диагностировать проблемы и модифицировать политики SELinux для корректной работы приложений, если это требуется;

Описание/Пошаговая инструкция выполнения домашнего задания:

Для выполнения домашнего задания используйте методичку
https://docs.google.com/document/d/1QwyccIn8jijBKdaoNR4DCtTULEqb5MKK/edit?usp=share_link&ouid=104106368295333385634&rtpof=true&sd=true
Что нужно сделать?

    Запустить nginx на нестандартном порту 3-мя разными способами:

    переключатели setsebool;
    добавление нестандартного порта в имеющийся тип;
    формирование и установка модуля SELinux.
    К сдаче:
    README с описанием каждого решения (скриншоты и демонстрация приветствуются).

    Обеспечить работоспособность приложения при включенном selinux.

    развернуть приложенный стенд https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems;
    выяснить причину неработоспособности механизма обновления зоны (см. README);
    предложить решение (или решения) для данной проблемы;
    выбрать одно из решений для реализации, предварительно обосновав выбор;
    реализовать выбранное решение и продемонстрировать его работоспособность.
    К сдаче:
    README с анализом причины неработоспособности, возможными способами решения и обоснованием выбора одного из них;
    исправленный стенд или демонстрация работоспособной системы скриншотами и описанием.
    В чат ДЗ отправьте ссылку на ваш git-репозиторий. Обычно мы проверяем ДЗ в течение 48 часов.
    Если возникнут вопросы, обращайтесь к студентам, преподавателям и наставникам в канал группы в Telegram.
    Удачи при выполнении!

## Описание ДЗ

1. Запустить nginx на нестандартном порту 3 способами


1. Создадим Vagrantfile


```shell

# -*- mode: ruby -*-
# vim: set ft=ruby :


MACHINES = {
  :selinux => {
        :box_name => "centos/7",
        :box_version => "2004.01",
        #:provision => "test.sh",       
  },
}


Vagrant.configure("2") do |config|


  MACHINES.each do |boxname, boxconfig|


      config.vm.define boxname do |box|


        box.vm.box = boxconfig[:box_name]
        box.vm.box_version = boxconfig[:box_version]


        box.vm.host_name = "selinux"
        box.vm.network "forwarded_port", guest: 4881, host: 4881


        box.vm.provider :virtualbox do |vb|
              vb.customize ["modifyvm", :id, "--memory", "1024"]
              needsController = false
        end


        box.vm.provision "shell", inline: <<-SHELL
          #install epel-release
          yum install -y epel-release
          #install nginx
          yum install -y nginx
          #change nginx port
          sed -ie 's/:80/:4881/g' /etc/nginx/nginx.conf
          sed -i 's/listen       80;/listen       4881;/' /etc/nginx/nginx.conf
          #disable SELinux
          #setenforce 0
          #start nginx
          systemctl start nginx
          systemctl status nginx
          #check nginx port
          ss -tlpn | grep 4881
        SHELL
    end
  end
end


```
Запускаем VM

```shell
vagrant up

...
    selinux: Complete!
    selinux: Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
    selinux: ● nginx.service - The nginx HTTP and reverse proxy server
    selinux:    Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
    selinux:    Active: failed (Result: exit-code) since Sun 2023-09-03 11:45:21 UTC; 18ms ago
    selinux:   Process: 2891 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
    selinux:   Process: 2890 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    selinux: 
    selinux: Sep 03 11:45:21 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
    selinux: Sep 03 11:45:21 selinux nginx[2891]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    selinux: Sep 03 11:45:21 selinux nginx[2891]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
    selinux: Sep 03 11:45:21 selinux nginx[2891]: nginx: configuration file /etc/nginx/nginx.conf test failed
    selinux: Sep 03 11:45:21 selinux systemd[1]: nginx.service: control process exited, code=exited status=1
    selinux: Sep 03 11:45:21 selinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
    selinux: Sep 03 11:45:21 selinux systemd[1]: Unit nginx.service entered failed state.
    selinux: Sep 03 11:45:21 selinux systemd[1]: nginx.service failed.
The SSH command responded with a non-zero exit status. Vagrant
assumes that this means the command failed. The output for this command
should be in the log above. Please read the output to determine what
went wrong.
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson17-SELinux/Part1-nginx$ 

```


``` shell

vagrant ssh

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson17-SELinux/Part1-nginx$ vagrant ssh
[vagrant@selinux ~]$ sudo -i
[root@selinux ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)
[root@selinux ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@selinux ~]# getenforce
Enforcing



```

FW отключен, конфигурация правильная, selinux включен

```shell

[root@selinux ~]# grep 4881 /var/log/audit/audit.log
type=AVC msg=audit(1693741521.736:833): avc:  denied  { name_bind } for  pid=2891 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
[root@selinux ~]# 

```

audit2why отсутствовал в системе и необходимо доустановить пакет selinux-policy



```shell
Installed:
  selinux-policy-minimum.noarch 0:3.13.1-268.el7_9.2                                                     

Dependency Installed:
  audit-libs-python.x86_64 0:2.8.5-4.el7                checkpolicy.x86_64 0:2.5-8.el7                   
  libcgroup.x86_64 0:0.41-21.el7                        libsemanage-python.x86_64 0:2.5-14.el7           
  policycoreutils-python.x86_64 0:2.5-34.el7            python-IPy.noarch 0:0.75-6.el7                   
  setools-libs.x86_64 0:3.3.8-4.el7                    

Complete!
[root@selinux ~]# grep 4881 /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1693741521.736:833): avc:  denied  { name_bind } for  pid=2891 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

	Was caused by:
	The boolean nis_enabled was set incorrectly. 
	Description:
	Allow nis to enabled

	Allow access by executing:
	# setsebool -P nis_enabled 1


```

Предлагает отключить nis

```shell 
setsebool -P nis_enabled 1
systemctl start nginx 
curl 127.0.0.1:4881


[root@selinux ~]# setsebool -P nis_enabled 1
[root@selinux ~]# systemctl start nginx 
[root@selinux ~]# curl 127.0.0.1:4881
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <title>Welcome to CentOS</title>
  <style rel="stylesheet" type="text/css"> 

	html {
	background-image:url(img/html-background.png);
	background-color: white;
	font-family: "DejaVu Sans", "Liberation Sans", sans-serif;
	font-size: 0.85em;
	line-height: 1.25em;
	margin: 0 4% 0 4%;
	}

	body {
	border: 10px solid #fff;
	margin:0;
	padding:0;


```
Работает, вернем назад


```shell
[root@selinux ~]# setsebool -P nis_enabled 0
[root@selinux ~]# getsebool -a | grep nis_enabled
nis_enabled --> off


Посмотрим какие порты по умолчанию разрешены для http


[root@selinux ~]# semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989

Добавим в группу нестандартных портов порт tcp 4881

[root@selinux ~]# semanage port -a -t  http_port_t -p tcp 4881
[root@selinux ~]# systemctl start nginx 
[root@selinux ~]# systemctl restart nginx 
[root@selinux ~]# curl 127.0.0.1:4881
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <title>Welcome to CentOS</title>
  <style rel="stylesheet" type="text/css"> 

	html {
	background-image:url(img/html-background.png);
	background-color: white;


```
Работает , возвращаем  как было


```shell

[root@selinux ~]# semanage port -d -t http_port_t -p tcp 4881

[root@selinux ~]# semanage port -l | grep  http_port_t
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988

Порт убрали


```

Рассмотрим третий вариант


```shell

[root@selinux ~]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
[root@selinux ~]# systemctl start nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
[root@selinux ~]# grep nginx /var/log/audit/audit.log
type=SOFTWARE_UPDATE msg=audit(1693741520.976:831): pid=2756 uid=0 auid=1000 ses=2 subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 msg='sw="nginx-filesystem-1:1.20.1-10.el7.noarch" sw_type=rpm key_enforce=0 gpg_res=1 root_dir="/" comm="yum" exe="/usr/bin/python2.7" hostname=? addr=? terminal=? res=success'
type=SOFTWARE_UPDATE msg=audit(1693741521.408:832): pid=2756 uid=0 auid=1000 ses=2 subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 msg='sw="nginx-1:1.20.1-10.el7.x86_64" sw_type=rpm key_enforce=0 gpg_res=1 root_dir="/" comm="yum" exe="/usr/bin/python2.7" hostname=? addr=? terminal=? res=success'
type=AVC msg=audit(1693741521.736:833): avc:  denied  { name_bind } for  pid=2891 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0


[root@selinux ~]# grep nginx /var/log/audit/audit.log | audit2allow -M nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i nginx.pp

[root@selinux ~]# ls -la
total 44
dr-xr-x---.  3 root root  181 сен  3 12:06 .
dr-xr-xr-x. 18 root root  255 сен  3 11:44 ..
-rw-------.  1 root root 5570 апр 30  2020 anaconda-ks.cfg
-rw-r--r--.  1 root root   18 дек 29  2013 .bash_logout
-rw-r--r--.  1 root root  176 дек 29  2013 .bash_profile
-rw-r--r--.  1 root root  176 дек 29  2013 .bashrc
-rw-r--r--.  1 root root  100 дек 29  2013 .cshrc
-rw-r--r--.  1 root root  960 сен  3 12:06 nginx.pp
-rw-r--r--.  1 root root  257 сен  3 12:06 nginx.te
-rw-------.  1 root root 5300 апр 30  2020 original-ks.cfg
drwxr-----.  3 root root   19 сен  3 11:45 .pki
-rw-r--r--.  1 root root  129 дек 29  2013 .tcshrc


[root@selinux ~]# cat nginx.pp
��|���|�SE Linux Modulnginx1.0@
tcp_socket	name_binobject_r@@@@@unreserved_port_t@httpd_t@@@@@@@@@@@@@@@@@@@@@@@@@@
tcp_sockeobject_runreserved_port_thttpd_t

[root@selinux ~]# cat nginx.te

module nginx 1.0;

require {
	type httpd_t;
	type unreserved_port_t;
	class tcp_socket name_bind;
}

#============= httpd_t ==============

#!!!! This avc can be allowed using the boolean 'nis_enabled'
allow httpd_t unreserved_port_t:tcp_socket name_bind;
[root@selinux ~]# 


Применим сгенерированный скрипт

[root@selinux ~]# semodule -i nginx.pp
[root@selinux ~]# systemctl start nginx
[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Вс 2023-09-03 12:10:06 UTC; 7s ago
  Process: 14653 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 14651 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 14650 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 14655 (nginx)
   CGroup: /system.slice/nginx.service
           ├─14655 nginx: master process /usr/sbin/nginx
           └─14656 nginx: worker process

сен 03 12:10:06 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
сен 03 12:10:06 selinux nginx[14651]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
сен 03 12:10:06 selinux nginx[14651]: nginx: configuration file /etc/nginx/nginx.conf test is s...sful
сен 03 12:10:06 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
Hint: Some lines were ellipsized, use -l to show in full.
[root@selinux ~]# 

Справочно список всех модулей для selinux
[root@selinux ~]# semodule -l
abrt	1.4.1
accountsd	1.1.0
acct	1.6.0
afs	1.9.0
aiccu	1.1.0
aide	1.7.1

Удалить ранее установленный модуль semodule -r nginx

[root@selinux ~]# semodule -r nginx
libsemanage.semanage_direct_remove_key: Removing last nginx module (no other nginx module exists at another priority).




```



## Part 2 Поиск ошибки в dns


Устанавливаем стенд


```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson17-SELinux$ mkdir Part2-dns
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson17-SELinux$ cd Part2-dns/
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson17-SELinux/Part2-dns$ git clone https://github.com/mbfx/otus-linux-adm.git
Cloning into 'otus-linux-adm'...
remote: Enumerating objects: 558, done.
remote: Counting objects: 100% (456/456), done.
remote: Compressing objects: 100% (303/303), done.
remote: Total 558 (delta 125), reused 396 (delta 74), pack-reused 102
Receiving objects: 100% (558/558), 1.38 MiB | 4.15 MiB/s, done.
Resolving deltas: 100% (140/140), done.
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson17-SELinux/Part2-dns$ ls
otus-linux-adm
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson17-SELinux/Part2-dns$ cd otus-linux-adm/
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson17-SELinux/Part2-dns/otus-linux-adm$ ls
dhcp_dns_demo         dynamic_routing_guideline  terraform-proxmox
drbd_stand_demo       pacemaker_vbox_stand_demo  vpn_tunnels_demo
dynamic_routing_demo  selinux_dns_problems       vpn_tunnels_demo_2
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson17-SELinux/Part2-dns/otus-linux-adm$  cd selinux_dns_problems/
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson17-SELinux/Part2-dns/otus-linux-adm/selinux_dns_problems$ vagrant up
Bringing machine 'ns01' up with 'virtualbox' provider...
Bringing machine 'client' up with 'virtualbox' provider...
==> ns01: Importing base box 'centos/7'...
==> ns01: Matching MAC address for NAT networking...
==> ns01: Checking if box 'centos/7' version '2004.01' is up to date...
==> ns01: Setting the name of the VM: selinux_dns_problems_ns01_1693744359865_1693
==> ns01: Fixed port collision for 22 => 2222. Now on port 2200.
==> ns01: Clearing any previously set network interfaces...
==> ns01: Preparing network interfaces based on configuration...
    ns01: Adapter 1: nat

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson17-SELinux/Part2-dns/otus-linux-adm/selinux_dns_problems$ vagrant status
Current machine states:

ns01                      running (virtualbox)
client                    running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.

```
Подключимся к клиенту: vagrant ssh client


    ns01 - DNS-сервер (192.168.50.10);
    client - клиентская рабочая станция (192.168.50.15).

При попытке с рабочей станции внести изменения в зону ddns.lab происходит ошибка:

```shell

[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10etc
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
>


```

На клиенте выполним

cat /var/log/audit/audit.log | audit2why

```shell

cat /var/log/audit/audit.log | audit2why
ошибок нет

```
На сервере

```shell

[root@ns01 ~]# cat /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1693745316.366:1945): avc:  denied  { create } for  pid=5131 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0

	Was caused by:
		Missing type enforcement (TE) allow rule.

		You can use audit2allow to generate a loadable module to allow this access.

[root@ns01 ~]# 

```

Видим ошибку контекста etc_t


Проверим что вообще в каталоге /etc/named

```shell
[root@ns01 ~]# ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:etc_t:s0       .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:etc_t:s0   dynamic
-rw-rw----. root named system_u:object_r:etc_t:s0       named.50.168.192.rev
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab.view1
-rw-rw----. root named system_u:object_r:etc_t:s0       named.newdns.lab
                          all files          system_u:object_r:named_cache_t:s0 

```

Проверим что по умолчанию записывает selinux


```shell
 [root@ns01 ~]# semanage fcontext -l | grep /etc/named
/etc/named\.rfc1912.zones                          regular file       system_u:object_r:named_conf_t:s0 
/var/named/chroot/etc/named\.rfc1912.zones         regular file       system_u:object_r:named_conf_t:s0 
/etc/named\.conf                                   regular file       system_u:object_r:named_conf_t:s0 
/etc/named\.root\.hints                            regular file       system_u:object_r:named_conf_t:s0 
/var/named/chroot/etc/named\.conf                  regular file       system_u:object_r:named_conf_t:s0 
/etc/named\.caching-nameserver\.conf               regular file       system_u:object_r:named_conf_t:s0 
/var/named/chroot/etc/named\.root\.hints           regular file       system_u:object_r:named_conf_t:s0 
/var/named/chroot/etc/named\.caching-nameserver\.conf regular file       system_u:object_r:named_conf_t:s0 


```

По идее нужно добавить 

/etc/named/*                                   regular file       system_u:object_r:named_conf_t:s0 

Но сначала перезапишем контекст руками как сказано в методичке

```shell
[root@ns01 ~]# ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:etc_t:s0       .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:etc_t:s0   dynamic
-rw-rw----. root named system_u:object_r:etc_t:s0       named.50.168.192.rev
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab.view1
-rw-rw----. root named system_u:object_r:etc_t:s0       named.newdns.lab
[root@ns01 ~]# sudo chcon -R -t named_zone_t /etc/named
[root@ns01 ~]# ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:named_zone_t:s0 .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:named_zone_t:s0 dynamic
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.50.168.192.rev
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab.view1
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.newdns.lab

```

Проверим

```shell
[root@client ~]# nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> quit
[root@client ~]# dig www.ddns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.14 <<>> www.ddns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 54585
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.ddns.lab.			IN	A

;; ANSWER SECTION:
www.ddns.lab.		60	IN	A	192.168.50.15

;; AUTHORITY SECTION:
ddns.lab.		3600	IN	NS	ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.		3600	IN	A	192.168.50.10

;; Query time: 5 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Sun Sep 03 13:06:59 UTC 2023
;; MSG SIZE  rcvd: 96




```
Работает


Восстановим контекст

```shell

[root@ns01 ~]# restorecon -v -R /etc/named
restorecon reset /etc/named context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/named.dns.lab context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/named.dns.lab.view1 context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/dynamic context unconfined_u:object_r:named_zone_t:s0->unconfined_u:object_r:etc_t:s0
restorecon reset /etc/named/dynamic/named.ddns.lab context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/dynamic/named.ddns.lab.view1 context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/named.newdns.lab context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/named.50.168.192.rev context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
[root@ns01 ~]# sudo chcon -R -t named_zone_t /etc/named
[root@ns01 ~]# restorecon -v -R /etc/named
restorecon reset /etc/named context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/named.dns.lab context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/named.dns.lab.view1 context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/dynamic context unconfined_u:object_r:named_zone_t:s0->unconfined_u:object_r:etc_t:s0
restorecon reset /etc/named/dynamic/named.ddns.lab context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/dynamic/named.ddns.lab.view1 context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/dynamic/named.ddns.lab.view1.jnl context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/named.newdns.lab context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/named.50.168.192.rev context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
[root@ns01 ~]# ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:etc_t:s0       .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:etc_t:s0   dynamic
-rw-rw----. root named system_u:object_r:etc_t:s0       named.50.168.192.rev
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab.view1
-rw-rw----. root named system_u:object_r:etc_t:s0       named.newdns.lab



```

Пропишем правильное правило у контекст selinux для каталога и файлов внутри /etc/named

```shell

Правило

[root@ns01 ~]# semanage fcontext -a -t named_zone_t "/etc/named(/.*)?"

Текущее состояние

[root@ns01 ~]# ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:etc_t:s0       .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:etc_t:s0   dynamic
-rw-rw----. root named system_u:object_r:etc_t:s0       named.50.168.192.rev
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab.view1
-rw-rw----. root named system_u:object_r:etc_t:s0       named.newdns.lab


[root@ns01 ~]# semanage fcontext -l | grep /etc/named
/etc/named\.rfc1912.zones                          regular file       system_u:object_r:named_conf_t:s0 
/var/named/chroot/etc/named\.rfc1912.zones         regular file       system_u:object_r:named_conf_t:s0 
/etc/named\.conf                                   regular file       system_u:object_r:named_conf_t:s0 
/etc/named\.root\.hints                            regular file       system_u:object_r:named_conf_t:s0 
/var/named/chroot/etc/named\.conf                  regular file       system_u:object_r:named_conf_t:s0 
/etc/named\.caching-nameserver\.conf               regular file       system_u:object_r:named_conf_t:s0 
/var/named/chroot/etc/named\.root\.hints           regular file       system_u:object_r:named_conf_t:s0 
/var/named/chroot/etc/named\.caching-nameserver\.conf regular file       system_u:object_r:named_conf_t:s0 
/etc/named(/.*)?                                   all files          system_u:object_r:named_zone_t:s0 

Восстановим контекст для каталогов и файлов с учетом ранее добавленного правила



[root@ns01 ~]# restorecon -v -R /etc/named
restorecon reset /etc/named context system_u:object_r:etc_t:s0->system_u:object_r:named_zone_t:s0
restorecon reset /etc/named/named.dns.lab context system_u:object_r:etc_t:s0->system_u:object_r:named_zone_t:s0
restorecon reset /etc/named/named.dns.lab.view1 context system_u:object_r:etc_t:s0->system_u:object_r:named_zone_t:s0
restorecon reset /etc/named/dynamic context unconfined_u:object_r:etc_t:s0->unconfined_u:object_r:named_zone_t:s0
restorecon reset /etc/named/dynamic/named.ddns.lab context system_u:object_r:etc_t:s0->system_u:object_r:named_zone_t:s0
restorecon reset /etc/named/dynamic/named.ddns.lab.view1 context system_u:object_r:etc_t:s0->system_u:object_r:named_zone_t:s0
restorecon reset /etc/named/dynamic/named.ddns.lab.view1.jnl context system_u:object_r:etc_t:s0->system_u:object_r:named_zone_t:s0
restorecon reset /etc/named/named.newdns.lab context system_u:object_r:etc_t:s0->system_u:object_r:named_zone_t:s0
restorecon reset /etc/named/named.50.168.192.rev context system_u:object_r:etc_t:s0->system_u:object_r:named_zone_t:s0

Проверяем

[root@ns01 ~]# ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:named_zone_t:s0 .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:named_zone_t:s0 dynamic
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.50.168.192.rev
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab.view1
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.newdns.lab
[root@ns01 ~]# 

```

Отлично! ДЗ выполнено!
