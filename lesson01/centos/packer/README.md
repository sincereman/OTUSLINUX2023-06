#CREATE Image centos8-kernel6 from http://mirror.linux-ia64.org/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-20230209-boot.iso

Stage 1

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson01/centos/packer$ cat centos.json 
{"builders": [
    {
      "boot_command": [
        "<tab> inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter><wait>"
      ],
      "boot_wait": "10s",
      "disk_size": "10240",
      "export_opts": [
        "--manifest",
        "--vsys",
        "0",
        "--description",
        "{{user `artifact_description`}}",
        "--version",
        "{{user `artifact_version`}}"
      ],
      "guest_os_type": "RedHat_64",
      "http_directory": "http",
      "iso_checksum": "28d1e072099a9d1632070cb7d6a7f544bfe4ef2df37cc7297c0122ace1500ffc",
      "iso_url": "http://mirror.linux-ia64.org/centos/8-stream/isos/x86_64/CentOS-Stream-8-20230612.0-x86_64-boot.iso",
      "name": "{{user `image_name`}}",
      "output_directory": "builds",
      "shutdown_command": "sudo -S /sbin/halt -h -p",
      "shutdown_timeout": "5m",
      "ssh_password": "vagrant",
      "ssh_port": 22,
      "ssh_pty": true,
      "ssh_timeout": "20m",
      "ssh_username": "vagrant",
      "type": "virtualbox-iso",
      "vboxmanage": [
        [
          "modifyvm",
          "{{.Name}}",
          "--memory",
          "1024"
        ],
        [
          "modifyvm",
          "{{.Name}}",
          "--cpus",
          "2"
        ]
      ],
      "vm_name": "packer-centos-vm"
    }
  ],
  "post-processors": [
    {
      "compression_level": "7",
      "output": "centos-{{user `artifact_version`}}-kernel-5-x86_64-Minimal.box",
      "type": "vagrant"
    }
  ],
  "provisioners": [
    {
      "execute_command": "echo 'vagrant'|{{.Vars}} sudo -S -E bash '{{.Path}}'",
      "expect_disconnect": true,
      "override": {
        "{{user `image_name`}}": {
          "scripts": [
            "scripts/stage-1-kernel-update.sh",
            "scripts/stage-2-clean.sh"
          ]
        }
      },
      "pause_before": "20s",
      "start_retry_timeout": "1m",
      "type": "shell"
    }
  ],
  "variables": {
    "artifact_description": "CentOS Stream 8 with kernel 5.x",
    "artifact_version": "8",
    "image_name": "centos-8"
  }
}




Create VM in the packer folders

Change form original config -  actual image from linux repository and hash

Lost "space" in a string output

Provisioners part

Lost password in inline string for sudo
"execute_command": "echo 'vagrant'|{{.Vars}} sudo -S -E bash '{{.Path}}'",

Stage 2

ks.cfg

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson01/centos/packer/http$ cat ks.cfg 
# Подтверждаем лицензионное соглашение
eula --agreed

# Указываем язык нашей ОС
lang en_US.UTF-8
# Раскладка клавиатуры
keyboard us
# Указываем часовой пояс
timezone UTC+3

# Включаем сетевой интерфейс и получаем ip-адрес по DHCP
network --bootproto=dhcp --device=link --activate
# Задаём hostname otus-c8
network --hostname=otus-c8

# Указываем пароль root пользователя
rootpw vagrant
authconfig --enableshadow --passalgo=sha512
# Создаём пользователя vagrant, добавляем его в группу Wheel
user --groups=wheel --name=vagrant --password=vagrant --gecos="vagrant"

# Включаем SELinux в режиме enforcing
selinux --enforcing
# Выключаем штатный межсетевой экран
firewall --disabled

firstboot --disable


#packages

%packages --ignoremissing
#environment
@^minimal-environment
%end

# Выбираем установку в режиме командной строки
text
# Указываем адрес, с которого установщик возьмёт недостающие компоненты
url --url="http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/"

# System bootloader configuration
bootloader --location=mbr --append="ipv6.disable=1 crashkernel=auto"

skipx
logging --level=info
zerombr
clearpart --all --initlabel
# Автоматически размечаем диск, создаём LVM
autopart --type=lvm
# Перезагрузка после установки
reboot


Replace "firewall –-disabled" to "firewall --disabled"



Stage 3

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson01/centos/packer/scripts$ cat stage-1-kernel-update.sh 
#!/bin/bash

# Установка репозитория elrepo



#sudo
echo 'vagrant' | sudo -s yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm 
# Установка нового ядра из репозитория elrepo-kernel
sudo -s
yum --enablerepo elrepo-kernel install kernel-ml -y

# Обновление параметров GRUB
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-set-default 0
echo "Grub update done."
# Перезагрузка ВМ
shutdown -r now



Change kernel 5 to 6 because it`s last core for now.


sincere@sincere-ubuntuotus:~/vagrantdocs/lesson01/centos/packer/scripts$ cat stage-2-clean.sh 
#!/bin/bash

# Обновление и очистка всех ненужных пакетов
yum update -y
yum clean all


# Добавление ssh-ключа для пользователя vagrant
mkdir -pm 700 /home/vagrant/.ssh
curl -sL https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub -o /home/vagrant/.ssh/authorized_keys
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh


# Удаление временных файлов
rm -rf /tmp/*
rm  -f /var/log/wtmp /var/log/btmp
rm -rf /var/cache/* /usr/share/doc/*
rm -rf /var/cache/yum
rm -rf /vagrant/home/*.iso
rm  -f ~/.bash_history
history -c

rm -rf /run/log/journal/*
sync
grub2-set-default 0
echo "###   Hi from second stage" >> /boot/grub2/grub.cfg



The VM cant shutdown  after the second clean scripts - i didnt find a solution
Tried add shutdown -p now in the end of scripts but it crushed the all of process

Solution shut off vm manually
 
Stage 4 

Upload to vagrant cloud and test

Dont forget to change private to cloud for free access



Stage 5 

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson01/centos/packer/scripts$ vagrant box list
centos8-kernel6            (virtualbox, 0)
sincereman/centos8-kernel6 (virtualbox, 1.0)
ubuntu/focal64             (virtualbox, 20230619.0.0)


Stage 6

sincereman/centos8-kernel6:   (v1.0) for provider 'virtualbox'
Automatic Release:     true
Do you wish to continue? [y/N]y
Saving box information...
Uploading provider with file /home/sincere/vagrantdocs/lesson01/centos/packer/centos-8-kernel-6-x86_64-Minimal.box
Releasing box...
Complete! Published sincereman/centos8-kernel6
Box:              sincereman/centos8-kernel6
Description:      
Private:          yes
Created:          2023-06-27T20:18:46.901+03:00
Updated:          2023-06-27T20:18:46.901+03:00
Current Version:  N/A
Versions:         1.0
Downloads:        0




