# Домашнее задание Lesson18  - Docker, docker-compose, dockerfile


## Цель:

разобраться с основами docker, с образом, эко системой docker в целом;

Описание/Пошаговая инструкция выполнения домашнего задания:

Для выполнения домашнего задания используйте методичку
https://drive.google.com/file/d/1wFCUXKQ-nSGzbShsaNy5M9hWNX4CSeB6/view?usp=share_link
Что нужно сделать?
Описание ДЗ в документе.
В чат ДЗ отправьте ссылку на ваш git-репозиторий. Обычно мы проверяем ДЗ в течение 48 часов.
Если возникнут вопросы, обращайтесь к студентам, преподавателям и наставникам в канал группы в Telegram.
Удачи при выполнении!

Что сделать!  - >>

1. Создайте свой кастомный образ nginx на базе alpine. После запуска nginx должен
отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx)

2. Определите разницу между контейнером и образом

Вывод опишите в домашнем задании.

Ответьте на вопрос: Можно ли в контейнере собрать ядро?

Собранный образ необходимо запушить в docker hub и дать ссылку на ваш
репозиторий.


Задание со * (звездочкой)
Создайте кастомные образы nginx и php, объедините их в docker-compose.
После запуска nginx должен показывать php info.
Все собранные образы должны быть в docker hub

## Описание выполнения ДЗ


Подготовка окружения docker

```shell

sudo apt-get -y remove docker docker-engine docker.io containerd runc
sudo apt-get update
sudo apt-get -y install     apt-transport-https     ca-certificates     curl     gnupg     lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
sudo chmod a+r /usr/share/keyrings/docker-archive-keyring.gpg


echo   "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get -y install docker-ce docker-ce-cli containerd.io

sudo usermod -aG docker $USER
sudo chown $USER /var/run/docker.sock

```

1. Создайте свой кастомный образ nginx на базе alpine. После запуска nginx должен
отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx)



mkdir part1 && cd part1 && touch Dockerfile

Создадим минимальную конфигурацию 
Dockerfile
```shell

FROM alpine:3.14.0
RUN apk add --no-cache nginx

CMD ["nginx", "-g", "daemon off;"]
```


Собираем образ командой

```shell
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson18/part1$ docker build -t nginx_custom_image - < Dockerfile
[+] Building 3.4s (6/6) FINISHED                                                                        docker:default
 => [internal] load build definition from Dockerfile                                                              0.0s
 => => transferring dockerfile: 316B                                                                              0.0s
 => [internal] load .dockerignore                                                                                 0.0s
 => => transferring context: 2B                                                                                   0.0s
 => [internal] load metadata for docker.io/library/alpine:3.14.0                                                  0.5s
 => [1/2] FROM docker.io/library/alpine:3.14.0@sha256:adab3844f497ab9171f070d4cae4114b5aec565ac772e2f2579405b78b  1.1s
 => => resolve docker.io/library/alpine:3.14.0@sha256:adab3844f497ab9171f070d4cae4114b5aec565ac772e2f2579405b78b  0.0s
 => => sha256:adab3844f497ab9171f070d4cae4114b5aec565ac772e2f2579405b78be67c96 1.64kB / 1.64kB                    0.0s
 => => sha256:1775bebec23e1f3ce486989bfc9ff3c4e951690df84aa9f926497d82f2ffca9d 528B / 528B                        0.0s
 => => sha256:d4ff818577bc193b309b355b02ebc9220427090057b54a59e73b79bdfe139b83 1.47kB / 1.47kB                    0.0s
 => => sha256:5843afab387455b37944e709ee8c78d7520df80f8d01cf7f861aae63beeddb6b 2.81MB / 2.81MB                    0.9s
 => => extracting sha256:5843afab387455b37944e709ee8c78d7520df80f8d01cf7f861aae63beeddb6b                         0.1s
 => [2/2] RUN apk add nginx                                                                                       1.7s
 => exporting to image                                                                                            0.0s
 => => exporting layers                                                                                           0.0s
 => => writing image sha256:6b721d304c38d2299d05ce2b872d6766d8dc8bca98c33307d3dc8227dff5e422                      0.0s
 => => naming to docker.io/library/nginx_custom_image  

Запускаем

docker run -d --name nginx_app_container -p 8081:80 nginx_custom_image

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson18/part1$ docker run -d --name nginx_app_container -p 8081:80 nginx_custom_image
73836642a1f621ea8a58f2a92db939b08857170a0ed9fa9a8075cef68813738c



Удаляем

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson18/part1$ docker stop nginx_app_container
nginx_app_container
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson18/part1$ docker rm nginx_app_container
nginx_app_container


```

Создаем структуру для Docker

```shell


sincere@sincere-ubuntuotus:~/vagrantdocs/lesson18/part1$ tree
.
├── Dockerfile
└── page
    ├── default.conf
    └── index.html


sincere@sincere-ubuntuotus:~/vagrantdocs/lesson18/part1$ cat  Dockerfile 
FROM alpine:3.14.0
RUN apk add nginx
#config
COPY ./page/default.conf /etc/nginx/http.d/default.conf
# Страница приветствия сайта
COPY page/index.html /usr/share/nginx/html/
CMD ["nginx", "-g", "daemon off;"]

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson18/part1$ cat page/default.conf 
server {
    listen       8080;
    server_name  localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson18/part1$ cat page/index.html 
<html>
<title>SINCERE OTUS</title>

<body>

    <p>SINCERE OTUS</p>
</body>
</html>
```



Создаем образ

```shell
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson18/part1$ docker build -t nginx_custom_image .
[+] Building 0.6s (9/9) FINISHED                                                                        docker:default
 => [internal] load build definition from Dockerfile                                                              0.0s
 => => transferring dockerfile: 271B                                                                              0.0s
 => [internal] load .dockerignore                                                                                 0.0s
 => => transferring context: 2B                                                                                   0.0s
 => [internal] load metadata for docker.io/library/alpine:3.14.0                                                  0.5s
 => [1/4] FROM docker.io/library/alpine:3.14.0@sha256:adab3844f497ab9171f070d4cae4114b5aec565ac772e2f2579405b78b  0.0s
 => [internal] load build context                                                                                 0.0s
 => => transferring context: 547B                                                                                 0.0s
 => CACHED [2/4] RUN apk add nginx                                                                                0.0s
 => CACHED [3/4] COPY ./page/default.conf /etc/nginx/http.d/default.conf                                          0.0s
 => CACHED [4/4] COPY page/index.html /usr/share/nginx/html/                                                      0.0s
 => exporting to image                                                                                            0.0s
 => => exporting layers                                                                                           0.0s
 => => writing image sha256:8ae8725c90dc81ab58a53ddd926f339537d28ddcfa22d2e3d934dec990dbfb6c                      0.0s
 => => naming to docker.io/library/nginx_custom_image                                                             0.0s


sincere@sincere-ubuntuotus:~/vagrantdocs/lesson18/part1$ docker run -d --name nginx_app_container -p 8080:8080 nginx_custom_image
8ec530c88cf5ae4dfd78cb1daeb2231f54c07e2776088b669d1ae97fda97675e

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson18/part1$ curl 127.0.0.1:8080
<html>
<title>SINCERE OTUS</title>

<body>

    <p>SINCERE OTUS</p>
</body>
</html>

```

Первая часть выполнена!


2. Определите разницу между контейнером и образом

Контейнер - это прежде всего процесс с его аттрибутами (монтированием внешних volume, сети и gh), а образ -  инструкции по сборке окружения ничего не знающий о способах взаимодействия с внешним миром

Вывод опишите в домашнем задании.

Ответьте на вопрос: Можно ли в контейнере собрать ядро?

Можно, но если его не сохранить навнешний volume то при перезапуске он не сохранится.

3. Выгружаем в Docker Hub

```shell 
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson18/part1$ docker tag nginx_custom_image sincereman/otus2023

Авторизоваться  с токеном
docker login



sincere@sincere-ubuntuotus:~/vagrantdocs/lesson18/part1$ docker push sincereman/otus2023
Using default tag: latest
The push refers to repository [docker.io/sincereman/otus2023]
f582de0bc1bc: Pushed 
0e81f307742c: Pushed 
119a5e76f92c: Pushed 
72e830a4dff5: Mounted from library/alpine 
latest: digest: sha256:2aed3ca29bcf3c6101952a090995c25c97f2b8cfb0c0ba74d0e1fe8bc5627609 size: 1153

```

Репозиторий

https://hub.docker.com/r/sincereman/otus2023


***

Docker-Compose


Создаем структуру используя файлы из первой части


sincere@sincere-ubuntuotus:~/vagrantdocs/lesson18/part2$ tree
.
├── docker-compose.yml
└── nginx_custom
    ├── Dockerfile
    └── page
        ├── default.conf
        └── index.html


Добавляем файл docker-compose.yml

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson18/part2$ cat docker-compose.yml 
    version: "3"
    
    services:
      nginx_node:
        image: image_custom_nginx_node
        build: nginx_custom/
        ports:
          - "8080:8080"


sincere@sincere-ubuntuotus:~/vagrantdocs/lesson18/part2$ docker-compose build
Building nginx_node
Step 1/5 : FROM alpine:3.14.0
3.14.0: Pulling from library/alpine
5843afab3874: Already exists
Digest: sha256:adab3844f497ab9171f070d4cae4114b5aec565ac772e2f2579405b78be67c96
Status: Downloaded newer image for alpine:3.14.0
 ---> d4ff818577bc
Step 2/5 : RUN apk add nginx
 ---> Running in 6bda47e7cf3f
fetch https://dl-cdn.alpinelinux.org/alpine/v3.14/main/x86_64/APKINDEX.tar.gz
fetch https://dl-cdn.alpinelinux.org/alpine/v3.14/community/x86_64/APKINDEX.tar.gz
(1/2) Installing pcre (8.44-r0)
(2/2) Installing nginx (1.20.2-r1)
Executing nginx-1.20.2-r1.pre-install
Executing nginx-1.20.2-r1.post-install
Executing busybox-1.33.1-r2.trigger
OK: 7 MiB in 16 packages
Removing intermediate container 6bda47e7cf3f
 ---> d820461e0f3a
Step 3/5 : COPY ./page/default.conf /etc/nginx/http.d/default.conf
 ---> 3b5d932a9820
Step 4/5 : COPY page/index.html /usr/share/nginx/html/
 ---> 30f2d70f77a6
Step 5/5 : CMD ["nginx", "-g", "daemon off;"]
 ---> Running in e942b21c4ee0
Removing intermediate container e942b21c4ee0
 ---> 3f718a136a71
Successfully built 3f718a136a71
Successfully tagged image_custom_nginx_node:latest


sincere@sincere-ubuntuotus:~/vagrantdocs/lesson18/part2$ docker-compose up -d
Starting part2_nginx_node_1 ... done


sincere@sincere-ubuntuotus:~/vagrantdocs/lesson18/part2$ curl localhost:8080
<html>
<title>SINCERE OTUS</title>

<body>

    <p>SINCERE OTUS</p>
</body>
</html>


```
Задание выполнено






