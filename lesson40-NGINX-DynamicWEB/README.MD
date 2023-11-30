# Lesson40 - NGINX -Dynamic WEB

## Цели домашнего задания

Получить практические навыки в настройке инфраструктуры с помощью манифестов и конфигураций. Отточить навыки использования ansible/vagrant/docker.

### Описание домашнего задания

Варианты стенда:
nginx + php-fpm (laravel/wordpress) + python (flask/django) + js(react/angular);
nginx + java (tomcat/jetty/netty) + go + ruby;
можно свои комбинации.
Реализации на выбор:
на хостовой системе через конфиги в /etc;
деплой через docker-compose.
Для усложнения можно попросить проекты у коллег с курсов по разработке
К сдаче принимается:
vagrant стэнд с проброшенными на локалхост портами
каждый порт на свой сайт
через нжинкс Формат сдачи ДЗ - vagrant + ansible

##  Выполнение

Так как тема для меня с одной стороны знакомая, а с другой стороны nginx  я знаю на 3 с минусом, выберу вариант как в методичке

### Nginx + php-fpm (laravel/wordpress) + python (flask/django) + js(react/angular) с деплоем через docker-compose


Как обычно создадим тестовую машинку через vagrant

```shell

# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES=[
  {
    :hostname => "web",
    :ip => "192.168.56.10",
    :box_name => "debian/bullseye64"
  }
]

Vagrant.configure(2) do |config|
    MACHINES.each do |machine|
        config.vm.define machine[:hostname] do |node|
            node.vm.box = machine[:box_name]
            node.vm.hostname = machine[:hostname]
            node.vm.network "private_network", ip: machine[:ip]
            node.vm.provider "virtualbox" do |v|
              v.memory = 4096
            end
            # node.vm.provision "ansible" do |ansible|
            #   ansible.playbook = "web.yml"
            #   ansible.tags = "all"
            # end
        end
    end
end


```
### Соберем сначала кусочек на wordpress так попроще отладка

 - Готовим конфиг урезанный nginx.conf

```
# Данный сервер отвечает за проксирование на wordpress через fastcgi
server {
# Wordpress будет отображаться на 8083 порту хоста
        listen 8083;
        listen [::]:8083;
        server_name localhost;
        index index.php index.html index.htm;

# Задаем корень корень проекта, куда мы смонтировали статику wordpress
        root /var/www/html;
        location ~ /.well-known/acme-challenge {
                allow all;
                root /var/www/html;
        }
        location / {
                try_files $uri $uri/ /index.php$is_args$args;
        }
# Само fastcgi проксирование в контейнер с wordpress по 9000 порту
        location ~ \.php$ {
                try_files $uri =404;
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_pass wordpress:9000;
                fastcgi_index index.php;
                include fastcgi_params;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_param PATH_INFO $fastcgi_path_info;
        }

        location = /favicon.ico {
                log_not_found off; access_log off;
        }

        location ~* \.(css|gif|ico|jpeg|jpg|js|png)$ {
                expires max;
                log_not_found off;
        }
}

```
- Docker-compose

```shell
version: "3"
    
services:

  database:
    image: mysql:8.0
    container_name: database
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: ${DB_NAME}
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
    volumes:
      - ./dbdata:/var/lib/mysql
    command: '--default-authentication-plugin=mysql_native_password'
    networks:
      - app-network

  wordpress:
    image: wordpress:5.1.1-fpm-alpine # официальный образ от разработчиков
    container_name: wordpress
    restart: unless-stopped
# на странице образа в docker hub написано, какие можно задать переменные контейнеру https://hub.docker.com/_/wordpress
    environment:
      WORDPRESS_DB_HOST: database
      WORDPRESS_DB_NAME: "${DB_NAME}" # Также импортируем переменные из .env
      WORDPRESS_DB_USER: root
      WORDPRESS_DB_PASSWORD: "${DB_ROOT_PASSWORD}"
    volumes:
      - ./wordpress:/var/www/html # сохраняем приложение на хост машине
    networks:
      - app-network
    depends_on:
      - database # контейнер wordpress дождется запуска БД

 


  nginx:
    image: nginx:1.15.12-alpine
    container_name: nginx
    restart: unless-stopped
# Т.к. все запросы к приложениям будут проходить через nginx, пробросим под каждое приложение по порту.
    ports:
      - 8083:8083
      - 8081:8081
      - 8082:8082
    volumes:
# будет использоваться php-fpm, необходимо смонтировать статические файлы wordpress :
      - ./wordpress:/var/www/html
      - ./nginx-conf:/etc/nginx/conf.d # монтируем конфиг
    networks:
      - app-network
    depends_on: # nginx будет запускаться после всех приложений
      - wordpress
    ##  - app
    ##  - node


networks:
  app-network:
    driver: bridge


```

.env

```shell

DB_NAME=wordpress 
DB_ROOT_PASSWORD=dbpassword 
# Переменные необходимые python приложению
MYSITE_SECRET_KEY=put_your_django_app_secret_key_here
DEBUG=True



```

- Ansible-playbook


```shell

---
##Set timezone
- name: set timezone
  shell: timedatectl set-timezone Europe/Moscow

# - name: Install EPEL Repo package from standard repo
#   yum:
#     name: epel-release
#     state: present

#Install Chrony to time Sync

- name: Synchronize datetime | Install chrony
  yum:
    name: chrony
    state: latest
  tags:
    - chrony-datesync

#Enable Chrony Services to time Sync

- name: Synchronize datetime | Turn on chronyd
  service:
    name: chronyd
    enabled: yes
    state: started
  notify:
    - systemctl daemon reload
  tags:
    - chrony-datesync


- name: Install docker packages # устанавливаем пакеты необходимые для установки докера
  become: true
  apt:
    name: "{{ item }}"
    state: present
    update_cache: yes
  with_items:
    - apt-transport-https
    - ca-certificates
    - curl
    - software-properties-common
    - gpg
  tags:
    - docker

- name: Add Docker GPG key
  apt_key:
    url: https://download.docker.com/linux/debian/gpg

- name: Add Docker APT repository
  apt_repository:
    repo: deb [arch=amd64] https://download.docker.com/{{ ansible_system | lower }}/{{ ansible_distribution | lower }} {{ ansible_distribution_release }} stable

- name: Install Docker CE
  apt:
    name: ['docker-ce', 'docker-ce-cli', 'containerd.io']
    update_cache: yes

- name: Install prerequisites for docker-compose
  apt:
    name: ['python3-pip', 'python3-setuptools', 'virtualenv']

- name: Install docker-compose
  pip:
    name: docker-compose

# - name: Add Docker s official GPG key
#   become: true
#   apt_key:
#     url: https://download.docker.com/linux/ubuntu/gpg
#     state: present
#   tags:
#     - docker

# - name: Verify that we have the key with the fingerprint
#   become: true   
#   apt_key:
#     id: 0EBFCD88
#     state: present
#   tags:
#     - docker

# - name: Set up the stable repository # добавляем репозиторий докера
#   become: true    
#   apt_repository:
#     repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable
#     state: present
#     update_cache: yes
#   tags:
#     - docker
  
# - name: Update apt packages
#   become: true    
#   apt:
#     update_cache: yes
#   tags:
#     - docker

# - name: Install docker # установка докера
#   become: true    
#   apt:
#     name: docker-ce
#     state: present
#     update_cache: yes
#   tags:
#     - docker

- name: Add remote "vagrant" user to "docker" group
  become: true
  user:
    name: vagrant
    group: "docker"
    append: yes
  tags:
    - docker

- name: Install docker-compose 
  become: true
  get_url:
    url : https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-linux-x86_64
    dest: /usr/local/bin/docker-compose
    mode: 0777

- name: Copy project # Копируем проект с хост машины в созданную через vagrant
  copy: 
    src: "../files/project"
    dest: /home/vagrant

- name: reset ssh connection # чтобы применились права на использование docker, необходимо перелогиниться
  meta: reset_connection

- name: Run container
  shell:
    cmd: "docker-compose -f docker-compose.yml up -d"
    chdir: /home/vagrant/project


```

- Запускаем


```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson40-NGINX-DynamicWEB/vm/ansible$ ansible-playbook playbooks/allweb.yml 

PLAY [install laravel/django/react] ***********************************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************************************************
[WARNING]: Platform linux on host web is using the discovered Python interpreter at /usr/bin/python3, but future installation of another Python interpreter could change this. See
https://docs.ansible.com/ansible/2.9/reference_appendices/interpreter_discovery.html for more information.
ok: [web]

TASK [../roles/allweb : set timezone] *********************************************************************************************************************************************************************
changed: [web]

TASK [../roles/allweb : Synchronize datetime | Install chrony] ********************************************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
ok: [web]

TASK [../roles/allweb : Synchronize datetime | Turn on chronyd] *******************************************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
ok: [web]

TASK [../roles/allweb : Install docker packages] **********************************************************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
ok: [web] => (item=['apt-transport-https', 'ca-certificates', 'curl', 'software-properties-common', 'gpg'])

TASK [../roles/allweb : Add Docker GPG key] ***************************************************************************************************************************************************************
ok: [web]

TASK [../roles/allweb : Add Docker APT repository] ********************************************************************************************************************************************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
ok: [web]

TASK [../roles/allweb : Install Docker CE] ****************************************************************************************************************************************************************
ok: [web]

TASK [../roles/allweb : Install prerequisites for docker-compose] *****************************************************************************************************************************************
ok: [web]

TASK [../roles/allweb : Install docker-compose] ***********************************************************************************************************************************************************
ok: [web]

TASK [../roles/allweb : Add remote "vagrant" user to "docker" group] **************************************************************************************************************************************
ok: [web]

TASK [../roles/allweb : Install docker-compose] ***********************************************************************************************************************************************************
ok: [web]

TASK [../roles/allweb : Copy project] *********************************************************************************************************************************************************************
changed: [web]

TASK [../roles/allweb : Run container] ********************************************************************************************************************************************************************
changed: [web]

PLAY RECAP ************************************************************************************************************************************************************************************************
web                        : ok=14   changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

```


 - Проверяем

```shell




root@web:/home/vagrant/project# ss -tulpn
Netid            State             Recv-Q            Send-Q                       Local Address:Port                       Peer Address:Port           Process                                             
udp              UNCONN            0                 0                                127.0.0.1:323                             0.0.0.0:*               users:(("chronyd",pid=367,fd=5))                   
udp              UNCONN            0                 0                                  0.0.0.0:68                              0.0.0.0:*               users:(("dhclient",pid=1029,fd=9))                 
udp              UNCONN            0                 0                                    [::1]:323                                [::]:*               users:(("chronyd",pid=367,fd=6))                   
tcp              LISTEN            0                 4096                               0.0.0.0:8081                            0.0.0.0:*               users:(("docker-proxy",pid=28557,fd=4))            
tcp              LISTEN            0                 4096                               0.0.0.0:8082                            0.0.0.0:*               users:(("docker-proxy",pid=28527,fd=4))            
tcp              LISTEN            0                 4096                               0.0.0.0:8083                            0.0.0.0:*               users:(("docker-proxy",pid=28502,fd=4))            
tcp              LISTEN            0                 128                                0.0.0.0:22                              0.0.0.0:*               users:(("sshd",pid=584,fd=3))                      
tcp              LISTEN            0                 4096                                  [::]:8081                               [::]:*               users:(("docker-proxy",pid=28563,fd=4))            
tcp              LISTEN            0                 4096                                  [::]:8082                               [::]:*               users:(("docker-proxy",pid=28536,fd=4))            
tcp              LISTEN            0                 4096                                  [::]:8083                               [::]:*               users:(("docker-proxy",pid=28511,fd=4))            
tcp              LISTEN            0                 128                                   [::]:22                                 [::]:*               users:(("sshd",pid=584,fd=4))                      
root@web:/home/vagrant/project# curl 127.0.0.1:8083
root@web:/home/vagrant/project# docker ps
CONTAINER ID   IMAGE                        COMMAND                  CREATED          STATUS          PORTS                                                                   NAMES
5072d9cd1957   nginx:1.15.12-alpine         "nginx -g 'daemon of…"   22 minutes ago   Up 22 minutes   80/tcp, 0.0.0.0:8081-8083->8081-8083/tcp, :::8081-8083->8081-8083/tcp   nginx
0e3bdcc1de69   wordpress:5.1.1-fpm-alpine   "docker-entrypoint.s…"   22 minutes ago   Up 22 minutes   9000/tcp                                                                wordpress
13df5a92c0d1   mysql:8.0                    "docker-entrypoint.s…"   22 minutes ago   Up 22 minutes   3306/tcp, 33060/tcp                                                     database


```


### Работает - удивительно что с первого раза все получилось.

Картинка с web 192.168.56.10:8083 - в папке images проекта


## Далее добавляем

- django и node конфиг  nginx

```shell

# Данный сервер отвечает за проксирование на wordpress через fastcgi
server {
# Wordpress будет отображаться на 8083 порту хоста
        listen 8083;
        listen [::]:8083;
        server_name localhost;
        index index.php index.html index.htm;

# Задаем корень корень проекта, куда мы смонтировали статику wordpress
        root /var/www/html;
        location ~ /.well-known/acme-challenge {
                allow all;
                root /var/www/html;
        }
        location / {
                try_files $uri $uri/ /index.php$is_args$args;
        }
# Само fastcgi проксирование в контейнер с wordpress по 9000 порту
        location ~ \.php$ {
                try_files $uri =404;
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_pass wordpress:9000;
                fastcgi_index index.php;
                include fastcgi_params;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_param PATH_INFO $fastcgi_path_info;
        }

        location = /favicon.ico {
                log_not_found off; access_log off;
        }

        location ~* \.(css|gif|ico|jpeg|jpg|js|png)$ {
                expires max;
                log_not_found off;
        }
}


upstream django {
  server app:8000;
}
server {
# Django будет отображаться на 8081 порту хоста
   listen 8081;
   listen [::]:8081;   
   server_name localhost;
  location / {
    try_files $uri @proxy_to_app;
  }
# тут используем обычное проксирование в контейнер django
  location @proxy_to_app {
    proxy_pass http://django;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_redirect off;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Host $server_name;
  }
}


# Node.js будет отображаться на 8082 порту хоста
server {
   listen 8082;
   listen [::]:8082;   
   server_name localhost;
  location / {
    proxy_pass http://node:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_redirect off;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Host $server_name;
  }
}


```


- Изменяем  docker-compose


```shell

version: "3"
    
services:

  database:
    image: mysql:8.0
    container_name: database
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: ${DB_NAME}
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
    volumes:
      - ./dbdata:/var/lib/mysql
    command: '--default-authentication-plugin=mysql_native_password'
    networks:
      - app-network

  wordpress:
    image: wordpress:5.1.1-fpm-alpine # официальный образ от разработчиков
    container_name: wordpress
    restart: unless-stopped
# на странице образа в docker hub написано, какие можно задать переменные контейнеру https://hub.docker.com/_/wordpress
    environment:
      WORDPRESS_DB_HOST: database
      WORDPRESS_DB_NAME: "${DB_NAME}" # Также импортируем переменные из .env
      WORDPRESS_DB_USER: root
      WORDPRESS_DB_PASSWORD: "${DB_ROOT_PASSWORD}"
    volumes:
      - ./wordpress:/var/www/html # сохраняем приложение на хост машине
    networks:
      - app-network
    depends_on:
      - database # контейнер wordpress дождется запуска БД

  app:
    build: ./python # для нашего приложения нужны зависимости, поэтому собираем свой образ 
    container_name: app
    restart: always
    env_file:
      - .env # импортируем в контейнер переменные из .env
    command:
      "gunicorn --workers=2 --bind=0.0.0.0:8000 mysite.wsgi:application" # команда для запуска django проекта, приложение будет работать на 8000 порту контейнера
    networks:
      - app-network


  node:
    image: node:16.13.2-alpine3.15
    container_name: node
    working_dir: /opt/server # переназначим рабочую директорию для удобства
    volumes:
      - ./node:/opt/server # пробрасываем приложение в директорию контейнера
    command: node test.js # запуск приложения
    networks:
      - app-network


  nginx:
    image: nginx:1.15.12-alpine
    container_name: nginx
    restart: unless-stopped
# Т.к. все запросы к приложениям будут проходить через nginx, пробросим под каждое приложение по порту.
    ports:
      - 8083:8083
      - 8081:8081
      - 8082:8082
    volumes:
# будет использоваться php-fpm, необходимо смонтировать статические файлы wordpress :
      - ./wordpress:/var/www/html
      - ./nginx-conf:/etc/nginx/conf.d # монтируем конфиг
    networks:
      - app-network
    depends_on: # nginx будет запускаться после всех приложений
      - wordpress
      - app
      - node


networks:
  app-network:
    driver: bridge




```

- Создаем файл проекта django и node.js


```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson40-NGINX-DynamicWEB/vm/ansible$ tree
.
├── ansible.cfg
├── inventories
│   └── hosts
├── playbooks
│   └── allweb.yml
└── roles
    └── allweb
        ├── files
        │   └── project
        │       ├── docker-compose.yml
        │       ├── nginx-conf
        │       │   └── nginx.conf
        │       ├── node
        │       │   └── test.js
        │       └── python
        │           ├── Dockerfile
        │           ├── manage.py
        │           ├── mysite
        │           │   ├── settings.py
        │           │   ├── urls.py
        │           │   └── wsgi.py
        │           └── requirements.txt
        ├── handlers
        │   └── main.yml
        ├── tasks
        │   └── main.yml
        └── vars
            └── main.yml

```


- Перезапускаем ansible-playbook и проверяем


```shell

root@web:/home/vagrant/project# docker ps
CONTAINER ID   IMAGE                        COMMAND                  CREATED          STATUS          PORTS                                                                   NAMES
5072d9cd1957   nginx:1.15.12-alpine         "nginx -g 'daemon of…"   22 minutes ago   Up 22 minutes   80/tcp, 0.0.0.0:8081-8083->8081-8083/tcp, :::8081-8083->8081-8083/tcp   nginx
0e3bdcc1de69   wordpress:5.1.1-fpm-alpine   "docker-entrypoint.s…"   22 minutes ago   Up 22 minutes   9000/tcp                                                                wordpress
13df5a92c0d1   mysql:8.0                    "docker-entrypoint.s…"   22 minutes ago   Up 22 minutes   3306/tcp, 33060/tcp                                                     database
root@web:/home/vagrant/project# docker ps
CONTAINER ID   IMAGE                        COMMAND                  CREATED          STATUS          PORTS                                                                   NAMES
c1c00d953d58   nginx:1.15.12-alpine         "nginx -g 'daemon of…"   2 minutes ago    Up 2 minutes    80/tcp, 0.0.0.0:8081-8083->8081-8083/tcp, :::8081-8083->8081-8083/tcp   nginx
a53379096954   node:16.13.2-alpine3.15      "docker-entrypoint.s…"   2 minutes ago    Up 2 minutes                                                                            node
77d267cfa046   project-app                  "gunicorn --workers=…"   2 minutes ago    Up 2 minutes                                                                            app
0e3bdcc1de69   wordpress:5.1.1-fpm-alpine   "docker-entrypoint.s…"   28 minutes ago   Up 27 minutes   9000/tcp                                                                wordpress
13df5a92c0d1   mysql:8.0                    "docker-entrypoint.s…"   28 minutes ago   Up 27 minutes   3306/tcp, 33060/tcp                                                     database



oot@web:/home/vagrant/project# ss -tilnp
State             Recv-Q            Send-Q                       Local Address:Port                       Peer Address:Port            Process                                                             
LISTEN            0                 4096                               0.0.0.0:8081                            0.0.0.0:*                users:(("docker-proxy",pid=31810,fd=4))
	 cubic cwnd:10            
LISTEN            0                 4096                               0.0.0.0:8082                            0.0.0.0:*                users:(("docker-proxy",pid=31789,fd=4))
	 cubic cwnd:10            
LISTEN            0                 4096                               0.0.0.0:8083                            0.0.0.0:*                users:(("docker-proxy",pid=31769,fd=4))
	 cubic cwnd:10            
LISTEN            0                 128                                0.0.0.0:22                              0.0.0.0:*                users:(("sshd",pid=584,fd=3))
	 cubic cwnd:10                      
LISTEN            0                 4096                                  [::]:8081                               [::]:*                users:(("docker-proxy",pid=31817,fd=4))
	 cubic cwnd:10            
LISTEN            0                 4096                                  [::]:8082                               [::]:*                users:(("docker-proxy",pid=31795,fd=4))
	 cubic cwnd:10            
LISTEN            0                 4096                                  [::]:8083                               [::]:*                users:(("docker-proxy",pid=31774,fd=4))
	 cubic cwnd:10            
LISTEN            0                 128                                   [::]:22                                 [::]:*                users:(("sshd",pid=584,fd=4))
	 cubic cwnd:10                      


```

- Проверяем

node.js  - работает

Картинка с web 192.168.56.10:8082 - в папке images проекта 


Djangо - проект отобразился с ошибкой.

Картинка с web 192.168.56.10:8081 - в папке images проекта 


А с localhost все хорошо, ищем где запрет


```shell


root@web:/home/vagrant/project# curl localhost:8081

<!doctype html>

<html>
    <head>
        <meta charset="utf-8">
        <title>Django: the Web framework for perfectionists with deadlines.</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="stylesheet" type="text/css" href="/static/admin/css/fonts.css">
        <style type="text/css">
          body, main {
            margin: 0 auto;
          }
          .body, .tip {
            stroke: #fff;
          }
          html {
            line-height: 1.15;
            -ms-text-size-adjust: 100%;



```

Разрешение кому можно ходить указывается в settings.py нужно поправить ALLOWED_HOSTS=['192.168.56.10',]


## Итоговая проверка


```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson40-NGINX-DynamicWEB/vm$ vagrant destroy -f
==> web: Forcing shutdown of VM...
==> web: Destroying VM and associated drives...
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson40-NGINX-DynamicWEB/vm$ vagrant up
Bringing machine 'web' up with 'virtualbox' provider...
==> web: Importing base box 'debian/bullseye64'...
==> web: Matching MAC address for NAT networking...
==> web: Checking if box 'debian/bullseye64' version '11.20231009.1' is up to date...
==> web: Setting the name of the VM: vm_web_1701357253421_65370
==> web: Clearing any previously set network interfaces...
==> web: Preparing network interfaces based on configuration...
    web: Adapter 1: nat
    web: Adapter 2: hostonly
==> web: Forwarding ports...
    web: 22 (guest) => 2222 (host) (adapter 1)
==> web: Running 'pre-boot' VM customizations...
==> web: Booting VM...
==> web: Waiting for machine to boot. This may take a few minutes...
    web: SSH address: 127.0.0.1:2222
    web: SSH username: vagrant
    web: SSH auth method: private key
    web: 
    web: Vagrant insecure key detected. Vagrant will automatically replace
    web: this with a newly generated keypair for better security.
    web: 
    web: Inserting generated public key within guest...
    web: Removing insecure key from the guest if it's present...
    web: Key inserted! Disconnecting and reconnecting using new SSH key...
==> web: Machine booted and ready!
==> web: Checking for guest additions in VM...
    web: The guest additions on this VM do not match the installed version of
    web: VirtualBox! In most cases this is fine, but in rare cases it can
    web: prevent things such as shared folders from working properly. If you see
    web: shared folder errors, please make sure the guest additions within the
    web: virtual machine match the version of VirtualBox you have installed on
    web: your host and reload your VM.
    web: 
    web: Guest Additions Version: 6.0.0 r127566
    web: VirtualBox Version: 6.1
==> web: Setting hostname...
==> web: Configuring and enabling network interfaces...
==> web: Mounting shared folders...
    web: /vagrant => /home/sincere/vagrantdocs/lesson40-NGINX-DynamicWEB/vm
==> web: Running provisioner: ansible...
Vagrant gathered an unknown Ansible version:


and falls back on the compatibility mode '1.8'.

Alternatively, the compatibility mode can be specified in your Vagrantfile:
https://www.vagrantup.com/docs/provisioning/ansible_common.html#compatibility_mode

    web: Running ansible-playbook...

PLAY [install laravel/django/react] ********************************************

TASK [Gathering Facts] *********************************************************
[WARNING]: Platform linux on host web is using the discovered Python
interpreter at /usr/bin/python3, but future installation of another Python
interpreter could change this. See https://docs.ansible.com/ansible/2.9/referen
ce_appendices/interpreter_discovery.html for more information.
ok: [web]

TASK [../roles/allweb : set timezone] ******************************************
changed: [web]

TASK [../roles/allweb : Synchronize datetime | Install chrony] *****************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-
packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot
import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-
packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot
import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
ok: [web]

TASK [../roles/allweb : Synchronize datetime | Turn on chronyd] ****************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-
packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot
import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-
packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot
import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
ok: [web]

TASK [../roles/allweb : Install docker packages] *******************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-
packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot
import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-
packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot
import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[DEPRECATION WARNING]: Invoking "apt" only once while using a loop via 
squash_actions is deprecated. Instead of using a loop to supply multiple items 
and specifying `name: "{{ item }}"`, please use `name: ['apt-transport-https', 
'ca-certificates', 'curl', 'software-properties-common', 'gpg']` and remove the
 loop. This feature will be removed in version 2.11. Deprecation warnings can 
be disabled by setting deprecation_warnings=False in ansible.cfg.
changed: [web] => (item=['apt-transport-https', 'ca-certificates', 'curl', 'software-properties-common', 'gpg'])

TASK [../roles/allweb : Add Docker GPG key] ************************************
changed: [web]

TASK [../roles/allweb : Add Docker APT repository] *****************************
[WARNING]: Skipping plugin (/usr/lib/python3/dist-
packages/ansible/plugins/filter/core.py) as it seems to be invalid: cannot
import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
[WARNING]: Skipping plugin (/usr/lib/python3/dist-
packages/ansible/plugins/filter/mathstuff.py) as it seems to be invalid: cannot
import name 'environmentfilter' from 'jinja2.filters'
(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
changed: [web]

TASK [../roles/allweb : Install Docker CE] *************************************
changed: [web]

TASK [../roles/allweb : Install prerequisites for docker-compose] **************
changed: [web]

TASK [../roles/allweb : Install docker-compose] ********************************
changed: [web]

TASK [../roles/allweb : Add remote "vagrant" user to "docker" group] ***********
changed: [web]

TASK [../roles/allweb : Install docker-compose] ********************************
changed: [web]

TASK [../roles/allweb : Copy project] ******************************************
changed: [web]

TASK [../roles/allweb : Run container] *****************************************
changed: [web]

PLAY RECAP *********************************************************************
web                        : ok=14   changed=11   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   


==> web: Machine 'web' has a post `vagrant up` message. This is a message
==> web: from the creator of the Vagrantfile, and not from Vagrant itself:
==> web: 
==> web: Vanilla Debian box. See https://app.vagrantup.com/debian for help and bug reports
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson40-NGINX-DynamicWEB/vm$ 


```

### Проверил, все работает в точм числе django - свежую картинку приложил.

# Задание выполнено.

Спасибо, за проверку.