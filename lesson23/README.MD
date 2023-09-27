# Lesson23 - PAM

## Цель: научиться создавать пользователей и добавлять им ограничения;

## Описание/Пошаговая инструкция выполнения домашнего задания:

Для выполнения домашнего задания используйте методичку
https://docs.google.com/document/d/1lOFe3rv0QcnvOTNfQm0OMHbNQ0Cet6AR/edit?usp=share_link&ouid=104106368295333385634&rtpof=true&sd=true
Что нужно сделать?
Запретить всем пользователям, кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников
Дать конкретному пользователю права работать с докером и возможность рестартить докер сервис*
В чат ДЗ отправьте ссылку на ваш git-репозиторий . Обычно мы проверяем ДЗ в течение 48 часов.
Если возникнут вопросы, обращайтесь к студентам, преподавателям и наставникам в канал группы в Telegram.
Удачи при выполнении!



## Выполнение ДЗ



Создадим Vagrantfile, в котором будут указаны параметры наших ВМ:

```shell
# Описание параметров ВМ
MACHINES = {
  # Имя DV "pam"
  :"pam" => {
              # VM box
              :box_name => "centos/8",
              # Количество ядер CPU
              :cpus => 2,
              # Указываем количество ОЗУ (В Мегабайтах)
              :memory => 1024,
              # Указываем IP-адрес для ВМ
              :ip => "192.168.56.10",
            }
}

Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
    # Отключаем сетевую папку
    config.vm.synced_folder ".", "/vagrant", disabled: true
    # Добавляем сетевой интерфейс
    config.vm.network "private_network", ip: boxconfig[:ip]
    # Применяем параметры, указанные выше
    config.vm.define boxname do |box|
      box.vm.box = boxconfig[:box_name]
      box.vm.box_version = boxconfig[:box_version]
      box.vm.host_name = boxname.to_s

      box.vm.provider "virtualbox" do |v|
        v.memory = boxconfig[:memory]
        v.cpus = boxconfig[:cpus]
      end
      box.vm.provision "shell", inline: <<-SHELL
          #Разрешаем подключение пользователей по SSH с использованием пароля
          sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config
          #Перезапуск службы SSHD
          systemctl restart sshd.service
  	  SHELL
    end
  end
end

```


Пишем скрипт создания пользователей

```shell

# Up the privileges
sudo -i

# Create  the users

sudo useradd otusadmin
echo "test" | sudo passwd otusadmin --stdin

sudo useradd otus
echo "test" | sudo passwd otus --stdin

# Create the groups

sudo groupadd -f admin

# Add users to groups "admin"

usermod otusadmin -aG admin
usermod root -aG admin
usermod vagrant -aG admin


```

<details><summary>Листинг</summary>

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson23$ vagrant ssh
[vagrant@pam ~]$ # Up the privileges
[vagrant@pam ~]$ sudo -i
[root@pam ~]# 
[root@pam ~]# # Create  the users
[root@pam ~]# 
[root@pam ~]# sudo useradd otusadmin
[root@pam ~]# echo "test" | sudo passwd otusadmin --stdin
passwd: Unknown user name 'admin'.
[root@pam ~]# 
[root@pam ~]# sudo useradd otus
[root@pam ~]# echo "test" | sudo passwd otus --stdin
passwd: Unknown user name 'admin'.
[root@pam ~]# 
[root@pam ~]# # Create the groups
[root@pam ~]# 
[root@pam ~]# sudo groupadd -f admin
[root@pam ~]# 
[root@pam ~]# # Add users to groups "admin"
[root@pam ~]# 
[root@pam ~]# usermod otusadmin -aG admin
[root@pam ~]# usermod root -aG admin
[root@pam ~]# usermod vagrant -aG admin
[root@pam ~]# exit
logout
[vagrant@pam ~]$ exit
logout
Connection to 127.0.0.1 closed.
```

</details>

Проверяем что подключились

`
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson23$ ssh otus@192.168.56.10
otus@192.168.56.10's password: 
Permission denied, please try again.
otus@192.168.56.10's password: 
Last failed login: Wed Sep 27 12:18:27 UTC 2023 from 192.168.56.1 on ssh:notty
There were 10 failed login attempts since the last successful login.
[otus@pam ~]$ exit
logout
Connection to 192.168.56.10 closed.
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson23$ ssh otusadmin@192.168.56.10
otusadmin@192.168.56.10's password: 
[otusadmin@pam ~]$ 
`


## настройка правила для PAM


Далее настроим правило, по которому все пользователи кроме тех, что указаны в группе admin не смогут подключаться в выходные дни:

Проверим, что пользователи root, vagrant и otusadm есть в группе admin:

`
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson23$ vagrant ssh
Last login: Wed Sep 27 12:17:20 2023 from 10.0.2.2
[vagrant@pam ~]$ cat /etc/group | grep admin
printadmin:x:994:
otusadmin:x:1001:
admin:x:1003:otusadmin,root,vagrant
`



Выберем метод PAM-аутентификации, так как у нас используется только ограничение по времени, то было бы логично использовать метод pam_time, однако, данный метод не работает с локальными группами пользователей, и, получается, что использование данного метода добавит нам большое количество однообразных строк с разными пользователями. В текущей ситуации лучше написать небольшой скрипт контроля и использовать модуль pam_exec

Создадим файл-скрипт /usr/local/bin/login.sh


```shell
sudo vi /usr/local/bin/login.sh


#!/bin/bash

if [ $(date +%a) = "Sat" ] || [ $(date +%a) = "Sun" ]; then

 if getent group admin | grep -qw "$PAM_USER"; then

        exit 1
      else

        exit 0
    fi

  else
    exit 0
fi

```

В скрипте подписаны все условия. Скрипт работает по принципу: 
Если сегодня суббота или воскресенье, то нужно проверить, входит ли пользователь в группу admin, если не входит — то подключение запрещено. При любых других вариантах подключение разрешено. 

Добавим права на исполнение файла: 

`sudo chmod +x /usr/local/bin/login.sh`

Укажем в файле /etc/pam.d/sshd модуль pam_exec и наш скрипт:

```shell
sudo vi /etc/pam.d/sshd 

[root@pam vagrant]# cat /etc/pam.d/sshd 
#%PAM-1.0
auth       substack     password-auth
auth       include      postlogin
account    required     pam_sepermit.so
account    required     pam_nologin.so
`account	   required     pam_exec.so /usr/local/bin/login.sh`
account    include      password-auth
password   include      password-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open env_params
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    optional     pam_motd.so
session    include      password-auth
session    include      postlogin


# Выполнить рестарт сервиса
sudo systemctl restart sshd


```

На этом настройка завершена, нужно только проверить, что скрипт отрабатывает корректно. 




Поменяем время в нашей ОС  -  30 сент 2023 года (Суббота): 

`sudo date 093012302023.00`

[root@pam vagrant]# sudo date 093012302023.00
Sat Sep 30 12:30:00 UTC 2023


### Проверка


sincere@sincere-ubuntuotus:~/vagrantdocs/lesson23$ ssh otusadmin@192.168.56.10
otusadmin@192.168.56.10's password: 
/usr/local/bin/login.sh failed: exit code 1
Connection closed by 192.168.56.10 port 22
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson23$ ssh otus@192.168.56.10
otus@192.168.56.10's password: 
Last login: Wed Sep 27 12:18:47 2023 from 192.168.56.1
[otusadmin@pam ~]$ date
Sat Sep 30 12:31:42 UTC 2023


Все настроено правильно.


### Итоговый скрипт



```shell
# Описание параметров ВМ
MACHINES = {
  # Имя DV "pam"
  :"pam" => {
              # VM box
              :box_name => "centos/8",
              # Количество ядер CPU
              :cpus => 2,
              # Указываем количество ОЗУ (В Мегабайтах)
              :memory => 1024,
              # Указываем IP-адрес для ВМ
              :ip => "192.168.56.10",
            }
}

Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
    # Отключаем сетевую папку
    config.vm.synced_folder ".", "/vagrant", disabled: true
    # Добавляем сетевой интерфейс
    config.vm.network "private_network", ip: boxconfig[:ip]
    # Применяем параметры, указанные выше
    config.vm.define boxname do |box|
      box.vm.box = boxconfig[:box_name]
      box.vm.box_version = boxconfig[:box_version]
      box.vm.host_name = boxname.to_s

      box.vm.provider "virtualbox" do |v|
        v.memory = boxconfig[:memory]
        v.cpus = boxconfig[:cpus]
      end
      box.vm.provision "shell", inline: <<-SHELL
          #Разрешаем подключение пользователей по SSH с использованием пароля
          sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config
          #Перезапуск службы SSHD
          systemctl restart sshd.service

          # Up the privileges
          sudo -i

          # Create  the users
            sudo useradd otusadmin
            echo "test" | sudo passwd otusadmin --stdin

            sudo useradd otus
            echo "test" | sudo passwd otus --stdin

            # Create the groups

            sudo groupadd -f admin

            # Add users to groups "admin"

            usermod otusadmin -aG admin
            usermod root -aG admin
            #usermod vagrant -aG admin
            # Check a group of users
            cat /etc/group | grep admin

            #create login script
cat >> /usr/local/bin/login.sh << 'EOF'
#!/bin/bash
if [ $(date +%a) = "Sat" ] || [ $(date +%a) = "Sun" ]; then
    if getent group admin | grep -qw "$PAM_USER"; then
        exit 1
    else
        exit 0
    fi
else
    exit 0
fi  
EOF
            #check /usr/local/bin/login.sh
            cat /usr/local/bin/login.sh
            #x privileges
            sudo chmod +x /usr/local/bin/login.sh
            #add string to the /etc/pam.d/sshd 
            echo "account    required     pam_exec.so /usr/local/bin/login.sh" >> /etc/pam.d/sshd
            cat /etc/pam.d/sshd
            #restart ssh
            sudo systemctl restart sshd
            #change the date to saturday 30 sep 2023
            sudo date 093012302023.00
            SHELL
          end
        end
      end        

```

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson23/vagrantfinish$ vagrant up
Bringing machine 'pam' up with 'virtualbox' provider...
==> pam: Importing base box 'centos/8'...
==> pam: Matching MAC address for NAT networking...
==> pam: Checking if box 'centos/8' version '2011.0' is up to date...
==> pam: Setting the name of the VM: vagrantfinish_pam_1695839694328_15198
==> pam: Clearing any previously set network interfaces...
==> pam: Preparing network interfaces based on configuration...
    pam: Adapter 1: nat
    pam: Adapter 2: hostonly
==> pam: Forwarding ports...
    pam: 22 (guest) => 2222 (host) (adapter 1)
==> pam: Running 'pre-boot' VM customizations...
==> pam: Booting VM...
==> pam: Waiting for machine to boot. This may take a few minutes...
    pam: SSH address: 127.0.0.1:2222
    pam: SSH username: vagrant
    pam: SSH auth method: private key
    pam: 
    pam: Vagrant insecure key detected. Vagrant will automatically replace
    pam: this with a newly generated keypair for better security.
    pam: 
    pam: Inserting generated public key within guest...
    pam: Removing insecure key from the guest if it's present...
    pam: Key inserted! Disconnecting and reconnecting using new SSH key...
==> pam: Machine booted and ready!
==> pam: Checking for guest additions in VM...
    pam: No guest additions were detected on the base box for this VM! Guest
    pam: additions are required for forwarded ports, shared folders, host only
    pam: networking, and more. If SSH fails on this machine, please install
    pam: the guest additions and repackage the box to continue.
    pam: 
    pam: This is not an error message; everything may continue to work properly,
    pam: in which case you may ignore this message.
==> pam: Setting hostname...
==> pam: Configuring and enabling network interfaces...
==> pam: Running provisioner: shell...
    pam: Running: inline script
    pam: Changing password for user otusadmin.
    pam: passwd: all authentication tokens updated successfully.
    pam: Changing password for user otus.
    pam: passwd: all authentication tokens updated successfully.
    pam: printadmin:x:994:
    pam: otusadmin:x:1001:
    pam: admin:x:1003:otusadmin,root
    pam: Sat Sep 30 12:30:00 UTC 2023


```


