# Домашнее задание - Lesson44-PSQLBARMAN

## Репликация postgres

Цель: научиться настраивать репликацию и создавать резервные копии в СУБД PostgreSQL;

Описание/Пошаговая инструкция выполнения домашнего задания:

Для выполнения домашнего задания используйте методичку
https://docs.google.com/document/d/1EU_KF3x9e2f75sNL4sghDIxib9eMfqex/edit?usp=share_link&ouid=104106368295333385634&rtpof=true&sd=true
Что нужно сделать?

    настроить hot_standby репликацию с использованием слотов
    настроить правильное резервное копирование
    Для сдачи работы присылаем ссылку на репозиторий, в котором должны обязательно быть
    Vagranfile (2 машины)
    плейбук Ansible
    конфигурационные файлы postgresql.conf, pg_hba.conf и recovery.conf,
    конфиг barman, либо скрипт резервного копирования.
    Команда "vagrant up" должна поднимать машины с настроенной репликацией и резервным копированием.
    Рекомендуется в README.md файл вложить результаты (текст или скриншоты) проверки работы репликации и резервного копирования.
    пример плейбука:


##  Выполнение

Делать ДЗ будем частистно по методичке, но с учетом что у меня в качестве платформы debian, то также воспользуемся статьей.

https://habr.com/ru/companies/first/articles/699644/


Предварительно на хотсе с вагрантом и ансиблом нужно доустановить пакет для postegres

```shell
ansible-galaxy collection install community.postgresql
```


Создаем Vagrantfile

```shell

# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
  :master => {
        :box_name => "debian/bullseye64",
        :ip_addr => '192.168.57.10'
  },
  :slave => {
        :box_name => "debian/bullseye64",
        :ip_addr => '192.168.57.20'
  },
  :barman => {
        :box_name => "debian/bullseye64",
        :ip_addr => '192.168.57.30'
  }
}

Vagrant.configure("2") do |config|

  MACHINES.each do |boxname, boxconfig|

      config.vm.define boxname do |box|

          box.vm.box = boxconfig[:box_name]
          box.vm.host_name = boxname.to_s
          
          box.vm.network "private_network", ip: boxconfig[:ip_addr]

          box.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--memory", "1024"]
          end

          box.vm.provision :shell do |s|
             s.inline = 'mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh'
          end

      end
  end
end


```


Первый playbook 01_master устанавливает на соответствующий хост postgres 16, описывает конфигурацию сервера master  и параметры подключения.

```shell
---

# Установим gnupg для ключа репозитория

- name: "Install gnupg"
  apt:
    name: gnupg2
    update_cache: yes

# добавим ключ репозитория

- name: Add PostgreSQL apt key
  ansible.builtin.apt_key:
    url: https://www.postgresql.org/media/keys/ACCC4CF8.asc
    state: present


## Добавим репозиторий

- name: Add PostgreSQL repository
  apt_repository:
    repo: deb https://apt.postgresql.org/pub/repos/apt {{ ansible_distribution_release }}-pgdg main
    state: present

# Установим Postgres

- name: Install PostgreSQL 16
  apt:
    name:
      - postgresql-16
    update_cache: yes
    state: present

# Проверяем, что postgres на хосте ещё не инициализирован
- name: check init 
  stat:
    path: /var/lib/postgresql/16/main/pg_stat
  register: stat_result

# Выполняем инициализацию postgres
- name: initialization setup
  shell: /usr/lib/postgresql/16/bin/initdb
  when: not stat_result.stat.exists
  become: true
  
# Запускаем postgresql
- name: enable and start service
  service:
    name: postgresql
    state: started
    enabled: true

### конец общей части для master и slave

# Установка python-пакетов для модулей psql
- name: install base tools
  apt:
    name:
      - python3-pexpect
      - python3-psycopg2
    state: present
    update_cache: true


# Установка acl для след блока
- name: install acl
  apt:
    name:
      - acl
    state: present
    update_cache: true
  tags: repluser
# требует ansible-galaxy collection install community.postgresql


- name: Create appclient user with SCRAM-hashed password
  become: true
  become_user: postgres
  community.postgresql.postgresql_user:
    name: replication
    password: "{{ replicator_password }}"
    role_attr_flags: REPLICATION 
  environment:
    PGOPTIONS: "-c password_encryption=scram-sha-256"
  tags: repluser

#Остановливаем postgresql на хосте master
- name: stop postgresql-server on 
  service: 
    name: postgresql
    state: stopped
  when: (ansible_hostname == "master")

#Копируем конфигурацию

- name: "Copy database configuration"
  template:
    src: "templates/full_postgresql.conf.j2"
    dest: "/etc/postgresql/16/main/postgresql.conf"
    owner: postgres
    group: postgres
    mode: 0644
  when: (ansible_hostname == "master")
  tags: backconf

#Копируем параметры подключения к базе

- name: "Copy user access configuration"
  template:
    src: "templates/pg_hba.conf.j2"
    dest: "/etc/postgresql/16/main/pg_hba.conf"
    owner: postgres
    group: postgres
    mode: 0640
  tags: backconf

#Перезапускаем службу  postgresql
- name: restart postgresql-server on master
  service: 
    name: postgresql
    state: restarted
  when: (ansible_hostname == "master")
  tags: backconf

####Barman

# Установим Barman-cli

- name: Install barman-cli
  apt:
    name:
      - barman-cli
    update_cache: yes
    state: present
  tags: barman


```
Результат выполнения в ansible

```shell
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson44-PSQLBARMAN/vm/ansible$ ansible-playbook playbooks/01_master.yml

PLAY [Install psql to master] *****************************************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************************************************
ok: [master]

TASK [../roles/01_master : Install gnupg] *****************************************************************************************************************************************************************
ok: [master]

TASK [../roles/01_master : Add PostgreSQL apt key] ********************************************************************************************************************************************************
ok: [master]

TASK [../roles/01_master : Add PostgreSQL repository] *****************************************************************************************************************************************************
ok: [master]

TASK [../roles/01_master : Install PostgreSQL 16] *********************************************************************************************************************************************************
ok: [master]

TASK [../roles/01_master : check init] ********************************************************************************************************************************************************************
ok: [master]

TASK [../roles/01_master : initialization setup] **********************************************************************************************************************************************************
skipping: [master]

TASK [../roles/01_master : enable and start service] ******************************************************************************************************************************************************
ok: [master]

TASK [../roles/01_master : install base tools] ************************************************************************************************************************************************************
changed: [master]

TASK [../roles/01_master : install acl] *******************************************************************************************************************************************************************
changed: [master]

TASK [../roles/01_master : Create appclient user with SCRAM-hashed password] ******************************************************************************************************************************
changed: [master]

TASK [../roles/01_master : stop postgresql-server on] *****************************************************************************************************************************************************
changed: [master]

TASK [../roles/01_master : Copy database configuration] ***************************************************************************************************************************************************

changed: [master]

TASK [../roles/01_master : Copy user access configuration] ************************************************************************************************************************************************

changed: [master]

TASK [../roles/01_master : restart postgresql-server on master] *******************************************************************************************************************************************

changed: [master]

PLAY RECAP ************************************************************************************************************************************************************************************************
master                     : ok=14   changed=7    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   


```

На хосте slave почти аналогичный playbook

Выполнение.

```shell



sincere@sincere-ubuntuotus:~/vagrantdocs/lesson44-PSQLBARMAN/vm/ansible$ ansible-playbook playbooks/02_slave.yml

PLAY [Install psql to slave] ******************************************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************************************************
ok: [slave]

TASK [../roles/02_slave : Install gnupg] ******************************************************************************************************************************************************************
changed: [slave]

TASK [../roles/02_slave : Add PostgreSQL apt key] *********************************************************************************************************************************************************
changed: [slave]

TASK [../roles/02_slave : Add PostgreSQL repository] ******************************************************************************************************************************************************
changed: [slave]

TASK [../roles/02_slave : Install PostgreSQL 16] **********************************************************************************************************************************************************
changed: [slave]

TASK [../roles/02_slave : install acl] ********************************************************************************************************************************************************************
changed: [slave]

TASK [../roles/02_slave : install base tools] *************************************************************************************************************************************************************
changed: [slave]

TASK [../roles/02_slave : Install python-pip for pexpect promt answering] *********************************************************************************************************************************
changed: [slave]

TASK [../roles/02_slave : Pip install pexpect] ************************************************************************************************************************************************************
ok: [slave]

TASK [../roles/02_slave : stop postgresql-server on] ******************************************************************************************************************************************************
changed: [slave]

TASK [../roles/02_slave : check init] *********************************************************************************************************************************************************************
ok: [slave]

TASK [../roles/02_slave : Remove files from data catalog] *************************************************************************************************************************************************
changed: [slave]

TASK [../roles/02_slave : copy files from master to slave] ************************************************************************************************************************************************
changed: [slave]

TASK [../roles/02_slave : Copy database configuration] ****************************************************************************************************************************************************
skipping: [slave]

TASK [../roles/02_slave : Copy user access configuration] *************************************************************************************************************************************************
changed: [slave]

TASK [../roles/02_slave : enable and start service] *******************************************************************************************************************************************************
changed: [slave]

PLAY RECAP ************************************************************************************************************************************************************************************************
slave                      : ok=15   changed=12   unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   

```


Проверяем как настроилось.

На master

```shell


postgres=# \du
                              List of roles
  Role name  |                         Attributes                         
-------------+------------------------------------------------------------
 postgres    | Superuser, Create role, Create DB, Replication, Bypass RLS
 replication | Replication



postgres=# show config_file;
               config_file               
-----------------------------------------
 /etc/postgresql/16/main/postgresql.conf
(1 row)

postgres=# show data_directory;
       data_directory        
-----------------------------
 /var/lib/postgresql/16/main
(1 row)


postgres=# select usename,application_name,client_addr,backend_start,state,sync_state from pg_stat_replication ;
   usename   | application_name |  client_addr  |         backend_start         |   state   | sync_state 
-------------+------------------+---------------+-------------------------------+-----------+------------
 replication | 16/main          | 192.168.57.20 | 2023-12-14 16:05:10.102646-03 | streaming | async
(1 row)


postgres=# create database repltest2023;
CREATE DATABASE
postgres=# \l
                                                     List of databases
     Name     |  Owner   | Encoding | Locale Provider | Collate |  Ctype  | ICU Locale | ICU Rules |   Access privileges   
--------------+----------+----------+-----------------+---------+---------+------------+-----------+-----------------------
 postgres     | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 repltest     | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 repltest2023 | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 template0    | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
              |          |          |                 |         |         |            |           | postgres=CTc/postgres
 template1    | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
              |          |          |                 |         |         |            |           | postgres=CTc/postgres
 test         | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 test2        | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
(7 rows)


```

На slave



```shell

postgres=# show config_file;
               config_file               
-----------------------------------------
 /etc/postgresql/16/main/postgresql.conf
(1 row)

postgres=# show data_directory;
       data_directory        
-----------------------------
 /var/lib/postgresql/16/main
(1 row)





pid  |  status   | receive_start_lsn | receive_start_tli | written_lsn | flushed_lsn | received_tli |      last_msg_send_time       |     last_msg_receipt_time     | latest_end_lsn |        latest_end_time        | slot_name |  sender_host  | sender_port |                                                                                                                                                                     conninfo                                                                                                                                                                      
-------+-----------+-------------------+-------------------+-------------+-------------+--------------+-------------------------------+-------------------------------+----------------+-------------------------------+-----------+---------------+-------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 28770 | streaming | 0/D000000         |                 1 | 0/D000148   | 0/D000148   |            1 | 2023-12-14 19:10:32.143817+00 | 2023-12-14 19:10:32.144764+00 | 0/D000148      | 2023-12-14 19:09:02.078316+00 |           | 192.168.57.10 |        5432 | user=replication password=******** channel_binding=prefer dbname=replication host=192.168.57.10 port=5432 fallback_application_name=16/main sslmode=prefer sslcompression=0 sslcertmode=allow sslsni=1 ssl_min_protocol_version=TLSv1.2 gssencmode=prefer krbsrvname=postgres gssdelegation=0 target_session_attrs=any load_balance_hosts=disable
(1 row)



postgres=# \l
                                                     List of databases
     Name     |  Owner   | Encoding | Locale Provider | Collate |  Ctype  | ICU Locale | ICU Rules |   Access privileges   
--------------+----------+----------+-----------------+---------+---------+------------+-----------+-----------------------
 postgres     | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 repltest     | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 repltest2023 | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 template0    | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
              |          |          |                 |         |         |            |           | postgres=CTc/postgres
 template1    | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
              |          |          |                 |         |         |            |           | postgres=CTc/postgres
 test         | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 test2        | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
(7 rows)

```

Видим что репликация настроена и работает.

### Переходим к настройке бэкапа.

Выполнение будет в два этапа

#### 1. Первичная настройка barman

Создаем playbook

```shell

---

# Установим gnupg для ключа репозитория

- name: "Install gnupg"
  apt:
    name: gnupg2
    update_cache: yes

# добавим ключ репозитория

- name: Add PostgreSQL apt key
  ansible.builtin.apt_key:
    url: https://www.postgresql.org/media/keys/ACCC4CF8.asc
    state: present


## Добавим репозиторий

- name: Add PostgreSQL repository
  apt_repository:
    repo: deb https://apt.postgresql.org/pub/repos/apt {{ ansible_distribution_release }}-pgdg main
    state: present

# Установим Postgres

- name: Install PostgreSQL 16
  apt:
    name:
      - postgresql-16
    update_cache: yes
    state: present

# Установим Barman

- name: Install PostgreSQL 16
  apt:
    name:
      - barman
      - barman-cli
    update_cache: yes
    state: present



# Установка python-пакетов для модулей psql
- name: install base tools
  apt:
    name:
      - python3-pexpect
      - python3-psycopg2
    state: present
    update_cache: true


# Установка acl
- name: install acl
  apt:
    name:
      - acl
    state: present
    update_cache: true
  tags: repluser

    # Копируем файл .pgpass
- name: copy .pgpass
  template:
    src: "templates/.pgpass.j2"
    dest: /var/lib/barman/.pgpass
    owner: barman
    group: barman
    mode: '0600'


  # Копируем файл barman.conf
- name: copy barman.conf
  template:
    src: "templates/barman.conf.j2"
    dest: /etc/barman.conf 
    owner: barman
    group: barman
    mode: '0755'


```

Выполнение

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson44-PSQLBARMAN/vm/ansible$ ansible-playbook playbooks/03_barman.yml

PLAY [Install barman] *************************************************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************************************************
[WARNING]: Platform linux on host barman is using the discovered Python interpreter at /usr/bin/python3, but future installation of another Python interpreter could change this. See
https://docs.ansible.com/ansible/2.9/reference_appendices/interpreter_discovery.html for more information.
ok: [barman]

TASK [../roles/03_barman : Install gnupg] *****************************************************************************************************************************************************************
ok: [barman]

TASK [../roles/03_barman : Add PostgreSQL apt key] ********************************************************************************************************************************************************
ok: [barman]

TASK [../roles/03_barman : Add PostgreSQL repository] *****************************************************************************************************************************************************
ok: [barman]

TASK [../roles/03_barman : Install PostgreSQL 16] *********************************************************************************************************************************************************
ok: [barman]

TASK [../roles/03_barman : Install PostgreSQL 16] *********************************************************************************************************************************************************
ok: [barman]

TASK [../roles/03_barman : install base tools] ************************************************************************************************************************************************************
ok: [barman]

TASK [../roles/03_barman : install acl] *******************************************************************************************************************************************************************
ok: [barman]

TASK [../roles/03_barman : copy .pgpass] ******************************************************************************************************************************************************************

changed: [barman]

TASK [../roles/03_barman : copy barman.conf] **************************************************************************************************************************************************************

ok: [barman]

PLAY RECAP ************************************************************************************************************************************************************************************************
barman                     : ok=10   changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  


```

4 шаг скрипт постконфигурации
Описывается обмен ключами ssh и конфигурация самого barman


```shell

---

# Установка python-пакетов для модулей psql
- name: install base tools
  apt:
    name:
      - python3-pexpect
      - python3-psycopg2
    state: present
    update_cache: true


- name: generate SSH key for postgres
  user:
    name: postgres
    generate_ssh_key: yes
    ssh_key_type: rsa
    ssh_key_bits: 4096
    force: no
  when: (ansible_hostname == "master")


- name: generate SSH key for barman
  user:
    name: barman
    shell: /bin/bash
    generate_ssh_key: yes
    ssh_key_type: rsa
    ssh_key_bits: 4096
    force: no
  when: (ansible_hostname == "barman")



#  Забираем содержимое открытого ключа postgres c хоста master
- name: fetch all public ssh keys node1
  shell: cat /var/lib/postgresql/.ssh/id_rsa.pub
  register: ssh_keys
  when: (ansible_hostname == "master")

#  Копируем ключ с barman на master
- name: transfer public key to barman
  delegate_to: barman
  authorized_key:
    key: "{{ ssh_keys.stdout }}"
    comment: "{{ansible_hostname}}"
    user: barman
  when: (ansible_hostname == "master")  

#  Забираем содержимое открытого ключа barman c хоста barman 
- name: fetch all public ssh keys barman
  shell: cat /var/lib/barman/.ssh/id_rsa.pub
  register: ssh_keys
  when: (ansible_hostname == "barman")

#  Копируем ключ с node1 на barman
- name: transfer public key to barman
  delegate_to: master
  authorized_key:
    key: "{{ ssh_keys.stdout }}"
    comment: "{{ansible_hostname}}"
    user: postgres
  when: (ansible_hostname == "barman")

#CREATE USER barman SUPERUSER;
- name: Create barman user
  become_user: postgres
  postgresql_user:
    name: barman
    password: '{{ barman_user_password }}'
    role_attr_flags: SUPERUSER 
  ignore_errors: true
  when: (ansible_hostname == "master")

 # Добавляем разрешения для поключения с хоста barman
- name: Add permission for barman
  lineinfile:
    path: "/etc/postgresql/16/main/pg_hba.conf"
    line: 'host    all   {{ barman_user }}    {{ barman_ip }}/32    scram-sha-256'
  when: (ansible_hostname != "barman") 

# Добавляем разрешения для подключения с хоста barman
- name: Add permission for barman
  lineinfile:
    path: "/etc/postgresql/16/main/pg_hba.conf"
    line: 'host    replication   {{ barman_user }}    {{ barman_ip }}/32    scram-sha-256'
  when: (ansible_hostname != "barman")


# Перезагружаем службу postgresql-server
- name: restart postgresql-server on master
  service: 
    name: postgresql
    state: restarted
  when: (ansible_hostname == "master")

# Создаём БД otus;
- name: Create DB for backup
  become_user: postgres
  postgresql_db:
    name: otus
    encoding: UTF-8
    template: template0
    state: present
  when: (ansible_hostname == "master")

# Создаём таблицу test1 в БД otus;
- name: Add tables to otus_backup
  become_user: postgres
  postgresql_table:
    db: otus
    name: sincere
    state: present
  when: (ansible_hostname == "master")

# Копируем файл master.conf
- name: copy master.conf
  template:
    src: "templates/master.conf.j2"
    dest: /etc/barman.d/master.conf
    owner: barman
    group: barman
    mode: '0755'
  when: (ansible_hostname == "barman")

- name: barman switch-wal master
  become_user: barman
  shell: barman switch-wal master
  when: (ansible_hostname == "barman")

- name: barman cron
  become_user: barman
  shell: barman cron
  when: (ansible_hostname == "barman")



```

Выполнение

```shell 

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson44-PSQLBARMAN/vm/ansible$ ansible-playbook playbooks/04_postconfiguration.yml 

PLAY [Postconfiguration] **********************************************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************************************************

ok: [master]

TASK [../roles/04_postconfiguration : install base tools] *************************************************************************************************************************************************
ok: [barman]
ok: [slave]
ok: [master]

TASK [../roles/04_postconfiguration : generate SSH key for postgres] **************************************************************************************************************************************
skipping: [barman]
ok: [master]

TASK [../roles/04_postconfiguration : generate SSH key for barman] ****************************************************************************************************************************************

ok: [barman]

TASK [../roles/04_postconfiguration : fetch all public ssh keys node1] ************************************************************************************************************************************

skipping: [slave]
skipping: [barman]
changed: [master]

TASK [../roles/04_postconfiguration : transfer public key to barman] **************************************************************************************************************************************

skipping: [barman]
changed: [master -> None]

TASK [../roles/04_postconfiguration : fetch all public ssh keys barman] ***********************************************************************************************************************************

skipping: [slave]
changed: [barman]

TASK [../roles/04_postconfiguration : transfer public key to barman] **************************************************************************************************************************************

changed: [barman -> None]

TASK [../roles/04_postconfiguration : Create barman user] *************************************************************************************************************************************************

skipping: [slave]
skipping: [barman]
[WARNING]: Module did not set no_log for no_password_changes
changed: [master]

TASK [../roles/04_postconfiguration : Add permission for barman] ******************************************************************************************************************************************

skipping: [barman]
changed: [master]
changed: [slave]

TASK [../roles/04_postconfiguration : Add permission for barman] ******************************************************************************************************************************************

skipping: [barman]
changed: [master]
changed: [slave]

TASK [../roles/04_postconfiguration : restart postgresql-server on master] ********************************************************************************************************************************

skipping: [slave]
skipping: [barman]
changed: [master]

TASK [../roles/04_postconfiguration : Create DB for backup] ***********************************************************************************************************************************************

skipping: [barman]
changed: [master]

TASK [../roles/04_postconfiguration : Add tables to otus_backup] ******************************************************************************************************************************************

skipping: [master]
skipping: [slave]
skipping: [barman]

TASK [../roles/04_postconfiguration : copy master.conf] ***************************************************************************************************************************************************

skipping: [slave]
changed: [barman]

TASK [../roles/04_postconfiguration : barman switch-wal master1] ********************************************************************************************************************************************

changed: [barman]

TASK [../roles/04_postconfiguration : barman cron] ********************************************************************************************************************************************************

skipping: [master]
skipping: [slave]

(/home/sincere/.local/lib/python3.8/site-packages/jinja2/filters.py)
changed: [barman]

PLAY RECAP ************************************************************************************************************************************************************************************************
barman                     : ok=8    changed=5    unreachable=0    failed=0    skipped=9    rescued=0    ignored=0   
master                     : ok=10   changed=7    unreachable=0    failed=0    skipped=7    rescued=0    ignored=0   
slave                      : ok=4    changed=2    unreachable=0    failed=0    skipped=13   rescued=0    ignored=0   

```
Проверяем создание бэкапа  и восстановление

```shell

on master 


Пользователи - barman  на месте 

postgres=# \du
                              List of roles
  Role name  |                         Attributes                         
-------------+------------------------------------------------------------
 barman      | Superuser
 postgres    | Superuser, Create role, Create DB, Replication, Bypass RLS
 replication | Replication

базы на месте

postgres=# \l
                                                     List of databases
     Name     |  Owner   | Encoding | Locale Provider | Collate |  Ctype  | ICU Locale | ICU Rules |   Access privileges   
--------------+----------+----------+-----------------+---------+---------+------------+-----------+-----------------------
 otus         | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 postgres     | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 repltest2023 | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 template0    | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
              |          |          |                 |         |         |            |           | postgres=CTc/postgres
 template1    | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
              |          |          |                 |         |         |            |           | postgres=CTc/postgres
(5 rows)

таблицы созданы

postgres=# \c otus
You are now connected to database "otus" as user "postgres".
otus=# \dt
          List of relations
 Schema |  Name   | Type  |  Owner   
--------+---------+-------+----------
 public | sincere | table | postgres
(1 row)

otus=# 



on slave

пользователь barman на месте

postgres=# \du
                              List of roles
  Role name  |                         Attributes                         
-------------+------------------------------------------------------------
 barman      | Superuser
 postgres    | Superuser, Create role, Create DB, Replication, Bypass RLS
 replication | Replication


базы нас месте (отреплицированы)


postgres=# \l
                                                     List of databases
     Name     |  Owner   | Encoding | Locale Provider | Collate |  Ctype  | ICU Locale | ICU Rules |   Access privileges   
--------------+----------+----------+-----------------+---------+---------+------------+-----------+-----------------------
 otus         | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 postgres     | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 repltest2023 | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 template0    | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
              |          |          |                 |         |         |            |           | postgres=CTc/postgres
 template1    | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
              |          |          |                 |         |         |            |           | postgres=CTc/postgres
(5 rows)

таблички на месте


postgres=# \c otus
You are now connected to database "otus" as user "postgres".
otus=# \dt+
                                     List of relations
 Schema |  Name   | Type  |  Owner   | Persistence | Access method |  Size   | Description 
--------+---------+-------+----------+-------------+---------------+---------+-------------
 public | sincere | table | postgres | permanent   | heap          | 0 bytes | 
(1 row)

otus=# 



## BARMAN

```shell

root@barman:/home/vagrant# cat /var/lib/barman/.pgpass
192.168.57.10:5432:*:barman:Barman2023!
root@barman:/home/vagrant# sudo su barman
barman@barman:/home/vagrant$ psql -h 192.168.57.10 -U barman -d postgres 
perl: warning: Setting locale failed.
perl: warning: Please check that your locale settings:
	LANGUAGE = (unset),
	LC_ALL = (unset),
	LC_ADDRESS = "ru_RU.UTF-8",
	LC_NAME = "ru_RU.UTF-8",
	LC_MONETARY = "ru_RU.UTF-8",
	LC_PAPER = "ru_RU.UTF-8",
	LC_IDENTIFICATION = "ru_RU.UTF-8",
	LC_TELEPHONE = "ru_RU.UTF-8",
	LC_MEASUREMENT = "ru_RU.UTF-8",
	LC_TIME = "ru_RU.UTF-8",
	LC_NUMERIC = "ru_RU.UTF-8",
	LANG = "C.UTF-8"
    are supported and installed on your system.
perl: warning: Falling back to a fallback locale ("C.UTF-8").
psql (16.1 (Debian 16.1-1.pgdg110+1))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
Type "help" for help.

postgres=# 

```

Подключились успешно.

```shell

barman@barman:/home/vagrant$ psql -h 192.168.57.10 -U barman -c "IDENTIFY_SYSTEM" replication=1
perl: warning: Setting locale failed.
perl: warning: Please check that your locale settings:
	LANGUAGE = (unset),
	LC_ALL = (unset),
	LC_ADDRESS = "ru_RU.UTF-8",
	LC_NAME = "ru_RU.UTF-8",
	LC_MONETARY = "ru_RU.UTF-8",
	LC_PAPER = "ru_RU.UTF-8",
	LC_IDENTIFICATION = "ru_RU.UTF-8",
	LC_TELEPHONE = "ru_RU.UTF-8",
	LC_MEASUREMENT = "ru_RU.UTF-8",
	LC_TIME = "ru_RU.UTF-8",
	LC_NUMERIC = "ru_RU.UTF-8",
	LANG = "C.UTF-8"
    are supported and installed on your system.
perl: warning: Falling back to a fallback locale ("C.UTF-8").
      systemid       | timeline |  xlogpos  | dbname 
---------------------+----------+-----------+--------
 7312537529709184425 |        1 | 0/5000060 | 
(1 row)

barman@barman:/home/vagrant$ 

```

Смотрим какие есть конфиги


```shell
barman@barman:/home/vagrant$ barman list-server
master - backup master
```

Переключаемся на журнал WAL на master

```shell

barman@barman:/home/vagrant$ barman switch-wal master
The WAL file 000000010000000000000006 has been closed on server 'master'
barman@barman:/home/vagrant$ 
barman@barman:/home/vagrant$ 
barman@barman:/home/vagrant$ barman cron
Starting WAL archiving for server master
barman@barman:/home/vagrant$ barman check master
Server master:
	PostgreSQL: OK
	superuser or standard user with backup privileges: OK
	PostgreSQL streaming: OK
	wal_level: OK
	replication slot: OK
	directories: OK
	retention policy settings: OK
	backup maximum age: FAILED (interval provided: 4 days, latest backup age: No available backups)
	backup minimum size: OK (0 B)
	wal maximum age: OK (no last_wal_maximum_age provided)
	wal size: OK (0 B)
	compression settings: OK
	failed backups: OK (there are 0 failed backups)
	minimum redundancy requirements: FAILED (have 0 backups, expected at least 1)
	pg_basebackup: OK
	pg_basebackup compatible: OK
	pg_basebackup supports tablespaces mapping: OK
	systemid coherence: OK (no system Id stored on disk)
	pg_receivexlog: OK
	pg_receivexlog compatible: OK
	receive-wal running: OK
	archiver errors: OK
barman@barman:/home/vagrant$ 



```


Запустим backup

```shell

barman@barman:/home/vagrant$ barman backup master
Starting backup using postgres method for server master in /var/lib/barman/master/base/20231217T205917
Backup start at LSN: 0/70158F8 (000000010000000000000007, 000158F8)
Starting backup copy via pg_basebackup for 20231217T205917
WARNING: pg_basebackup does not copy the PostgreSQL configuration files that reside outside PGDATA. Please manually backup the following files:
	/etc/postgresql/16/main/postgresql.conf
	/etc/postgresql/16/main/pg_hba.conf
	/etc/postgresql/16/main/pg_ident.conf

Copy done (time: 2 seconds)
Finalising the backup.
This is the first backup for server master
WAL segments preceding the current backup have been found:
	000000010000000000000005 from server master has been removed
	000000010000000000000006 from server master has been removed
Backup size: 36.7 MiB
Backup end at LSN: 0/9000000 (000000010000000000000008, 00000000)
Backup completed (start time: 2023-12-17 20:59:17.967006, elapsed time: 3 seconds)
Processing xlog segments from streaming for master
	000000010000000000000007
	000000010000000000000008
barman@barman:/home/vagrant$ barman check master
Server master:
	PostgreSQL: OK
	superuser or standard user with backup privileges: OK
	PostgreSQL streaming: OK
	wal_level: OK
	replication slot: OK
	directories: OK
	retention policy settings: OK
	backup maximum age: OK (interval provided: 4 days, latest backup age: 8 seconds)
	backup minimum size: OK (36.7 MiB)
	wal maximum age: OK (no last_wal_maximum_age provided)
	wal size: OK (0 B)
	compression settings: OK
	failed backups: OK (there are 0 failed backups)
	minimum redundancy requirements: OK (have 1 backups, expected at least 1)
	pg_basebackup: OK
	pg_basebackup compatible: OK
	pg_basebackup supports tablespaces mapping: OK
	systemid coherence: OK
	pg_receivexlog: OK
	pg_receivexlog compatible: OK
	receive-wal running: OK
	archiver errors: OK
barman@barman:/home/vagrant$ 


```

Удаляем базу


## На master

```shell

postgres@master:/home/vagrant$ psql
perl: warning: Setting locale failed.
perl: warning: Please check that your locale settings:
	LANGUAGE = (unset),
	LC_ALL = (unset),
	LC_ADDRESS = "ru_RU.UTF-8",
	LC_NAME = "ru_RU.UTF-8",
	LC_MONETARY = "ru_RU.UTF-8",
	LC_PAPER = "ru_RU.UTF-8",
	LC_IDENTIFICATION = "ru_RU.UTF-8",
	LC_TELEPHONE = "ru_RU.UTF-8",
	LC_MEASUREMENT = "ru_RU.UTF-8",
	LC_TIME = "ru_RU.UTF-8",
	LC_NUMERIC = "ru_RU.UTF-8",
	LANG = "C.UTF-8"
    are supported and installed on your system.
perl: warning: Falling back to a fallback locale ("C.UTF-8").
psql (16.1 (Debian 16.1-1.pgdg110+1))
Type "help" for help.

postgres=# 
postgres=# 
postgres=# \l
                                                     List of databases
     Name     |  Owner   | Encoding | Locale Provider | Collate |  Ctype  | ICU Locale | ICU Rules |   Access privileges   
--------------+----------+----------+-----------------+---------+---------+------------+-----------+-----------------------
 otus         | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 postgres     | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 repltest2023 | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 template0    | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
              |          |          |                 |         |         |            |           | postgres=CTc/postgres
 template1    | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
              |          |          |                 |         |         |            |           | postgres=CTc/postgres
(5 rows)

postgres=# DROP DATABASE otus;
DROP DATABASE
postgres=# \l
                                                     List of databases
     Name     |  Owner   | Encoding | Locale Provider | Collate |  Ctype  | ICU Locale | ICU Rules |   Access privileges   
--------------+----------+----------+-----------------+---------+---------+------------+-----------+-----------------------
 postgres     | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 repltest2023 | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 template0    | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
              |          |          |                 |         |         |            |           | postgres=CTc/postgres
 template1    | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
              |          |          |                 |         |         |            |           | postgres=CTc/postgres
(4 rows)

postgres=# 


```

## На barman

```shell

barman@barman:/home/vagrant$ barman list-backup master
master 20231217T205917 - Sun Dec 17 17:59:20 2023 - Size: 36.7 MiB - WAL Size: 0 B

barman@barman:/home/vagrant$ barman recover master 20231217T205917 /var/lib/postgresql/16/data/ --remote-ssh-comman "ssh postgres@192.168.57.10"
The authenticity of host '192.168.57.10 (192.168.57.10)' can't be established.
ECDSA key fingerprint is SHA256:/rjKA6JBg7NgNFhhC4gHlLSom38qnWqjDPk0ZfWZ1eo.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Starting remote restore for server master using backup 20231217T205917
Destination directory: /var/lib/postgresql/16/data/
Remote command: ssh postgres@192.168.57.10
Copying the base backup.
Copying required WAL segments.
Generating archive status files
Identify dangerous settings in destination directory.

WARNING
The following configuration files have not been saved during backup, hence they have not been restored.
You need to manually restore them in order to start the recovered PostgreSQL instance:

    postgresql.conf
    pg_hba.conf
    pg_ident.conf

Recovery completed (start time: 2023-12-17 21:06:33.598949+00:00, elapsed time: 9 seconds)
Your PostgreSQL server has been successfully prepared for recovery!
barman@barman:/home/vagrant$ 


```

## На master



```shell

Действительно не восстановились конфиги


postgres@master:~/16/main$ ls -la
total 316
drwx------ 19 postgres postgres   4096 Dec 17 21:09 .
drwxr-xr-x  3 postgres postgres   4096 Dec 17 21:12 ..
-rw-r--r--  1 postgres postgres    944 Dec 17 20:59 .barman-recover.info
-rw-------  1 postgres postgres      3 Dec 17 20:59 PG_VERSION
-rw-------  1 postgres postgres    225 Dec 17 20:59 backup_label
-rw-------  1 postgres postgres 224141 Dec 17 20:59 backup_manifest.20231217T205917
drwx------  7 postgres postgres   4096 Dec 17 20:59 base
drwx------  2 postgres postgres   4096 Dec 17 20:59 global
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_commit_ts
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_dynshmem
drwx------  4 postgres postgres   4096 Dec 17 20:59 pg_logical
drwx------  4 postgres postgres   4096 Dec 17 20:59 pg_multixact
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_notify
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_replslot
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_serial
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_snapshots
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_stat
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_stat_tmp
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_subtrans
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_tblspc
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_twophase
drwx------  3 postgres postgres   4096 Dec 17 21:09 pg_wal
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_xact
-rw-------  1 postgres postgres     88 Dec 17 21:09 postgresql.auto.conf
-rw-------  1 postgres postgres     88 Dec 17 20:59 postgresql.auto.conf.origin



Восстановим


sincere@sincere-ubuntuotus:~/vagrantdocs/lesson44-PSQLBARMAN/vm/ansible$ ansible-playbook playbooks/01_master.yml -t backconf

PLAY [Install psql to master] *****************************************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************************************************
[WARNING]: Platform linux on host master is using the discovered Python interpreter at /usr/bin/python3, but future installation of another Python interpreter could change this. See
https://docs.ansible.com/ansible/2.9/reference_appendices/interpreter_discovery.html for more information.
ok: [master]

TASK [../roles/01_master : Copy database configuration] ***************************************************************************************************************************************************

ok: [master]

TASK [../roles/01_master : Copy user access configuration] ************************************************************************************************************************************************

changed: [master]

TASK [../roles/01_master : restart postgresql-server on master] *******************************************************************************************************************************************

changed: [master]

PLAY RECAP ************************************************************************************************************************************************************************************************
master                     : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   


Восстановились

postgres@master:~/16/main$ ls -la
total 324
drwx------ 19 postgres postgres   4096 Dec 17 21:15 .
drwxr-xr-x  3 postgres postgres   4096 Dec 17 21:12 ..
-rw-r--r--  1 postgres postgres    944 Dec 17 20:59 .barman-recover.info
-rw-------  1 postgres postgres      3 Dec 17 20:59 PG_VERSION
-rw-------  1 postgres postgres    225 Dec 17 20:59 backup_label.old
-rw-------  1 postgres postgres 224141 Dec 17 20:59 backup_manifest.20231217T205917
drwx------  7 postgres postgres   4096 Dec 17 20:59 base
drwx------  2 postgres postgres   4096 Dec 17 21:15 global
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_commit_ts
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_dynshmem
drwx------  4 postgres postgres   4096 Dec 17 21:15 pg_logical
drwx------  4 postgres postgres   4096 Dec 17 20:59 pg_multixact
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_notify
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_replslot
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_serial
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_snapshots
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_stat
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_stat_tmp
drwx------  2 postgres postgres   4096 Dec 17 21:15 pg_subtrans
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_tblspc
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_twophase
drwx------  3 postgres postgres   4096 Dec 17 21:15 pg_wal
drwx------  2 postgres postgres   4096 Dec 17 20:59 pg_xact
-rw-------  1 postgres postgres     88 Dec 17 21:09 postgresql.auto.conf
-rw-------  1 postgres postgres     88 Dec 17 20:59 postgresql.auto.conf.origin
-rw-------  1 postgres postgres    130 Dec 17 21:15 postmaster.opts
-rw-------  1 postgres postgres    109 Dec 17 21:15 postmaster.pid


Наши базы на месте

postgres@master:~/16/main$ psql
perl: warning: Setting locale failed.
perl: warning: Please check that your locale settings:
	LANGUAGE = (unset),
	LC_ALL = (unset),
	LC_ADDRESS = "ru_RU.UTF-8",
	LC_NAME = "ru_RU.UTF-8",
	LC_MONETARY = "ru_RU.UTF-8",
	LC_PAPER = "ru_RU.UTF-8",
	LC_IDENTIFICATION = "ru_RU.UTF-8",
	LC_TELEPHONE = "ru_RU.UTF-8",
	LC_MEASUREMENT = "ru_RU.UTF-8",
	LC_TIME = "ru_RU.UTF-8",
	LC_NUMERIC = "ru_RU.UTF-8",
	LANG = "C.UTF-8"
    are supported and installed on your system.
perl: warning: Falling back to a fallback locale ("C.UTF-8").
psql (16.1 (Debian 16.1-1.pgdg110+1))
Type "help" for help.

postgres=# \l
                                                     List of databases
     Name     |  Owner   | Encoding | Locale Provider | Collate |  Ctype  | ICU Locale | ICU Rules |   Access privileges   
--------------+----------+----------+-----------------+---------+---------+------------+-----------+-----------------------
 otus         | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 postgres     | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 repltest2023 | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 template0    | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
              |          |          |                 |         |         |            |           | postgres=CTc/postgres
 template1    | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
              |          |          |                 |         |         |            |           | postgres=CTc/postgres
(5 rows)

postgres=# 

postgres=# \c otus
You are now connected to database "otus" as user "postgres".
otus=# \dt+
                                      List of relations
 Schema |  Name   | Type  |  Owner   | Persistence | Access method |    Size    | Description 
--------+---------+-------+----------+-------------+---------------+------------+-------------
 public | sincere | table | postgres | permanent   | heap          | 0 bytes    | 
 public | test    | table | postgres | permanent   | heap          | 8192 bytes | 
(2 rows)

otus=# 



```

Ура!! Все работает!

Домашнее задание сделано.