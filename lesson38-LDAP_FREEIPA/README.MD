# Lesson38-LDAP_FREEIPA

Домашнее задание

Цель:  научиться настраивать LDAP-сервер и подключать к нему LDAP-клиентов;

Описание/Пошаговая инструкция выполнения домашнего задания:

Для выполнения домашнего задания используйте методичку
https://docs.google.com/document/d/1HoZBcvitZ4A9t-y6sbLEbzKmf4CWvb39/edit?usp=share_link&ouid=104106368295333385634&rtpof=true&sd=true
Что нужно сделать?

    Установить FreeIPA;
    Написать Ansible playbook для конфигурации клиента;
    Настроить аутентификацию по SSH-ключам*
    Firewall должен быть включен на сервере и на клиенте*
    Формат сдачи ДЗ - vagrant + ansible
    В чат ДЗ отправьте ссылку на ваш git-репозиторий. Обычно мы проверяем ДЗ в течение 48 часов.
    Если возникнут вопросы, обращайтесь к студентам, преподавателям и наставникам в канал группы в Telegram.
    Удачи при выполнении!


# Выполнение

Традиционно  подправим конфиг Vagrantfile

```shell

Vagrant.configure("2") do |config|
  # Указываем ОС, версию, количество ядер и ОЗУ
  config.vm.box = "centos/stream8"
  #config.vm.box_version = "20230727.1"
  config.vm.box_url = "https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-Vagrant-8-20231016.0.x86_64.vagrant-virtualbox.box"

  config.vm.provider :virtualbox do |v|
    v.memory = 2048
    v.cpus = 1
  end

  # Указываем имена хостов и их IP-адреса
  boxes = [
    { :name => "ipa.otus.lan",
      :ip => "192.168.57.10",
    },
    { :name => "client1.otus.lan",
      :ip => "192.168.57.11",
    },
    { :name => "client2.otus.lan",
      :ip => "192.168.57.12",
    }
  ]
  # Цикл запуска виртуальных машин
  boxes.each do |opts|
    config.vm.define opts[:name] do |config|
      config.vm.hostname = opts[:name]
      config.vm.network "private_network", ip: opts[:ip]
    end
  end
end

```

и не забудем про ansible.cfg после развертывания.


Изначально хотел в качестве хостовой системы для FreeIPA использовать Debian, но прочитал, что есть проблема совместимости в последних версиях IPA и Debian поэтому все на CENTOS8



## IPA-SERVER

Подготовим ansible role ipaserver


Важно подключить модуль в ansible @idm:DL1 !!
Сначала при тестовой установке хотел импользовать модуль pexpect, но видимо все время не попадал в ответы, и пошел традиционным путем передавать параметрычерез ключи.

Параметры 

```shell
[root@ipa vagrant]# ipa-server-install -h
Usage: ipa-server-install [options]

Options:
  --version             show program's version number and exit
  -h, --help            show this help message and exit
  -U, --unattended      unattended (un)installation never prompts the user
  --uninstall           uninstall an existing installation. The uninstall can
                        be run with --unattended option

  Basic options:
    -p DM_PASSWORD, --ds-password=DM_PASSWORD
                        Directory Manager password
    -a ADMIN_PASSWORD, --admin-password=ADMIN_PASSWORD
                        admin user kerberos password
    --ip-address=IP_ADDRESS
                        Master Server IP Address. This option can be used
                        multiple times
    -n DOMAIN_NAME, --domain=DOMAIN_NAME
                        primary DNS domain of the IPA deployment (not
                        necessarily related to the current hostname)
    -r REALM_NAME, --realm=REALM_NAME
                        Kerberos realm name of the IPA deployment (typically
                        an upper-cased name of the primary DNS domain)
    --hostname=HOST_NAME
                        fully qualified name of this host
    --ca-cert-file=FILE
                        File containing CA certificates for the service
                        certificate files
    --pki-config-override=PKI_CONFIG_OVERRIDE
                        Path to ini file with config overrides.
    --no-host-dns       Do not use DNS for hostname lookup during installation

  Server options:
    --setup-adtrust     configure AD trust capability
    --setup-kra         configure a dogtag KRA
    --setup-dns         configure bind with our zone

.... etc

```

Согласно документации напишем команду установки

```shell

ipa-server-install -U \
--ds-password=Otus2023! \
--admin-password=Otus2023! \
--ip-address=192.168.57.10
--auto-reverse \
--domain=otus.lan \
--realm=OTUS.LAN \
--hostname=ipa.otus.lan \
--mkhomedir \
--setup-dns \
--forwarder=8.8.8.8 \
--no-ntp \
-v \
--log-file=/var/log/ipaserver-install.log 

```


Запустим наш playbook


```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson38-LDAP_FREEIPA/vm/ansible$ ansible-playbook playbooks/ipaserver.yml

PLAY [Playbook of "ipaserver"] ***********************************************************************************************************************

TASK [Gathering Facts] *******************************************************************************************************************************
ok: [ipa.otus.lan]

TASK [../roles/ipaserver : set timezone] *************************************************************************************************************
changed: [ipa.otus.lan]

TASK [../roles/ipaserver : Synchronize datetime | Install chrony] ************************************************************************************

ok: [ipa.otus.lan]

TASK [../roles/ipaserver : Synchronize datetime | Turn on chronyd] ***********************************************************************************

ok: [ipa.otus.lan]

TASK [../roles/ipaserver : Allow connections on multiple tcp ports for IPASERVER] ********************************************************************

changed: [ipa.otus.lan] => (item=80)
changed: [ipa.otus.lan] => (item=443)
changed: [ipa.otus.lan] => (item=389)
changed: [ipa.otus.lan] => (item=636)
changed: [ipa.otus.lan] => (item=88)
changed: [ipa.otus.lan] => (item=464)
changed: [ipa.otus.lan] => (item=53)

TASK [../roles/ipaserver : Allow connections on multiple udp ports for IPASERVER] ********************************************************************

changed: [ipa.otus.lan] => (item=123)
changed: [ipa.otus.lan] => (item=88)
changed: [ipa.otus.lan] => (item=464)
changed: [ipa.otus.lan] => (item=53)

TASK [../roles/ipaserver : Add 192.168.57.10 to hosts file] ******************************************************************************************
changed: [ipa.otus.lan] => (item=127.0.0.1   localhost localhost.localdomain)
changed: [ipa.otus.lan] => (item=192.168.57.10 ipa.otus.lan ipa)

TASK [../roles/ipaserver : Install @idm:DL1] *********************************************************************************************************

changed: [ipa.otus.lan]

TASK [../roles/ipaserver : Install ipa-server] *******************************************************************************************************

changed: [ipa.otus.lan]

TASK [../roles/ipaserver : Install ipa-server-dns] ***************************************************************************************************

changed: [ipa.otus.lan]

```

Сразу не заработало, поправил на запуск команды установки сервера ipa с параматрами, а не с попытками отвечать на вопросы установщика (вариант виден в коде ansible скрипта - закомментирован блок - для истории)

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson38-LDAP_FREEIPA/vm/ansible$ ansible-playbook playbooks/ipaserver.yml -t configureipaserver

PLAY [Playbook of "ipaserver"] ****************************************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************************************************
ok: [ipa.otus.lan]

TASK [../roles/ipaserver : Configure ipa-server] **********************************************************************************************************************************************************
changed: [ipa.otus.lan]

PLAY RECAP ************************************************************************************************************************************************************************************************
ipa.otus.lan               : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  

```


Проверим выдает ли kerberos тикеты

```shell

[root@ipa vagrant]# kinit admin
Password for admin@OTUS.LAN: 
[root@ipa vagrant]# klist
Ticket cache: KCM:0
Default principal: admin@OTUS.LAN
Valid starting     Expires            Service principal
11/22/23 10:52:10  11/23/23 10:19:27  krbtgt/OTUS.LAN@OTUS.LAN
[root@ipa vagrant]# kdestroy

```

Все ок!

Проверим web

Обязательно обавить в /etc/hosts на машине с браузером

`192.168.57.10   ipa.otus.lan`


Заходим на web-интерфейс

Сделаем пару скриншотов - в папке images проекта


## IPA-CLIENT

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson38-LDAP_FREEIPA/vm/ansible$ ansible-playbook playbooks/ipaclient.yml 

PLAY [Playbook of "ipaclient"] ****************************************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************************************************
ok: [client1.otus.lan]
ok: [client2.otus.lan]

TASK [../roles/ipaclient : set timezone] ******************************************************************************************************************************************************************
changed: [client2.otus.lan]
changed: [client1.otus.lan]

TASK [../roles/ipaclient : Synchronize datetime | Install chrony] *****************************************************************************************************************************************

ok: [client1.otus.lan]
ok: [client2.otus.lan]

TASK [../roles/ipaclient : Synchronize datetime | Turn on chronyd] ****************************************************************************************************************************************

ok: [client2.otus.lan]
ok: [client1.otus.lan]

TASK [../roles/ipaclient : Allow connections on multiple tcp ports for IPASERVER] *************************************************************************************************************************

ok: [client1.otus.lan] => (item=80)
ok: [client2.otus.lan] => (item=80)
ok: [client2.otus.lan] => (item=443)
ok: [client1.otus.lan] => (item=443)
ok: [client2.otus.lan] => (item=389)
ok: [client1.otus.lan] => (item=389)
ok: [client2.otus.lan] => (item=88)
ok: [client1.otus.lan] => (item=88)
ok: [client2.otus.lan] => (item=464)
ok: [client1.otus.lan] => (item=464)

TASK [../roles/ipaclient : Allow connections on multiple udp ports for IPASERVER] *************************************************************************************************************************

ok: [client2.otus.lan] => (item=123)
ok: [client1.otus.lan] => (item=123)
ok: [client2.otus.lan] => (item=88)
ok: [client1.otus.lan] => (item=88)
ok: [client2.otus.lan] => (item=464)
ok: [client1.otus.lan] => (item=464)

TASK [../roles/ipaclient : Add 192.168.57.10 to hosts file] ***********************************************************************************************************************************************

ok: [client2.otus.lan] => (item=search otus.lan)
ok: [client1.otus.lan] => (item=search otus.lan)
ok: [client1.otus.lan] => (item=nameserver 192.168.57.10)
ok: [client2.otus.lan] => (item=nameserver 192.168.57.10)

TASK [../roles/ipaclient : Install @idm:DL1] **************************************************************************************************************************************************************

ok: [client1.otus.lan]
ok: [client2.otus.lan]

TASK [../roles/ipaclient : Install ipa-client] ************************************************************************************************************************************************************

ok: [client2.otus.lan]
ok: [client1.otus.lan]

TASK [../roles/ipaclient : configure ipa-client] **********************************************************************************************************************************************************
changed: [client1.otus.lan]
changed: [client2.otus.lan]

TASK [../roles/ipaclient : Debug registered var] **********************************************************************************************************************************************************

ok: [client2.otus.lan] => {
    "ipa_client_configure_log": {
        "changed": true,
        "cmd": [
            "ipa-client-install",
            "-U",
            "--principal",
            "admin@OTUS.LAN",
            "--password",
            "Otus2023!",
            "--server",
            "ipa.otus.lan",
            "--domain",
            "otus.lan",
            "--realm",
            "OTUS.LAN",
            "--mkhomedir",
            "--force-join"
        ],
        "delta": "0:01:26.006362",
        "end": "2023-11-22 11:10:56.686419",
        "failed": false,
        "rc": 0,
        "start": "2023-11-22 11:09:30.680057",
        "stderr": "Client hostname: client2.otus.lan\nRealm: OTUS.LAN\nDNS Domain: otus.lan\nIPA Server: ipa.otus.lan\nBaseDN: dc=otus,dc=lan\nSynchronizing time\nNo SRV records of NTP servers found and no NTP server or pool address was provided.\nAttempting to sync time with chronyc.\nTime synchronization was successful.\nSuccessfully retrieved CA cert\n    Subject:     CN=Certificate Authority,O=OTUS.LAN\n    Issuer:      CN=Certificate Authority,O=OTUS.LAN\n    Valid From:  2023-11-22 07:29:12\n    Valid Until: 2043-11-22 07:29:12\n\nEnrolled in IPA realm OTUS.LAN\nCreated /etc/ipa/default.conf\nConfigured /etc/sssd/sssd.conf\nSystemwide CA database updated.\nHostname (client2.otus.lan) does not have A/AAAA record.\nFailed to update DNS records.\nMissing A/AAAA record(s) for host client2.otus.lan: 192.168.57.12.\nMissing reverse record(s) for address(es): 192.168.57.12.\nAdding SSH public key from /etc/ssh/ssh_host_ed25519_key.pub\nAdding SSH public key from /etc/ssh/ssh_host_ecdsa_key.pub\nAdding SSH public key from /etc/ssh/ssh_host_rsa_key.pub\nCould not update DNS SSHFP records.\nSSSD enabled\nConfigured /etc/openldap/ldap.conf\nConfigured /etc/ssh/ssh_config\nConfigured /etc/ssh/sshd_config\nConfiguring otus.lan as NIS domain.\nConfigured /etc/krb5.conf for IPA realm OTUS.LAN\nClient configuration complete.\nThe ipa-client-install command was successful",
        "stderr_lines": [
            "Client hostname: client2.otus.lan",
            "Realm: OTUS.LAN",
            "DNS Domain: otus.lan",
            "IPA Server: ipa.otus.lan",
            "BaseDN: dc=otus,dc=lan",
            "Synchronizing time",
            "No SRV records of NTP servers found and no NTP server or pool address was provided.",
            "Attempting to sync time with chronyc.",
            "Time synchronization was successful.",
            "Successfully retrieved CA cert",
            "    Subject:     CN=Certificate Authority,O=OTUS.LAN",
            "    Issuer:      CN=Certificate Authority,O=OTUS.LAN",
            "    Valid From:  2023-11-22 07:29:12",
            "    Valid Until: 2043-11-22 07:29:12",
            "",
            "Enrolled in IPA realm OTUS.LAN",
            "Created /etc/ipa/default.conf",
            "Configured /etc/sssd/sssd.conf",
            "Systemwide CA database updated.",
            "Hostname (client2.otus.lan) does not have A/AAAA record.",
            "Failed to update DNS records.",
            "Missing A/AAAA record(s) for host client2.otus.lan: 192.168.57.12.",
            "Missing reverse record(s) for address(es): 192.168.57.12.",
            "Adding SSH public key from /etc/ssh/ssh_host_ed25519_key.pub",
            "Adding SSH public key from /etc/ssh/ssh_host_ecdsa_key.pub",
            "Adding SSH public key from /etc/ssh/ssh_host_rsa_key.pub",
            "Could not update DNS SSHFP records.",
            "SSSD enabled",
            "Configured /etc/openldap/ldap.conf",
            "Configured /etc/ssh/ssh_config",
            "Configured /etc/ssh/sshd_config",
            "Configuring otus.lan as NIS domain.",
            "Configured /etc/krb5.conf for IPA realm OTUS.LAN",
            "Client configuration complete.",
            "The ipa-client-install command was successful"
        ],
        "stdout": "This program will set up IPA client.\nVersion 4.9.12\n\n\nUsing default chrony configuration.",
        "stdout_lines": [
            "This program will set up IPA client.",
            "Version 4.9.12",
            "",
            "",
            "Using default chrony configuration."
        ]
    }
}
ok: [client1.otus.lan] => {
    "ipa_client_configure_log": {
        "changed": true,
        "cmd": [
            "ipa-client-install",
            "-U",
            "--principal",
            "admin@OTUS.LAN",
            "--password",
            "Otus2023!",
            "--server",
            "ipa.otus.lan",
            "--domain",
            "otus.lan",
            "--realm",
            "OTUS.LAN",
            "--mkhomedir",
            "--force-join"
        ],
        "delta": "0:01:25.872111",
        "end": "2023-11-22 11:10:56.561553",
        "failed": false,
        "rc": 0,
        "start": "2023-11-22 11:09:30.689442",
        "stderr": "Client hostname: client1.otus.lan\nRealm: OTUS.LAN\nDNS Domain: otus.lan\nIPA Server: ipa.otus.lan\nBaseDN: dc=otus,dc=lan\nSynchronizing time\nNo SRV records of NTP servers found and no NTP server or pool address was provided.\nAttempting to sync time with chronyc.\nTime synchronization was successful.\nSuccessfully retrieved CA cert\n    Subject:     CN=Certificate Authority,O=OTUS.LAN\n    Issuer:      CN=Certificate Authority,O=OTUS.LAN\n    Valid From:  2023-11-22 07:29:12\n    Valid Until: 2043-11-22 07:29:12\n\nEnrolled in IPA realm OTUS.LAN\nCreated /etc/ipa/default.conf\nConfigured /etc/sssd/sssd.conf\nSystemwide CA database updated.\nHostname (client1.otus.lan) does not have A/AAAA record.\nFailed to update DNS records.\nMissing A/AAAA record(s) for host client1.otus.lan: 192.168.57.11.\nMissing reverse record(s) for address(es): 192.168.57.11.\nAdding SSH public key from /etc/ssh/ssh_host_ed25519_key.pub\nAdding SSH public key from /etc/ssh/ssh_host_ecdsa_key.pub\nAdding SSH public key from /etc/ssh/ssh_host_rsa_key.pub\nCould not update DNS SSHFP records.\nSSSD enabled\nConfigured /etc/openldap/ldap.conf\nConfigured /etc/ssh/ssh_config\nConfigured /etc/ssh/sshd_config\nConfiguring otus.lan as NIS domain.\nConfigured /etc/krb5.conf for IPA realm OTUS.LAN\nClient configuration complete.\nThe ipa-client-install command was successful",
        "stderr_lines": [
            "Client hostname: client1.otus.lan",
            "Realm: OTUS.LAN",
            "DNS Domain: otus.lan",
            "IPA Server: ipa.otus.lan",
            "BaseDN: dc=otus,dc=lan",
            "Synchronizing time",
            "No SRV records of NTP servers found and no NTP server or pool address was provided.",
            "Attempting to sync time with chronyc.",
            "Time synchronization was successful.",
            "Successfully retrieved CA cert",
            "    Subject:     CN=Certificate Authority,O=OTUS.LAN",
            "    Issuer:      CN=Certificate Authority,O=OTUS.LAN",
            "    Valid From:  2023-11-22 07:29:12",
            "    Valid Until: 2043-11-22 07:29:12",
            "",
            "Enrolled in IPA realm OTUS.LAN",
            "Created /etc/ipa/default.conf",
            "Configured /etc/sssd/sssd.conf",
            "Systemwide CA database updated.",
            "Hostname (client1.otus.lan) does not have A/AAAA record.",
            "Failed to update DNS records.",
            "Missing A/AAAA record(s) for host client1.otus.lan: 192.168.57.11.",
            "Missing reverse record(s) for address(es): 192.168.57.11.",
            "Adding SSH public key from /etc/ssh/ssh_host_ed25519_key.pub",
            "Adding SSH public key from /etc/ssh/ssh_host_ecdsa_key.pub",
            "Adding SSH public key from /etc/ssh/ssh_host_rsa_key.pub",
            "Could not update DNS SSHFP records.",
            "SSSD enabled",
            "Configured /etc/openldap/ldap.conf",
            "Configured /etc/ssh/ssh_config",
            "Configured /etc/ssh/sshd_config",
            "Configuring otus.lan as NIS domain.",
            "Configured /etc/krb5.conf for IPA realm OTUS.LAN",
            "Client configuration complete.",
            "The ipa-client-install command was successful"
        ],
        "stdout": "This program will set up IPA client.\nVersion 4.9.12\n\n\nUsing default chrony configuration.",
        "stdout_lines": [
            "This program will set up IPA client.",
            "Version 4.9.12",
            "",
            "",
            "Using default chrony configuration."
        ]
    }
}

PLAY RECAP ************************************************************************************************************************************************************************************************
client1.otus.lan           : ok=11   changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
client2.otus.lan           : ok=11   changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   



[root@client1 vagrant]# klist
klist: Credentials cache 'KCM:0' not found
[root@client1 vagrant]# kinit admin
Password for admin@OTUS.LAN: 
[root@client1 vagrant]# klist
Ticket cache: KCM:0
Default principal: admin@OTUS.LAN

Valid starting     Expires            Service principal
11/22/23 11:14:35  11/23/23 10:36:14  krbtgt/OTUS.LAN@OTUS.LAN
[root@client1 vagrant]# kdestroy


Клиент установлен


# Попробуем создать пользователя и подключиться им с машины в домен

```shell 
[root@ipa vagrant]# ipa user-add sincere --first=sincere --last=AS --password
ipa: ERROR: did not receive Kerberos credentials
[root@ipa vagrant]# kinit admin
Password for admin@OTUS.LAN: 
[root@ipa vagrant]# ipa user-add sincere --first=sincere --last=AS --password
Password: 
Enter Password again to verify: 
--------------------
Added user "sincere"
--------------------
  User login: sincere
  First name: sincere
  Last name: AS
  Full name: sincere AS
  Display name: sincere AS
  Initials: sAroot
  Home directory: /home/sincere
  GECOS: sincere AS
  Login shell: /bin/sh
  Principal name: sincere@OTUS.LAN
  Principal alias: sincere@OTUS.LAN
  User password expiration: 20231122081959Z
  Email address: sincere@otus.lan
  UID: 938200003
  GID: 938200003
  Password: True
  Member of groups: ipausers
  Kerberos keys available: True
[root@ipa vagrant]# 


```

Отлично

### Проверим вход на клиента под новым логином

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson38-LDAP_FREEIPA/vm$ ssh sincere@192.168.57.11
Password: 
Password expired. Change your password now.
Current Password: 
New password: 
Retype new password: 
Last failed login: Wed Nov 22 11:25:54 MSK 2023 from 192.168.57.1 on ssh:notty
There were 3 failed login attempts since the last successful login.
[sincere@client1 ~]$ sudo -s

We trust you have received the usual lecture from the local System
Administrator. It usually boils down to these three things:

    #1) Respect the privacy of others.
    #2) Think before you type.
    #3) With great power comes great responsibility.

[sudo] password for sincere: 
sincere is not allowed to run sudo on client1.  This incident will be reported.
[sincere@client1 ~]$ 

```

При первом входе предложил поменять пароль - что очень логично. И не пустил под sudo, так как созданный пользователь в IPA очевидно не состоит в wheel/root группах.


### SSH key авторизация.

Можно было при создании пользователя указать public ssh key клиента, так как мы не сделали, то вставим непосредствено в web интерфейсе (но наверняка есть и консольная команда) 

PS  Команда в консоли

```shell
[root@ipa vagrant]# ipa user-mod sincere --sshpubkey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDlI+y4Uk0bDbxHBRAtNl8YDBQ0Upp92ngGgFRwVat1rzMdWu8JxbBeFkDvvQuQUexm5nBpKyZEX2RORBgH5nCNtVMrXOHGqmrakQdJYv0BNh3I1Ol0Vis1TO5wOiLd4GDnRPR4/Sa2t3pqpg+6BXpNy1l38Xs7cwjwqQAlkGRwwx4yE5Oxw/35riTxlNmN2Ox3dMBceTUuEBQrlgM8FoTTXxNMTb/8VFGgsuOyA91VXeexWLNwgg1H8bAu4yxR7KeeS/mTG9NbzcUe2BGwXfXnt5Y3OCvipm220cy1y1N75YoYIAoRuqS6qSBYQCHDGb10uU7Mh3wTN0WyJbJutQnLqZVOGmikLKWQjm02kG/QFevcg5Zuk8Tl4iQDAkLWW6uqcegl799AmviOv0ThnMrJ0BMoFbOIT1oBDC39jm74N477uTjganpG0yIwSRfi7XFMfBzEQYFxydmJUwo3I5kVXAfRhmFXmxd3Ub5Mz9YkoCTH+qmSue3kYP2EP/XVmqE="
-----------------------
Modified user "sincere"
-----------------------
  User login: sincere
  First name: sincere
  Last name: AS
  Home directory: /home/sincere
  Login shell: /bin/sh
  Principal name: sincere@OTUS.LAN
  Principal alias: sincere@OTUS.LAN
  Email address: sincere@otus.lan
  UID: 938200003
  GID: 938200003
  SSH public key: ssh-rsa
                  AAAAB3NzaC1yc2EAAAADAQABAAABgQDlI+y4Uk0bDbxHBRAtNl8YDBQ0Upp92ngGgFRwVat1rzMdWu8JxbBeFkDvvQuQUexm5nBpKyZEX2RORBgH5nCNtVMrXOHGqmrakQdJYv0BNh3I1Ol0Vis1TO5wOiLd4GDnRPR4/Sa2t3pqpg+6BXpNy1l38Xs7cwjwqQAlkGRwwx4yE5Oxw/35riTxlNmN2Ox3dMBceTUuEBQrlgM8FoTTXxNMTb/8VFGgsuOyA91VXeexWLNwgg1H8bAu4yxR7KeeS/mTG9NbzcUe2BGwXfXnt5Y3OCvipm220cy1y1N75YoYIAoRuqS6qSBYQCHDGb10uU7Mh3wTN0WyJbJutQnLqZVOGmikLKWQjm02kG/QFevcg5Zuk8Tl4iQDAkLWW6uqcegl799AmviOv0ThnMrJ0BMoFbOIT1oBDC39jm74N477uTjganpG0yIwSRfi7XFMfBzEQYFxydmJUwo3I5kVXAfRhmFXmxd3Ub5Mz9YkoCTH+qmSue3kYP2EP/XVmqE=
  SSH public key fingerprint: SHA256:K9PgxVgS0SOKc47fe6lGhtq9Ayqp96v9x217IzVB25E (ssh-rsa)
  Account disabled: False
  Password: True
  Member of groups: ipausers
  Kerberos keys available: True


```

В web только проверим, что ключ прописался  -все ок!


Пробуем залогиниться

```shell
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson38-LDAP_FREEIPA/vm/ansible/roles/ipaclient/files$ chmod 600 id_rsa
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson38-LDAP_FREEIPA/vm/ansible/roles/ipaclient/files$ ssh -i ./id_rsa sincere@192.168.57.11
Last login: Wed Nov 22 11:26:23 2023 from 192.168.57.1
[sincere@client1 ~]$ exit
logout
Connection to 192.168.57.11 closed.
sincere@sincere-ubuntuotus:~/vagrantdocs/lesson38-LDAP_FREEIPA/vm/ansible/roles/ipaclient/files$ ssh -i ./id_rsa sincere@192.168.57.10
The authenticity of host '192.168.57.10 (192.168.57.10)' can't be established.
ECDSA key fingerprint is SHA256:7qfccOymzrUYkkgbhFcxJi7GGgRfaTDCqbXI5oxdFbI.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.57.10' (ECDSA) to the list of known hosts.
[sincere@ipa ~]$ 

```

Все работает и это прекрасно!

Маленькое дополнение про SUDO

Так как проверка SUDO стала настроена через sss (часть ipa), то мы можешь создать в IPA Server  политику для группы или пользователя и разрешить ей ALL в sudo

```shell
sh-4.4# cat /etc/nsswitch.conf | grep shadow
# Valid databases are: aliases, ethers, group, gshadow, hosts,
# rpc, services, and shadow.
# shadow:    db files
shadow:     files sss
gshadow:    files
sh-4.4# cat /etc/nsswitch.conf | grep sudo
sudoers:    files sss

```

Скрин из админки в images

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson38-LDAP_FREEIPA/vm/ansible/roles/ipaclient/files$ ssh -i ./id_rsa sincere@192.168.57.11
Last login: Wed Nov 22 13:08:08 2023 from 192.168.57.1
[sincere@client1 ~]$ sudo -s
[sudo] password for sincere: 
sh-4.4# 

```

Пароль для sudo запросил, так как на клиенте нет приватного ключа.

Так как я в большей степени windows админ и хорошо знаком с AD, то на базовом принципе уже понимаю, что с 60% простого функционала USER-GROUPS можно вполне простыми методами закрыть. Наверное пока не увидел аналога GPO, но с PKI и прочим наверное больших проблем не должно быть.
Конечно вопрос если  что-то сломается, то с траблшутингом с учетом количества компонентов пока не очень ясно понятно))

## Домашнее задание выполнено