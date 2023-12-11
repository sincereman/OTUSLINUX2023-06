# Lesson42 - Репликация mysql


## Описание/Пошаговая инструкция выполнения домашнего задания:

Для выполнения домашнего задания используйте методичку
https://drive.google.com/file/d/139irfqsbAxNMjVcStUN49kN7MXAJr_z9/view?usp=share_link
Что нужно сделать?
В материалах приложены ссылки на вагрант для репликации и дамп базы bet.dmp
Базу развернуть на мастере и настроить так, чтобы реплицировались таблицы:
| bookmaker |
| competition |
| market |
| odds |
| outcome

    Настроить GTID репликацию
    x
    варианты которые принимаются к сдаче

    рабочий вагрантафайл
    скрины или логи SHOW TABLES
    конфиги*
    пример в логе изменения строки и появления строки на реплике*


## Выполнение

Как обычно начинаем с Vagrantfile

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

## Разделим инсталяцию на три части

### 1. Установка Percona-Server MYSQL

Подробно описывать не буду - так как в основном известные вещи - подключение репозитория, apt и права на каталоги 

### 2. Настройка Master

В целом тоже понятный конфиг, но долго мучился с тем что GTID все время показывал как OFF, сначала пробовал включать руками через ansible, но затем вдруг понял, что в debian конфигурационный файлы в другом каталоге лежат относительно centos


```shell


mysql> SELECT @@server_id;
+-------------+
| @@server_id |
+-------------+
|           1 |
+-------------+
1 row in set (0.02 sec)

mysql> use bet;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> show tables;
+------------------+
| Tables_in_bet    |
+------------------+
| bookmaker        |
| competition      |
| events_on_demand |
| market           |
| odds             |
| outcome          |
| v_same_event     |
+------------------+
7 rows in set (0.02 sec)

mysql> show master status;
+------------------+----------+--------------+------------------+-------------------------------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set                         |
+------------------+----------+--------------+------------------+-------------------------------------------+
| mysql-bin.000001 |   120152 |              |                  | 3fabce01-9851-11ee-9f21-0800278dc04d:1-38 |
+------------------+----------+--------------+------------------+-------------------------------------------+
1 row in set (0.01 sec)


```

### 3. Настройка Slave

В mysql 8 усиленная авторизация... Долго искал правильный вариант, в итоге нашел, но уже реализовал с native password - сделаю уже в реальных условиях.

Вот что получилось.

```shell

mysql> SELECT @@server_id;
+-------------+
| @@server_id |
+-------------+
|           2 |
+-------------+
1 row in set (0.01 sec)

mysql> use bet;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> show tables;
+---------------+
| Tables_in_bet |
+---------------+
| bookmaker     |
| competition   |
| market        |
| odds          |
| outcome       |
+---------------+
5 rows in set (0.02 sec)

mysql> show slave status\G;
*************************** 1. row ***************************
               Slave_IO_State: Waiting for source to send event
                  Master_Host: 192.168.57.10
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000001
          Read_Master_Log_Pos: 120152
               Relay_Log_File: slave-relay-bin.000002
                Relay_Log_Pos: 420
        Relay_Master_Log_File: mysql-bin.000001
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: bet.events_on_demand,bet.v_same_event
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 120152
              Relay_Log_Space: 630
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 1
                  Master_UUID: 3fabce01-9851-11ee-9f21-0800278dc04d
             Master_Info_File: mysql.slave_master_info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Replica has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 
            Executed_Gtid_Set: 3fabce01-9851-11ee-9f21-0800278dc04d:1-38
                Auto_Position: 1
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version: 
       Master_public_key_path: 
        Get_master_public_key: 0
            Network_Namespace: 
1 row in set, 1 warning (0.01 sec)

ERROR: 
No query specified


```

### Проверим репликацию

Добавим запись в таблицу bookmaker

```shell

mysql> INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet');
Query OK, 1 row affected (0.06 sec)

mysql> SELECT * FROM bookmaker;
+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  1 | 1xbet          |
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  3 | unibet         |
+----+----------------+
5 rows in set (0.01 sec)

mysql> show master status
    -> ;
+------------------+----------+--------------+------------------+-------------------------------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set                         |
+------------------+----------+--------------+------------------+-------------------------------------------+
| mysql-bin.000001 |   120468 |              |                  | 3fabce01-9851-11ee-9f21-0800278dc04d:1-39 |
+------------------+----------+--------------+------------------+-------------------------------------------+
1 row in set (0.00 sec)


```

Значение GTID увеличилось на единичку.

Посмотрим на slave сервере

```shell


mysql> SELECT * FROM bookmaker;
+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  1 | 1xbet          |
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  3 | unibet         |
+----+----------------+
5 rows in set (0.02 sec)

mysql> show slave status\G;
*************************** 1. row ***************************
               Slave_IO_State: Waiting for source to send event
                  Master_Host: 192.168.57.10
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000001
          Read_Master_Log_Pos: 120468
               Relay_Log_File: slave-relay-bin.000002
                Relay_Log_Pos: 736
        Relay_Master_Log_File: mysql-bin.000001
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: bet.events_on_demand,bet.v_same_event
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 120468
              Relay_Log_Space: 946
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 1
                  Master_UUID: 3fabce01-9851-11ee-9f21-0800278dc04d
             Master_Info_File: mysql.slave_master_info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Replica has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 3fabce01-9851-11ee-9f21-0800278dc04d:39
            Executed_Gtid_Set: 3fabce01-9851-11ee-9f21-0800278dc04d:1-39
                Auto_Position: 1
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version: 
       Master_public_key_path: 
        Get_master_public_key: 0
            Network_Namespace: 
1 row in set, 1 warning (0.02 sec)

ERROR: 
No query specified

```
Запись реплицировалась.
Все отлично - репликация работает

Спасибо!



    


