# Домашнее задание - Ansible

Первые шаги с Ansible
Описание/Пошаговая инструкция выполнения домашнего задания:

Для выполнения домашнего задания используйте методичку
https://drive.google.com/file/d/1CKknAPX-Ixnl4ClluCSbQQFne0PMsHBU/view?usp=share_link
Что нужно сделать?
Подготовить стенд на Vagrant как минимум с одним сервером. На этом сервере используя Ansible необходимо развернуть nginx со следующими условиями:

    необходимо использовать модуль yum/apt;
    конфигурационные файлы должны быть взяты из шаблона jinja2 с перемененными;
    после установки nginx должен быть в режиме enabled в systemd;
    должен быть использован notify для старта nginx после установки;
    сайт должен слушать на нестандартном порту - 8080, для этого использовать переменные в Ansible.



Подготовить стенд на Vagrant как минимум с одним сервером. На этом
сервере используя Ansible необходимо развернуть nginx со следующими
условиями:
- необходимо использовать модуль yum/apt
- конфигурационные файлы должны быть взяты из шаблона jinja2 с
переменными
- после установки nginx должен быть в режиме enabled в systemd
- должен быть использован notify для старта nginx после установки
- сайт должен слушать на нестандартном порту - 8080, для этого использовать
переменные в Ansible
* Сделать все это с использованием Ansible роли
Домашнее задание считается принятым, если:
- предоставлен Vagrantfile и готовый playbook/роль ( инструкция по запуску
стенда, если посчитаете необходимым )
- после запуска стенда nginx доступен на порту 8080
- при написании playbook/роли соблюдены перечисленные в задании условия



## Выполнение домашнего задания

1. Подготовить стенд на Vagrant как минимум с одним сервером. 


Создадим каталог Ansible
```shell
mkdir Ansible
cd Ansible
vagrant init
```

Поместим в Vagrantfile следующий конфиг

```shell

# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
  :nginx => {
        :box_name => "centos/7",
        :ip_addr => '192.168.56.150'
  }
}

Vagrant.configure("2") do |config|

  MACHINES.each do |boxname, boxconfig|

      config.vm.define boxname do |box|

          box.vm.box = boxconfig[:box_name]
          box.vm.host_name = boxname.to_s

          box.vm.network "private_network", ip: boxconfig[:ip_addr]

          box.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--memory", "200"]
          end
          
          box.vm.provision "shell", inline: <<-SHELL
            mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
            sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
            systemctl restart sshd
          SHELL

      end
  end
end

```

Запустим командой 

```shell

vagrant up

```
Для подключения к хосту nginx нам необходимо будет передать множество
параметров - это особенность Vagrant. Узнать эти параметры можно с
помощью команды vagrant ssh-config. Вот основные необходимые нам:


```shell 
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson12/Ansible$ vagrant ssh-config
Host nginx
  HostName 127.0.0.1
  User vagrant
  Port 2222
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile /home/sincere/vagrantdocs/lesson12/Ansible/.vagrant/machines/nginx/virtualbox/private_key
  IdentitiesOnly yes
  LogLevel FATAL
  PubkeyAcceptedKeyTypes +ssh-rsa
  HostKeyAlgorithms +ssh-rsa

```

Установим и проверим версию Ansible

```shell
apt install ansible


sincere@sincere-ubuntuotus:~/vagrantdocs/lesson12/Ansible$ ansible --version
ansible 2.9.6
  config file = /etc/ansible/ansible.cfg
  configured module search path = ['/home/sincere/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3/dist-packages/ansible
  executable location = /bin/ansible
  python version = 3.8.10 (default, May 26 2023, 14:05:08) [GCC 9.4.0]

```


Создадим inventory файл hosts в каталоге inventories

```shell
mkdir inventories
cd inventories

touch hosts

[web]
nginx ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_private_key_file=.vagrant/machines/nginx/virtualbox/private_key


```

Проверим что можем управлять хостом

```shell
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson12/Ansible$ ansible nginx -i inventories/hosts -m ping
The authenticity of host '[127.0.0.1]:2222 ([127.0.0.1]:2222)' can't be established.
ECDSA key fingerprint is SHA256:BcJZQfZK/8dXHuUhNWsnEjK/8xYW04gW6vJSaJ8Cl0s.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
nginx | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}

```

Создадим в каталоге Ansible файл конфигурации  ansible.cfg

[defaults]
inventory = inventories/hosts
remote_user = vagrant
host_key_checking = False
retry_files_enabled = False



Из hosts уберем ansible_user=vagrant 



Проверим конфигурацию

```shell
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson12/Ansible$ ansible nginx -m ping
nginx | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}


```

Работает  - продолжаем


ansible nginx -m command -a "uname -r"
ansible nginx -m systemd -a name=firewalld
ansible nginx -m yum -a "name=epel-release state=present" -b

Вывод команды 

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson12/Ansible$ ansible nginx -m command -a "uname -r"
nginx | CHANGED | rc=0 >>
3.10.0-1127.el7.x86_64
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson12/Ansible$ ansible nginx -m systemd -a name=firewalld
nginx | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "name": "firewalld",
    "status": {
        "ActiveEnterTimestampMonotonic": "0",
        "ActiveExitTimestampMonotonic": "0",
        "ActiveState": "inactive",
        "After": "system.slice basic.target polkit.service dbus.service",
        "AllowIsolate": "no",
        "AmbientCapabilities": "0",
        "AssertResult": "no",
        "AssertTimestampMonotonic": "0",
        "Before": "network-pre.target shutdown.target",
        "BlockIOAccounting": "no",
        "BlockIOWeight": "18446744073709551615",
        "BusName": "org.fedoraproject.FirewallD1",
        "CPUAccounting": "no",
        "CPUQuotaPerSecUSec": "infinity",
        "CPUSchedulingPolicy": "0",


```


Создадим playbook

В создадим каталог playbooks

В файле simple.yml

```yaml

---
  - name: Install EPEL Repo
    hosts: nginx
    become: true
    tasks:
    - name: Install EPEL Repo package from standard repo
      yum:
        name: epel-release
        state: present


```

Вывод

```shell
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson12/Ansible$ ansible-playbook playbooks/simple.yml

PLAY [Install EPEL Repo] ******************************************************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************************************
ok: [nginx]

TASK [Install EPEL Repo package from standard repo] ***************************************************************************************************************************************************************
ok: [nginx]

PLAY RECAP ********************************************************************************************************************************************************************************************************
nginx                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

```


Создадим отдельный каталог ansible_roles и начнем писать playbooks roles

Создадим первоначальную структуру

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson12/Ansible/ansible_roles$ tree
.
├── ansible.cfg
├── inventories
│   └── hosts
├── playbooks
│   └── nginx.yml
└── roles

Добавим  в nginx.yml структуру


---
- name: NGINX | Install and configure NGINX
  hosts: nginx
  become: true
  
  tasks:
    - name: NGINX | Install EPEL Repo package from standart repo
      yum:
        name: epel-release
        state: present
      tags:
        - epel-package
        - packages

    - name: NGINX | Install NGINX package from EPEL Repo
      yum:
        name: nginx
        state: latest
      tags:
        - nginx-package
        - packages
      


sincere@sincere-ubuntuotus:~/vagrantdocs/lesson12/Ansible/ansible_roles$ ansible-playbook playbooks/nginx.yml --list-tags

playbook: playbooks/nginx.yml

  play #1 (nginx): NGINX | Install and configure NGINX	TAGS: []
      TASK TAGS: [epel-package, nginx-package, packages]

```


Запустим только установку NGINX:

```shell
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson12/Ansible$ ansible-playbook ansible_roles/playbooks/nginx.yml -t nginx-package

PLAY [NGINX | Install and configure NGINX] ************************************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************************************
ok: [nginx]

TASK [NGINX | Install NGINX package from EPEL Repo] ***************************************************************************************************************************************************************
changed: [nginx]

PLAY RECAP ********************************************************************************************************************************************************************************************************
nginx                      : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   


```
Так как методичка неожиданно обрывается, дальше пытаемся используя видео с урока, гугл и богатое воображение пересобрать все в роли


Распределим части playbook в такую структуру


```shell




```shell
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson12/Ansible$ tree ansible_roles/
ansible_roles/
├── ansible.cfg
├── inventories
│   └── hosts
├── playbook_nginx.yml
├── roles
│   └── nginx
│       ├── handlers
│       │   └── main.yml
│       ├── tasks
│       │   └── main.yml
│       ├── templates
│       │   └── nginx.conf.j2
│       └── vars
│           └── main.yml
└── Vagrantfile

7 directories, 8 files


hosts

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson12/Ansible/ansible_roles$ cat ./inventories/hosts 
[web]
nginx ansible_host=127.0.0.1 ansible_port=2222 ansible_private_key_file=.vagrant/machines/nginx/virtualbox/private_key

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson12/Ansible$ cat ansible_roles/playbook_nginx.yml 
---
- name: NGINX | Install and configure NGINX
  hosts: nginx
  become: true
  
  tasks:
    - name: NGINX | Install EPEL Repo package from standart repo
      yum:
        name: epel-release
        state: present
      tags:
        - epel-package
        - packages

    - name: NGINX | Install NGINX package from EPEL Repo
      yum:
        name: nginx
        state: latest
      tags:
        - nginx-package
        - packages


sincere@sincere-ubuntuotus:~/vagrantdocs/lesson12/Ansible/ansible_roles$ cat roles/nginx/handlers/main.yml 
---
- name: start nginx
  systemd:
    name: nginx
    state: started
    enabled: yes
    
- name: restart nginx
  systemd:
    name: nginx
    state: restarted
    enabled: yes

- name: reload nginx
  systemd:
    name: nginx
    state: reloaded

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson12/Ansible/ansible_roles$ cat roles/nginx/tasks/main.yml 
---
- name: NGINX | Install EPEL Repo package from standart repo
  yum:
    name: epel-release
    state: present
  tags:
    - epel-package
    - packages

- name: NGINX | Install NGINX package from EPEL Repo
  yum:
    name: nginx
    state: latest
  tags:
    - nginx-package
    - packages
  notify:
  - start nginx

- name: Replace nginx.conf
  template:
    src=../templates/nginx.conf.j2
    dest=/etc/nginx/nginx.conf
  tags:
    - nginx-configuration
    - packages
  notify:
    - reload nginx


    sincere@sincere-ubuntuotus:~/vagrantdocs/lesson12/Ansible/ansible_roles$ cat roles/nginx/templates/nginx.conf.j2 
{# ansible_managed #}
events {
    worker_connections 1024;
}

http {
    server {
        listen       {{ nginx_listen_port }} default_server;
        server_name  default_server;
        root         /usr/share/nginx/html;

        location / {
        }
    }
}


sincere@sincere-ubuntuotus:~/vagrantdocs/lesson12/Ansible/ansible_roles$ cat roles/nginx/vars/main.yml 
---
  nginx_listen_port: 8080


Также копируем наш ранее написанный ansible.cfg

```
 
Пробуем выполнить чистую установку


```shell

cd ansible_roles
vagrant up

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson12/Ansible/ansible_roles$ ansible-playbook playbook_nginx.yml

PLAY [Role config] ************************************************************************************************************************************************************************************************

TASK [nginx : NGINX | Install EPEL Repo package from standart repo] ***********************************************************************************************************************************************
changed: [nginx]

TASK [nginx : NGINX | Install NGINX package from EPEL Repo] *******************************************************************************************************************************************************
changed: [nginx]

TASK [nginx : Replace nginx.conf] *********************************************************************************************************************************************************************************
changed: [nginx]

TASK [nginx : NGINX | Create my own page] *************************************************************************************************************************************************************************
changed: [nginx]

RUNNING HANDLER [nginx : start nginx] *****************************************************************************************************************************************************************************
changed: [nginx]

RUNNING HANDLER [nginx : reload nginx] ****************************************************************************************************************************************************************************
changed: [nginx]

PLAY RECAP ********************************************************************************************************************************************************************************************************
nginx                      : ok=6    changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   


```

Выполнено успешно

Проверим доступность порта и http страницы

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson12/Ansible/ansible_roles$ curl http://192.168.56.150:8080
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

```

Выполнено!!


Небольшой доп в тасках - замена дефолтной страницы

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson12/Ansible/ansible_roles$ curl http://192.168.56.150:8080
Sincere


Частично описание и репозиторий могут не совпадать, так как выполнены многочисленные правки, чтобы заставить код работать!





