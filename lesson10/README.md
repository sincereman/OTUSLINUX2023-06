# Lesson10 - BASH

Пишем скрипт
## Цель:

написать скрипт на языке Bash;

## Описание/Пошаговая инструкция выполнения домашнего задания:

Написать скрипт для CRON, который раз в час будет формировать письмо и отправлять на заданную почту.
Необходимая информация в письме:

    Список IP адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;
    Список запрашиваемых URL (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;
    Ошибки веб-сервера/приложения c момента последнего запуска;
    Список всех кодов HTTP ответа с указанием их кол-ва с момента последнего запуска скрипта.
    Скрипт должен предотвращать одновременный запуск нескольких копий, до его завершения.
    В письме должен быть прописан обрабатываемый временной диапазон.


### Описание выполнение


Vagrantfile

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
  config.vm.define "bash" do |bash| 
    bash.vm.network "private_network", ip: "192.168.56.10",  virtualbox__intnet: "net1" 
    bash.vm.hostname = "bash"
    bash.vm.provision "shell", path: "bash.sh"
  end 
end


```

Как обычно запускаем машинку и входим в нее

```shell

vagrant up && vagrant ssh

```

Доустанавливаем apache

```shell
yum -y install httpd


[root@bash vagrant]# systemctl  enable httpd
httpd@          httpd.service   httpd@.service  httpd.socket    
[root@bash vagrant]# systemctl  enable httpd.service 
Created symlink /etc/systemd/system/multi-user.target.wants/httpd.service → /usr/lib/systemd/system/httpd.service.
[root@bash vagrant]# systemctl start  httpd.service 
[root@bash vagrant]# tail -f /var/log/httpd/access.log

Пока там пусто
```

Можно на этом этапе выставить порт наружу, но в целом такого не очень хотело, поэтому я нашел кусок лога на примере которого будем тренироваться писать скрипты.

В целом про предыдущую часть можно забыть))



Берем за образец кусочек лога апача с продакшн сервера - ru.access.log


Значительную часть времени заняло проектирование подхода к выборке, так как четко не указано пишется ли лог последовательно в отношении даты, то после нескольких итераций пришел к пониманию, что нужно разбирать каждый раз файл целиком и каждую строку анализировать на дату, поэтом у в коде будет несколько закомментированных подходов к выборке периода.

Для окончательной сортировки формируем по отобранным строкам в выбранном временном периоде строку и дата в строке удовлетворяет условиям :
1. Больше чем дата предыдущего запуска ()не час а именно дата предыдущего периода - так как выполнение могло не завершиться. (Ну и было доп условие, что если дата не определена то с начала файла)
2. Меньше чем текушая дата.

Метка времени последнего выполнения записывается в файл lasttimestampfile.date
Отобранные строки во временный файл (по прерыванию процесса или по успешному завершению файл удаляется) templogfile.tmp


```shell

#!/bin/bash


USAGE="SYNOPSIS: top_ip_limit.sh logfile"
# cat ru.access.log  | awk '{print $1, $9}' | sort| uniq -c | sort -rn


#Variable
if [ -z "$1" ]
    then
        echo $USAGE
        exit 1
fi

LogFile=$1
#LastTimeStampDateNew=`tail -n 1 $LogFile | awk '{print $5}'`
LogFileTemp=templogfile.tmp
CountString=0
LastTimeStampFile='lasttimestampfile.date'    #file with stamp of time in unixtime
LockFile=top_ip_limit.lock 



#Cleanin when interrupted
cleanup() {
    return_value=$?
    echo "Terminated. Cleaning ..."
    rm -rf $LogFileTemp >> /dev/null
    rm -rf $LockFile >> /dev/null
    exit $return_value
}

trap "cleanup" SIGTERM EXIT 

#cleanbefore start

rm  -rf $LogFileTemp >> /dev/null

Divider="==========================================="
if [ -f "./$LockFile" ]
    then
    echo "Process has already been started" 
    exit 1
fi
touch $LockFile

#Check a tsfile


if [ -f "./$LastTimeStampFile" ]
    then
    if [ -s "./$LastTimeStampFile" ]
        then
        echo "Control File $LastTimeStampFile has data. Read timestampdate from file"
        LastTimeStampDate=`cat ./$LastTimeStampFile`
#        echo CHECK IP SINCE $LastTimeStampDate
    else
        echo "Write a new timestamp to file"
        echo `date +%s` > $LastTimeStampFile
        #echo $LastTimeStampDateNew > $LastTimeStampFile
        LastTimeStampDate=0
    fi
else
    echo "Create a new timestamp and write it to file $LastTimeStampFile"
    #echo $LastTimeStampDateNew > $LastTimeStampFile
    echo `date +%s`  > $LastTimeStampFile
    LastTimeStampDate=0
fi

CurrentTimeStamp=`date +%s`
#CurrentTimeStamp= `date +%s $LastTimeStampDateNew`
Period=`expr $CurrentTimeStamp - $LastTimeStampDate`

echo "SELECT LAST SECONDS: CurrentTime" $CurrentTimeStamp  " - LastTime of Run " $LastTimeStampDate " = " $Period "last seconds"

#Define string for GREP

FindStringTime=`date -d @$LastTimeStampDate  +%d/%b/%Y:%H:%M:%S`
#FindStringTime="24/Mar/2022:00:05:55"
echo "Time when script was runned last time" $FindStringTime
echo $Divider

#Process

#Check count a string in a LogFile


StringCountLogFile=`wc -l ./$LogFile`
#StringCountLogFile=`sed -n '$=' $LogFile`
#StringCountFirst=`awk "match($0,$FindStringTime){ print NR; exit }" ./$LogFile`
#StringCountFirst=`grep -n  $FindStringTime $LogFile | head -n 1 | cut -d: -f1`
#if [ -n $StringCountFirst ]
#    then
#    StringCountFirst=0
#    echo  "Not Found line start from" $StringCountFirst " string"
#fi
#
#TotalLineForAnalyse=`expr $StringCountLogFile - $StringCountFirst`
#echo $Divider
#echo "Analyse from " $StringCountFirst " to " $StringCountLogFile " Total: " $TotalLineForAnalyse

echo "Analyze Date From Log File. Wait please..."
echo $Divider
while IFS= read -r line; do
    LineDate=`echo $line  | awk '{print $4}'| tr -d "\["`
    LineDateUnixTime=`date -d "$(echo $LineDate | sed -e 's,/,-,g' -e 's,:, ,')" +"%s"`
    let CountString=CountString+1
    printf "\rAnalyze string $CountString of $StringCountLogFile" 
    if [ "$LineDateUnixTime" -gt "$LastTimeStampDate" ]
        then
        printf "\rAnalyze string $CountString of $StringCountLogFile  - String $CountString add to analyse  (MinDate:  $LastTimeStampDate < DateOfString:  $LineDateUnixTime < CurrentDate:  $CurrentTimeStamp )"
        echo $line >> $LogFileTemp
    fi
done < $LogFile


echo $Divider
echo "Sort by top ip:"
cat $LogFileTemp | awk '{print $1, $9}' | sort| uniq -c | sort -rn | head -n 20

echo $Divider
echo "Sort by URL:"
cat $LogFileTemp | awk '{print $7}' | sort| uniq -c | sort -rn | head -n 20

echo $Divider
echo "Error WEB Servers From Last Time:"
cat $LogFileTemp | awk 'BEGIN { FS = "\" "; OFS= "#"} ; {print $0,$2}' | awk 'BEGIN { FS = "#" }; { if (!(match($2,/2.*/))) { print $1 }}'

echo $Divider
echo "Sort by top Code:"
cat $LogFileTemp | awk '{print $9}' | sort| uniq -c | sort -rn 

#cat $LogFile | grep -e "$FindStringTime" -A $TotalLineForAnalyse | awk '{print $1, $9}' | sort| uniq -c | sort -rn
#cat $LogFile  | awk '{print $4}'| tr -d "\["

#Запишем новую дату
#tail -n 1 ru.access.log | awk '{print $5}'
echo $CurrentTimeStamp > $LastTimeStampFile


#generate test data
#LANG=en_EN
echo '194.58.113.39 - - ['$(LANG=en_EN date  +%d/%b/%Y:%H:%M:%S)' +0300] "GET / HTTP/1.0" 301 328 "-" "-"\n ' >> $LogFile
#echo '194.58.113.39 - - ['$(LANG=en_EN date -u  +%d/%b/%Y:%H:%M:%S)' +0300] "GET / HTTP/1.0" 301 328 "-" "-"\n ' >> $LogFile
sleep 2 
echo '95.163.36.4 - - ['$(LANG=en_EN date  +%d/%b/%Y:%H:%M:%S)' +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"\n ' >> $LogFile



exit 0

```

Для добавления в cron выполнить команду

```shell
echo "* */1	* * *	root    ./top_ip_limit.sh" >> /etc/crontab
```


## Список IP адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;

ключевая строка

```shell
echo "Sort by top ip:"
cat $LogFileTemp | awk '{print $1, $9}' | sort| uniq -c | sort -rn | head -n 20


### Cписок запрашиваемых URL (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;

echo "Sort by URL:"
cat $LogFileTemp | awk '{print $7}' | sort| uniq -c | sort -rn

###Ошибки веб-сервера/приложения c момента последнего запуска;

echo "Error From Last Time:"
cat $LogFileTemp | awk 'BEGIN { FS = "\" "; OFS= "#"} ; {print $0,$2}' | awk 'BEGIN { FS = "#" }; { if (!(match($2,/2.*/))) { print $1 }}'

###Список всех кодов HTTP ответа с указанием их кол-ва с момента последнего запуска скрипта.

cat $LogFileTemp | awk '{print $9}' | sort| uniq -c | sort -rn 

###Скрипт должен предотвращать одновременный запуск нескольких копий, до его завершения.

Реализован LockFile/


###В письме должен быть прописан обрабатываемый временной диапазон.

Функция отправки письма...

Отправка письма может быть настроена несколькими способами

https://rtcamp.com/tutorials/linux/ubuntu-postfix-gmail-smtp/ - представим что настроена по вышеуказанной статье


echo "MailBody" | mail -s "Message Subject" recipient@example.com



./top_limit_ip.sh $LogFile | mail -s "Message Subject" recipient@example.com


```

## Вывод

### Первый запуск

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson10$ ./top_ip_limit.sh ru.access.log
Control File lasttimestampfile.date has data. Read timestampdate from file
SELECT LAST SECONDS: CurrentTime 1691856504  - LastTime of Run  0  =  1691856504 last seconds
Time when script was runned last time 01/янв/1970:03:00:00
===========================================
Analyze Date From Log File. Wait please...
===========================================
Analyze string 7049 of 7049 ./ru.access.log  - String 7049 add to analyse  (MinDate:  0 < DateOfString:  1691856070 < CurrentDate:  1691856504 )===========================================
Sort by top ip:
    208 141.8.142.72 200
    207 46.8.50.166 200
    200 94.25.169.182 200
    194 109.196.140.144 200
    193 5.183.29.115 200
    184 91.232.80.11 200
    174 188.170.72.169 200
    139 213.87.135.75 200
    136 87.249.25.21 200
    129 212.33.240.241 200
    122 5.45.207.132 200
    122 185.36.158.114 200
    121 37.193.7.171 200
    118 185.181.247.42 200
    117 213.33.227.86 200
    113 79.105.18.172 200
    113 217.118.90.130 200
    107 94.25.173.198 200
    106 91.193.179.102 200
     96 31.173.120.228 200
===========================================
Sort by URL:
    564 /
    156 /ds-comf/ds-form/main.php?m=getcss
     97 /autodiscover/autodiscover.xml
     82 /js/jcarusel/jquery.jcarousel.js
     81 /robots.txt
     77 /bitrix/js/main/core/core_db.min.js?153357781310247
     76 /js/jquery.formstyler.min.js
     75 /bitrix/templates/bamard/js/my.slider.js
     75 /bitrix/templates/bamard/js/jquery.maskedinput.min.js
     75 /bitrix/templates/bamard/components/bitrix/menu/top-main/script.js?1542706233627
     75 /bitrix/js/main/core/core_promise.min.js?15517047772478
     74 /bitrix/templates/bamard/flash-slider/slider.js
     74 /bitrix/js/main/loadext/loadext.min.js?1551704826810
     74 /bitrix/js/main/loadext/extension.min.js?15517048261304
     74 /bitrix/js/main/core/core_fx.min.js?15335775819768
     73 /js/height.js
     73 /bitrix/templates/bamard/js/script.js
     73 /bitrix/js/main/core/core_ajax.min.js?155170483723951
     72 /slick/slick.min.js
     72 /js/jquery-1.10.2.min.js
===========================================
Error WEB Servers From Last Time:
95.163.36.7 - - [23/Mar/2022:00:05:16 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
78.109.66.253 - - [23/Mar/2022:00:08:15 +0300] "GET /auth.php?login=yes HTTP/1.0" 301 346 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/71.0.3542.0 Safari/537.36"
78.109.66.253 - - [23/Mar/2022:00:08:15 +0300] "GET /forum/ HTTP/1.0" 301 334 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/71.0.3542.0 Safari/537.36"
78.109.66.253 - - [23/Mar/2022:00:08:16 +0300] "GET /communication/forum/ HTTP/1.0" 301 348 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/71.0.3542.0 Safari/537.36"
78.109.66.253 - - [23/Mar/2022:00:08:16 +0300] "GET /community/forum/ HTTP/1.0" 301 344 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/71.0.3542.0 Safari/537.36"
78.109.66.253 - - [23/Mar/2022:00:08:16 +0300] "GET /about/forum/ HTTP/1.0" 301 340 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/71.0.3542.0 Safari/537.36"
78.109.66.253 - - [23/Mar/2022:00:08:17 +0300] "GET /forum.php HTTP/1.0" 301 337 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/71.0.3542.0 Safari/537.36"
78.109.66.253 - - [23/Mar/2022:00:08:17 +0300] "GET /phorum/ HTTP/1.0" 301 335 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/71.0.3542.0 Safari/537.36"
207.46.13.229 - - [23/Mar/2022:00:23:21 +0300] "GET /robots.txt HTTP/1.0" 301 338 "-" "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"
157.55.39.182 - - [23/Mar/2022:00:23:42 +0300] "GET /bitrix/templates/bamard/components/bitrix/catalog.section/.default/script.js?1542706232353 HTTP/1.0" 301 418 "-" "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)"
95.163.36.14 - - [23/Mar/2022:00:23:53 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
87.251.83.70 - - [23/Mar/2022:00:32:35 +0300] "GET /katalog/maxi-grass/ HTTP/1.0" 301 351 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
109.196.167.24 - - [23/Mar/2022:00:34:04 +0300] "GET /katalog/begovye-dorozhki/ HTTP/1.0" 301 357 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
109.196.167.28 - - [23/Mar/2022:00:34:04 +0300] "GET /katalog/begovye-dorozhki/ HTTP/1.0" 301 357 "-" "Mozilla/5.0 (Linux; Android 7.0; SM-G892A Build/NRD90M; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/60.0.3112.107 Mobile Safari/537.36"
109.196.167.48 - - [23/Mar/2022:00:34:04 +0300] "GET /katalog/parket/boflex-stadium-28mm/ HTTP/1.0" 301 367 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
109.196.167.48 - - [23/Mar/2022:00:34:04 +0300] "GET /katalog/parket/boflex-stadium-28mm/ HTTP/1.0" 301 377 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
109.196.167.48 - - [23/Mar/2022:00:34:05 +0300] "GET /katalog/sportivnyj-parket/boflex-stadium-28mm/ HTTP/1.0" 301 378 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
109.196.167.48 - - [23/Mar/2022:00:34:05 +0300] "GET /katalog/sportivnyj-parket/boflex-stadium-28mm/ HTTP/1.0" 404 10546 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
109.196.167.50 - - [23/Mar/2022:00:34:05 +0300] "GET /katalog/parket/boflex-stadium-28mm/ HTTP/1.0" 301 367 "-" "Mozilla/5.0 (Linux; Android 7.0; SM-G892A Build/NRD90M; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/60.0.3112.107 Mobile Safari/537.36"
109.196.167.50 - - [23/Mar/2022:00:34:05 +0300] "GET /katalog/parket/boflex-stadium-28mm/ HTTP/1.0" 301 377 "-" "Mozilla/5.0 (Linux; Android 7.0; SM-G892A Build/NRD90M; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/60.0.3112.107 Mobile Safari/537.36"
109.196.167.50 - - [23/Mar/2022:00:34:05 +0300] "GET /katalog/sportivnyj-parket/boflex-stadium-28mm/ HTTP/1.0" 301 378 "-" "Mozilla/5.0 (Linux; Android 7.0; SM-G892A Build/NRD90M; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/60.0.3112.107 Mobile Safari/537.36"
109.196.167.50 - - [23/Mar/2022:00:34:05 +0300] "GET /katalog/sportivnyj-parket/boflex-stadium-28mm/ HTTP/1.0" 404 10545 "-" "Mozilla/5.0 (Linux; Android 7.0; SM-G892A Build/NRD90M; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/60.0.3112.107 Mobile Safari/537.36"
109.196.167.58 - - [23/Mar/2022:00:34:05 +0300] "GET /o-kompanii/ HTTP/1.0" 301 343 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
109.196.167.64 - - [23/Mar/2022:00:34:05 +0300] "GET /o-kompanii/ HTTP/1.0" 301 343 "-" "Mozilla/5.0 (Linux; Android 7.0; SM-G892A Build/NRD90M; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/60.0.3112.107 Mobile Safari/537.36"
95.163.36.7 - - [23/Mar/2022:00:43:43 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
87.251.83.70 - - [23/Mar/2022:00:58:54 +0300] "GET /o-kompanii/nashi-obekty/ HTTP/1.0" 301 356 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
95.163.36.6 - - [23/Mar/2022:01:07:18 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
66.249.89.235 - - [23/Mar/2022:01:13:45 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 374 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
66.249.89.239 - - [23/Mar/2022:01:13:45 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 331 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
95.163.36.13 - - [23/Mar/2022:01:23:44 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
87.251.83.70 - - [23/Mar/2022:01:25:45 +0300] "GET /uslugi/ukladka-i-ukhod/ HTTP/1.0" 301 355 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
95.163.36.15 - - [23/Mar/2022:01:44:28 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
87.251.83.70 - - [23/Mar/2022:01:59:04 +0300] "GET /uslugi/obogrev-futbolnogo-polya/ HTTP/1.0" 301 364 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
95.163.36.13 - - [23/Mar/2022:02:05:25 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
66.249.64.172 - - [23/Mar/2022:02:21:53 +0300] "GET /proektirovanie.html HTTP/1.0" 301 351 "-" "Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.82 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
95.163.36.6 - - [23/Mar/2022:02:23:47 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
141.8.142.72 - - [23/Mar/2022:02:25:31 +0300] "GET /images/pages/10.jpg HTTP/1.0" 301 351 "-" "Mozilla/5.0 (compatible; YandexImages/3.0; +http://yandex.com/bots)"
87.251.83.70 - - [23/Mar/2022:02:36:57 +0300] "GET /uslugi/ukladka-futbolnykh-poley/ HTTP/1.0" 301 364 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
66.249.93.235 - - [23/Mar/2022:02:38:41 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 374 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
66.249.93.235 - - [23/Mar/2022:02:38:41 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 331 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
66.249.64.176 - - [23/Mar/2022:02:41:06 +0300] "GET /uslugi/obogrev-futbolnogo-polya/ HTTP/1.0" 304 - "-" "Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.82 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
95.163.36.7 - - [23/Mar/2022:02:43:42 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
95.163.255.121 - - [23/Mar/2022:02:57:43 +0300] "GET /robots.txt HTTP/1.0" 301 338 "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Img/2.0; +http://go.mail.ru/help/robots)"
95.163.255.129 - - [23/Mar/2022:02:57:51 +0300] "GET /upload/iblock/690/03_s.jpg HTTP/1.0" 301 354 "http://go.mail.ru/search_images" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Img/2.0; +http://go.mail.ru/help/robots)"
95.163.36.14 - - [23/Mar/2022:03:04:06 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
87.251.83.70 - - [23/Mar/2022:03:05:52 +0300] "GET /uslugi/sistema-poliva-futbolnykh-poley/ HTTP/1.0" 301 371 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
95.163.36.6 - - [23/Mar/2022:03:22:51 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
87.251.83.70 - - [23/Mar/2022:03:42:55 +0300] "GET /katalog/sportivnye-rezinovye-pokrytiya/ HTTP/1.0" 301 371 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
35.243.255.13 - - [23/Mar/2022:03:44:00 +0300] "GET /robots.txt HTTP/1.0" 301 338 "-" "ZoominfoBot (zoominfobot at zoominfo dot com)"
95.163.36.4 - - [23/Mar/2022:03:45:14 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
114.119.138.28 - - [23/Mar/2022:03:59:27 +0300] "GET /katalog/product/maxi-grass-f12 HTTP/1.0" 301 363 "-" "Mozilla/5.0 (Linux; Android 7.0;) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36 (compatible; PetalBot;+https://webmaster.petalsearch.com/site/petalbot)"
95.163.36.5 - - [23/Mar/2022:04:04:34 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
20.223.185.232 - - [23/Mar/2022:04:09:44 +0300] "GET /.env HTTP/1.0" 404 10373 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:77.0) Gecko/20100101 Firefox/77.0"
20.223.185.232 - - [23/Mar/2022:04:09:44 +0300] "GET /wp-content/ HTTP/1.0" 301 339 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:77.0) Gecko/20100101 Firefox/77.0"
20.223.185.232 - - [23/Mar/2022:04:09:44 +0300] "GET /wp-content/ HTTP/1.0" 404 10371 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:77.0) Gecko/20100101 Firefox/77.0"
207.46.13.156 - - [23/Mar/2022:04:18:28 +0300] "GET /katalog/maty/sportivnye-maty-bsw-/ HTTP/1.0" 301 376 "-" "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"
95.163.36.4 - - [23/Mar/2022:04:24:15 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
87.251.83.70 - - [23/Mar/2022:04:25:13 +0300] "GET /sitemap/ HTTP/1.0" 301 340 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
66.249.64.174 - - [23/Mar/2022:04:39:37 +0300] "GET /katalog/dlya-sporta/ HTTP/1.0" 301 363 "-" "Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.82 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.64.174 - - [23/Mar/2022:04:39:38 +0300] "GET /katalog/trava-futbolnogo-polya/ HTTP/1.0" 301 378 "-" "Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.82 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
185.5.249.185 - - [23/Mar/2022:04:40:57 +0300] "HEAD / HTTP/1.0" 301 - "https://obogrevatel-mag.ru/ulichnye-gazovye-obogrevateli/grib-zontik/" "Mozilla/4.0 (compatible; MSIE4.00; Windows 2008)"
194.67.207.94 - - [23/Mar/2022:04:40:58 +0300] "HEAD / HTTP/1.0" 301 - "https://mf-group.com/" "Mozilla/5.0 (compatible; MSIE5.00; Windows 2003)"
95.163.36.13 - - [23/Mar/2022:04:43:02 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
154.6.18.75 - - [23/Mar/2022:04:45:08 +0300] "GET /personal/ HTTP/1.0" 301 337 "http://bamard-sport.ru/personal/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.85 Safari/537.36 Edg/90.0.818.46"
154.6.18.75 - - [23/Mar/2022:04:45:11 +0300] "POST /personal/ HTTP/1.0" 403 118 "https://www.bamard-sport.ru/personal/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.85 Safari/537.36 Edg/90.0.818.46"
34.86.35.2 - - [23/Mar/2022:04:54:02 +0300] "GET / HTTP/1.0" 200 66675 "-" "Expanse, a Palo Alto Networks company, searches across the global IPv4 space multiple times per day to identify customers&
35.210.80.43 - - [23/Mar/2022:04:56:14 +0300] "GET /robots.txt HTTP/1.0" 301 338 "-" "Go-http-client/1.1"
35.210.80.43 - - [23/Mar/2022:04:56:17 +0300] "GET /uslugi/stroitelstvo-sportivnyh-sooruzheny HTTP/1.0" 301 370 "-" "Mozilla/5.0 (compatible; VelenPublicWebCrawler/1.0; +https://velen.io)"
95.163.36.4 - - [23/Mar/2022:05:04:42 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
194.67.207.9 - - [23/Mar/2022:05:08:42 +0300] "HEAD / HTTP/1.0" 301 - "https://steamauthenticator.ru/" "Mozilla/8.0 (compatible; MSIE6.00; Windows 2002)"
194.67.210.77 - - [23/Mar/2022:05:13:12 +0300] "HEAD / HTTP/1.0" 301 - "https://actorz.ru/" "Mozilla/8.0 (compatible; MSIE4.00; Windows 2002)"
66.249.89.237 - - [23/Mar/2022:05:15:01 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 374 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
66.249.89.237 - - [23/Mar/2022:05:15:01 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 331 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
87.251.83.70 - - [23/Mar/2022:05:17:44 +0300] "GET /katalog/sportivnyj-parket/ HTTP/1.0" 301 358 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
95.163.36.13 - - [23/Mar/2022:05:23:16 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
95.163.36.7 - - [23/Mar/2022:05:42:58 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
87.251.83.70 - - [23/Mar/2022:05:43:05 +0300] "GET /uslugi/usloviya-predostavleniya-garantii-na-iskusstvennoe-travyanoe-pokrytie/ HTTP/1.0" 301 409 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
95.163.36.13 - - [23/Mar/2022:06:05:50 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
87.251.83.70 - - [23/Mar/2022:06:09:11 +0300] "GET /katalog/stadio-grass/ HTTP/1.0" 301 353 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
95.163.36.5 - - [23/Mar/2022:06:23:26 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
66.249.93.239 - - [23/Mar/2022:06:32:19 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 374 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
66.249.93.232 - - [23/Mar/2022:06:32:20 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 331 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
95.163.36.6 - - [23/Mar/2022:06:44:06 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
87.251.83.70 - - [23/Mar/2022:06:50:57 +0300] "GET /uslugi/instruktsiya-po-ukhodu-za-iskusstvennym-travyanym-pokrytiem/ HTTP/1.0" 301 399 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
114.119.138.230 - - [23/Mar/2022:07:04:13 +0300] "GET /katalog/product/sportivnye-maty-bsw-1000x1500-mm HTTP/1.0" 301 381 "-" "Mozilla/5.0 (Linux; Android 7.0;) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36 (compatible; PetalBot;+https://webmaster.petalsearch.com/site/petalbot)"
95.163.36.14 - - [23/Mar/2022:07:04:41 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
114.119.138.27 - - [23/Mar/2022:07:23:20 +0300] "GET /vidy-sporta/obshchie-razdevalki-vykhody-i-prokhody HTTP/1.0" 301 383 "-" "Mozilla/5.0 (Linux; Android 7.0;) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36 (compatible; PetalBot;+https://webmaster.petalsearch.com/site/petalbot)"
95.163.36.7 - - [23/Mar/2022:07:24:57 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
207.46.13.156 - - [23/Mar/2022:07:32:22 +0300] "GET /spectech_10.html HTTP/1.0" 301 348 "-" "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"
95.163.36.6 - - [23/Mar/2022:07:43:38 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
114.119.138.230 - - [23/Mar/2022:07:49:26 +0300] "GET /upload/resize_cache/iblock/d45/92_64_2/f_11.jpg HTTP/1.0" 301 375 "-" "Mozilla/5.0 (Linux; Android 7.0;) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36 (compatible; PetalBot;+https://webmaster.petalsearch.com/site/petalbot)"
95.163.255.137 - - [23/Mar/2022:07:52:54 +0300] "GET /robots.txt HTTP/1.0" 301 338 "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/2.0; +http://go.mail.ru/help/robots)"
87.251.83.70 - - [23/Mar/2022:07:57:21 +0300] "GET /katalog/gotovye-resheniya/ HTTP/1.0" 301 358 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
5.45.207.146 - - [23/Mar/2022:08:00:43 +0300] "GET /images/m2.jpg HTTP/1.0" 301 345 "-" "Mozilla/5.0 (compatible; YandexImages/3.0; +http://yandex.com/bots)"
95.163.36.14 - - [23/Mar/2022:08:05:28 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
141.8.142.66 - - [23/Mar/2022:08:16:10 +0300] "GET /images/pages/11/13.jpg HTTP/1.0" 301 354 "-" "Mozilla/5.0 (compatible; YandexImages/3.0; +http://yandex.com/bots)"
35.206.158.187 - - [23/Mar/2022:08:17:07 +0300] "GET /robots.txt HTTP/1.0" 301 338 "-" "Go-http-client/1.1"
35.206.158.187 - - [23/Mar/2022:08:17:10 +0300] "GET /uslugi/stroitelstvo-novykh-stadionov HTTP/1.0" 301 365 "-" "Mozilla/5.0 (compatible; VelenPublicWebCrawler/1.0; +https://velen.io)"
95.163.36.8 - - [23/Mar/2022:08:22:56 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
114.119.138.230 - - [23/Mar/2022:08:33:18 +0300] "GET /katalog/product/pritsepnoe-ustroystvo-dc-1600/ HTTP/1.0" 301 374 "-" "Mozilla/5.0 (Linux; Android 7.0;) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36 (compatible; PetalBot;+https://webmaster.petalsearch.com/site/petalbot)"
87.251.83.70 - - [23/Mar/2022:08:33:24 +0300] "GET /uslugi/ HTTP/1.0" 301 339 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
141.8.142.72 - - [23/Mar/2022:08:42:03 +0300] "GET /images/adv/5.png HTTP/1.0" 301 348 "-" "Mozilla/5.0 (compatible; YandexImages/3.0; +http://yandex.com/bots)"
95.163.36.4 - - [23/Mar/2022:08:44:23 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
35.210.78.159 - - [23/Mar/2022:08:57:50 +0300] "GET /katalog/product/regupol-elastic-tiles-e43 HTTP/1.0" 301 370 "-" "Mozilla/5.0 (compatible; VelenPublicWebCrawler/1.0; +https://velen.io)"
95.163.36.6 - - [23/Mar/2022:09:05:36 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
87.251.83.70 - - [23/Mar/2022:09:06:00 +0300] "GET /katalog/iskusstvennaya-trava-futbolnogo-polya/ HTTP/1.0" 301 378 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
66.249.81.152 - - [23/Mar/2022:09:13:46 +0300] "GET /.well-known/traffic-advice HTTP/1.0" 301 359 "-" "Chrome Privacy Preserving Prefetch Proxy"
66.249.89.237 - - [23/Mar/2022:09:15:38 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 374 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
66.249.89.237 - - [23/Mar/2022:09:15:39 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 331 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
95.142.121.69 - - [23/Mar/2022:09:17:30 +0300] "GET /katalog/trava-futbolnogo-polya/ HTTP/1.0" 301 363 "http://www.bamard-sport.ru/katalog/trava-futbolnogo-polya/" "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36"
95.142.121.69 - - [23/Mar/2022:09:17:31 +0300] "GET /katalog/trava-futbolnogo-polya/ HTTP/1.0" 301 378 "https://www.bamard-sport.ru/katalog/trava-futbolnogo-polya/" "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36"
95.108.213.72 - - [23/Mar/2022:09:23:21 +0300] "GET /upload/medialibrary/30a/03_b.jpg HTTP/1.0" 301 364 "-" "Mozilla/5.0 (compatible; YandexImages/3.0; +http://yandex.com/bots)"
95.163.36.8 - - [23/Mar/2022:09:25:18 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
87.251.83.70 - - [23/Mar/2022:09:30:51 +0300] "GET /uslugi/stroitelstvo-novykh-stadionov/ HTTP/1.0" 301 369 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
35.210.137.15 - - [23/Mar/2022:09:38:49 +0300] "GET /robots.txt HTTP/1.0" 301 338 "-" "Go-http-client/1.1"
35.210.137.15 - - [23/Mar/2022:09:38:53 +0300] "GET /robots.txt HTTP/1.0" 301 338 "-" "Go-http-client/1.1"
35.210.137.15 - - [23/Mar/2022:09:38:53 +0300] "GET /katalog/sportivnye-rezinovye-pokrytiya HTTP/1.0" 301 367 "-" "Mozilla/5.0 (compatible; VelenPublicWebCrawler/1.0; +https://velen.io)"
95.163.36.14 - - [23/Mar/2022:09:43:52 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
87.251.83.70 - - [23/Mar/2022:09:56:22 +0300] "GET /katalog/spetsializirovannaya-tekhnika/ HTTP/1.0" 301 370 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
66.249.64.148 - - [23/Mar/2022:10:02:06 +0300] "GET /stati/pol-tancevalnyj-zal/ HTTP/1.0" 304 - "-" "Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.82 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
95.163.36.8 - - [23/Mar/2022:10:05:40 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
34.77.162.20 - - [23/Mar/2022:10:10:40 +0300] "GET / HTTP/1.0" 301 332 "-" "Expanse, a Palo Alto Networks company, searches across the global IPv4 space multiple times per day to identify customers&
35.206.147.48 - - [23/Mar/2022:10:19:38 +0300] "GET /robots.txt HTTP/1.0" 301 338 "-" "Go-http-client/1.1"
35.206.147.48 - - [23/Mar/2022:10:19:41 +0300] "GET /uslugi/stroitelstvo-futbolnykh-poley/stroitelstvo-futbolnogo-polya-s-naturalnym-gazonom HTTP/1.0" 301 416 "-" "Mozilla/5.0 (compatible; VelenPublicWebCrawler/1.0; +https://velen.io)"
185.22.235.145 - - [23/Mar/2022:10:22:11 +0300] "GET /radio.php HTTP/1.0" 301 337 "-" "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 YaBrowser/20.9.3.136 Yowser/2.5 Safari/537.36"
95.163.36.8 - - [23/Mar/2022:10:23:20 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
157.55.39.182 - - [23/Mar/2022:10:29:32 +0300] "GET /map.html HTTP/1.0" 301 340 "-" "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"
66.249.64.26 - - [23/Mar/2022:10:30:27 +0300] "GET /ads.txt HTTP/1.0" 301 335 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.64.19 - - [23/Mar/2022:10:30:28 +0300] "GET /ads.txt HTTP/1.0" 301 335 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
66.249.64.142 - - [23/Mar/2022:10:30:28 +0300] "GET /ads.txt HTTP/1.0" 404 10374 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
95.163.36.5 - - [23/Mar/2022:10:43:13 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
62.173.152.68 - - [23/Mar/2022:10:44:24 +0300] "GET /robots.txt HTTP/1.0" 301 338 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36"
212.33.240.241 - - [23/Mar/2022:10:48:55 +0300] "GET /katalog/product/euro-grass-m60/ HTTP/1.0" 304 - "https://www.bamard-sport.ru/katalog/euro-grass/" "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.174 YaBrowser/22.1.5.812 Yowser/2.5 Safari/537.36"
87.251.83.70 - - [23/Mar/2022:10:52:13 +0300] "GET /katalog/regumond/ HTTP/1.0" 301 349 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
193.27.41.100 - - [23/Mar/2022:10:52:56 +0300] "GET /uslugi/stabilizatsiya-osnovaniya/stabilizatsionnyy-polimernyy-monoblok/ HTTP/1.0" 304 - "https://www.bamard-sport.ru/uslugi/stabilizatsiya-osnovaniya/stabilizatsionnyy-polimernyy-monoblok/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.174 YaBrowser/22.1.4.837 Yowser/2.5 Safari/537.36"
193.27.41.100 - - [23/Mar/2022:10:53:19 +0300] "GET /bitrix/spread.php?s=VkpTVmNKMVRfU0FMRV9VSUQBODI5OQExNjc5MTI1OTk5AS8BAQEC&k=7c6ca97e3cdbdb82957e04a14c4b33cd HTTP/1.0" 301 439 "https://www.bamard-sport.ru/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.174 YaBrowser/22.1.4.837 Yowser/2.5 Safari/537.36"
87.250.224.26 - - [23/Mar/2022:10:53:59 +0300] "GET /sitemap.xml HTTP/1.0" 301 343 "-" "Mozilla/5.0 (compatible; YandexBot/3.0; +http://yandex.com/bots)"
193.27.41.100 - - [23/Mar/2022:10:54:46 +0300] "GET /uslugi/stabilizatsiya-osnovaniya/stabilizatsionnyy-polimernyy-monoblok/ HTTP/1.0" 304 - "https://www.bamard-sport.ru/uslugi/stabilizatsiya-osnovaniya/stabilizatsionnyy-polimernyy-monoblok/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.174 YaBrowser/22.1.4.837 Yowser/2.5 Safari/537.36"
66.249.89.67 - - [23/Mar/2022:10:55:30 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 374 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
66.249.89.77 - - [23/Mar/2022:10:55:30 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 331 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
95.163.36.15 - - [23/Mar/2022:11:05:00 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
176.53.217.53 - - [23/Mar/2022:11:05:24 +0300] "GET /favicon.ico HTTP/1.0" 301 339 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36"
89.113.127.79 - - [23/Mar/2022:11:19:26 +0300] "GET /katalog/sportivnye-rezinovye-pokrytiya/ HTTP/1.0" 304 - "-" "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1"
89.113.127.79 - - [23/Mar/2022:11:19:26 +0300] "GET /bitrix/templates/bamard/template_styles.css?164752237566008 HTTP/1.0" 304 - "https://www.bamard-sport.ru/katalog/sportivnye-rezinovye-pokrytiya/" "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1"
87.251.83.70 - - [23/Mar/2022:11:21:32 +0300] "GET /katalog/soputstvuyushchie-tovary/ HTTP/1.0" 301 365 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
95.163.36.5 - - [23/Mar/2022:11:24:51 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
185.181.247.42 - - [23/Mar/2022:11:25:01 +0300] "GET /auth.php?login=yes HTTP/1.0" 301 346 "-" "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3202.75 Safari/537.36"
185.181.247.42 - - [23/Mar/2022:11:25:24 +0300] "GET /forum/ HTTP/1.0" 301 334 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36"
185.181.247.42 - - [23/Mar/2022:11:25:24 +0300] "GET /forum/ HTTP/1.0" 404 10373 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36"
185.181.247.42 - - [23/Mar/2022:11:25:31 +0300] "GET /communication/forum/ HTTP/1.0" 301 348 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36"
185.181.247.42 - - [23/Mar/2022:11:25:31 +0300] "GET /communication/forum/ HTTP/1.0" 404 10373 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36"
185.181.247.42 - - [23/Mar/2022:11:25:37 +0300] "GET /community/forum/ HTTP/1.0" 301 344 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36"
185.181.247.42 - - [23/Mar/2022:11:25:38 +0300] "GET /community/forum/ HTTP/1.0" 404 10373 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36"
185.181.247.42 - - [23/Mar/2022:11:25:44 +0300] "GET /about/forum/ HTTP/1.0" 301 340 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36"
185.181.247.42 - - [23/Mar/2022:11:25:44 +0300] "GET /about/forum/ HTTP/1.0" 404 10373 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36"
185.181.247.42 - - [23/Mar/2022:11:25:50 +0300] "GET /support/forum/ HTTP/1.0" 404 10371 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36"
185.181.247.42 - - [23/Mar/2022:11:25:56 +0300] "GET /forum.php HTTP/1.0" 301 337 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36"
185.181.247.42 - - [23/Mar/2022:11:26:03 +0300] "GET /phorum/ HTTP/1.0" 301 335 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36"
185.181.247.42 - - [23/Mar/2022:11:26:03 +0300] "GET /phorum/ HTTP/1.0" 404 10373 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36"
185.181.247.42 - - [23/Mar/2022:11:26:09 +0300] "GET /blogs/ HTTP/1.0" 301 334 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36"
185.181.247.42 - - [23/Mar/2022:11:26:09 +0300] "GET /blogs/ HTTP/1.0" 404 10373 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36"
185.181.247.42 - - [23/Mar/2022:11:26:15 +0300] "GET /blog/ HTTP/1.0" 301 333 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36"
185.181.247.42 - - [23/Mar/2022:11:26:20 +0300] "GET /club/ HTTP/1.0" 301 333 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36"
185.181.247.42 - - [23/Mar/2022:11:26:24 +0300] "GET / HTTP/1.0" 304 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36"
185.181.247.42 - - [23/Mar/2022:11:26:39 +0300] "GET /search/index.php?q=ezoqe&s=%D0%9F%D0%BE%D0%B8%D1%81%D0%BA HTTP/1.0" 301 384 "https://www.bamard-sport.ru/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36"
5.255.253.185 - - [23/Mar/2022:11:31:09 +0300] "GET /about/forum/ HTTP/1.0" 404 10371 "-" "Mozilla/5.0 (compatible; YandexBot/3.0; +http://yandex.com/bots)"
95.163.255.146 - - [23/Mar/2022:11:41:01 +0300] "GET /favicon.png HTTP/1.0" 404 10373 "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Favicons/2.0; +https://help.mail.ru/webmaster/indexing/robots)"
80.250.211.149 - - [23/Mar/2022:11:42:54 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
95.163.36.7 - - [23/Mar/2022:11:43:23 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
80.250.211.149 - - [23/Mar/2022:11:49:02 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
87.251.83.70 - - [23/Mar/2022:11:54:20 +0300] "GET /o-kompanii/stroitelnye-moshchnosti/ HTTP/1.0" 301 367 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
80.250.211.149 - - [23/Mar/2022:11:55:08 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
95.163.255.144 - - [23/Mar/2022:11:57:43 +0300] "GET /favicon.png HTTP/1.0" 404 10373 "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Favicons/2.0; +https://help.mail.ru/webmaster/indexing/robots)"
80.250.211.149 - - [23/Mar/2022:12:01:18 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
66.249.64.142 - - [23/Mar/2022:12:02:45 +0300] "GET /bitrix/templates/bamard/images/footbal/stabilization-system/text.png HTTP/1.0" 304 - "-" "Googlebot-Image/1.0"
95.163.36.8 - - [23/Mar/2022:12:06:28 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
80.250.211.149 - - [23/Mar/2022:12:07:25 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:12:13:59 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
207.46.13.156 - - [23/Mar/2022:12:17:27 +0300] "GET /genre/A90086/ HTTP/1.0" 404 10373 "-" "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"
80.250.211.149 - - [23/Mar/2022:12:20:05 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
95.163.36.13 - - [23/Mar/2022:12:23:57 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
35.210.5.38 - - [23/Mar/2022:12:25:18 +0300] "GET /robots.txt HTTP/1.0" 301 338 "-" "Go-http-client/1.1"
35.210.5.38 - - [23/Mar/2022:12:25:20 +0300] "GET /katalog/begovye-dorozhki HTTP/1.0" 301 353 "-" "Mozilla/5.0 (compatible; VelenPublicWebCrawler/1.0; +https://velen.io)"
80.250.211.149 - - [23/Mar/2022:12:26:11 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
45.90.60.90 - - [23/Mar/2022:12:27:22 +0300] "GET /favicon.ico HTTP/1.0" 301 339 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36"
87.251.83.70 - - [23/Mar/2022:12:28:52 +0300] "GET /katalog/iskusstvennaya-trava/ HTTP/1.0" 301 361 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
17.121.115.22 - - [23/Mar/2022:12:31:02 +0300] "GET /katalog/zakrytye-zaly/ HTTP/1.0" 301 354 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.1 Safari/605.1.15 (Applebot/0.1; +http://www.apple.com/go/applebot)"
17.121.114.169 - - [23/Mar/2022:12:31:03 +0300] "GET /katalog/zakrytye-zaly/ HTTP/1.0" 301 364 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.1 Safari/605.1.15 (Applebot/0.1; +http://www.apple.com/go/applebot)"
80.250.211.149 - - [23/Mar/2022:12:32:16 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:12:38:22 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
157.55.39.182 - - [23/Mar/2022:12:40:08 +0300] "GET /vacancy.html HTTP/1.0" 301 344 "-" "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"
95.163.36.8 - - [23/Mar/2022:12:44:20 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
80.250.211.149 - - [23/Mar/2022:12:44:40 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:12:51:01 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
66.249.81.150 - - [23/Mar/2022:12:55:40 +0300] "GET /.well-known/traffic-advice HTTP/1.0" 301 359 "-" "Chrome Privacy Preserving Prefetch Proxy"
114.119.138.251 - - [23/Mar/2022:12:55:55 +0300] "GET /katalog/product/regupol-compact HTTP/1.0" 301 364 "-" "Mozilla/5.0 (Linux; Android 7.0;) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36 (compatible; PetalBot;+https://webmaster.petalsearch.com/site/petalbot)"
80.250.211.149 - - [23/Mar/2022:12:57:05 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
212.192.246.199 - - [23/Mar/2022:13:02:38 +0300] "GET //feed/ HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
212.192.246.199 - - [23/Mar/2022:13:02:38 +0300] "GET //blog/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
212.192.246.199 - - [23/Mar/2022:13:02:38 +0300] "GET //web/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
212.192.246.199 - - [23/Mar/2022:13:02:38 +0300] "GET //wordpress/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
212.192.246.199 - - [23/Mar/2022:13:02:38 +0300] "GET //wp/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
212.192.246.199 - - [23/Mar/2022:13:02:38 +0300] "GET //2020/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
212.192.246.199 - - [23/Mar/2022:13:02:38 +0300] "GET //2019/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
212.192.246.199 - - [23/Mar/2022:13:02:38 +0300] "GET //2021/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
212.192.246.199 - - [23/Mar/2022:13:02:39 +0300] "GET //shop/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
212.192.246.199 - - [23/Mar/2022:13:02:39 +0300] "GET //wp1/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
212.192.246.199 - - [23/Mar/2022:13:02:39 +0300] "GET //test/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
212.192.246.199 - - [23/Mar/2022:13:02:39 +0300] "GET //site/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
212.192.246.199 - - [23/Mar/2022:13:02:39 +0300] "GET //cms/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
80.250.211.149 - - [23/Mar/2022:13:03:10 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
95.163.36.15 - - [23/Mar/2022:13:05:14 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
114.119.138.230 - - [23/Mar/2022:13:08:39 +0300] "GET /katalog/product/pritsepnoe-ustroystvo-sb1 HTTP/1.0" 301 374 "-" "Mozilla/5.0 (Linux; Android 7.0;) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36 (compatible; PetalBot;+https://webmaster.petalsearch.com/site/petalbot)"
80.250.211.149 - - [23/Mar/2022:13:09:15 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:13:15:20 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
87.251.83.70 - - [23/Mar/2022:13:16:55 +0300] "GET /katalog/regupol/ HTTP/1.0" 301 348 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
66.249.89.233 - - [23/Mar/2022:13:19:58 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 374 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
66.249.89.239 - - [23/Mar/2022:13:19:59 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 331 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
114.119.138.27 - - [23/Mar/2022:13:21:22 +0300] "GET /uslugi/stabilizatsiya-osnovaniya/ HTTP/1.0" 301 361 "-" "Mozilla/5.0 (Linux; Android 7.0;) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36 (compatible; PetalBot;+https://webmaster.petalsearch.com/site/petalbot)"
80.250.211.149 - - [23/Mar/2022:13:21:24 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
217.118.90.130 - - [23/Mar/2022:13:23:51 +0300] "GET /katalog/iskusstvennaya-trava-futbolnogo-polya/ HTTP/1.0" 304 - "https://www.google.ru/" "Mozilla/5.0 (iPhone; CPU iPhone OS 15_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.3 Mobile/15E148 Safari/604.1"
95.163.36.13 - - [23/Mar/2022:13:23:54 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
217.118.90.130 - - [23/Mar/2022:13:25:40 +0300] "GET /katalog/iskusstvennaya-trava-futbolnogo-polya/ HTTP/1.0" 304 - "https://www.google.ru/" "Mozilla/5.0 (iPhone; CPU iPhone OS 15_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.3 Mobile/15E148 Safari/604.1"
37.193.7.171 - - [23/Mar/2022:13:25:52 +0300] "GET /bitrix/spread.php?s=VkpTVmNKMVRfU0FMRV9VSUQBODMwMAExNjc5MTM1MTUyAS8BAQEC&k=69d315e8797674b063706ed4d4966cf9 HTTP/1.0" 301 439 "https://www.bamard-sport.ru/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.82 Safari/537.36"
37.193.7.171 - - [23/Mar/2022:13:26:04 +0300] "GET /vidy-sporta/futbol/ HTTP/1.0" 304 - "https://www.bamard-sport.ru/katalog/product/euro-grass-m60/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.82 Safari/537.36"
37.193.7.171 - - [23/Mar/2022:13:26:08 +0300] "GET /katalog/product/euro-grass-m60/ HTTP/1.0" 304 - "https://www.bamard-sport.ru/vidy-sporta/futbol/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.82 Safari/537.36"
80.250.211.149 - - [23/Mar/2022:13:27:38 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
66.249.64.174 - - [23/Mar/2022:13:29:18 +0300] "GET /katalog/iskusstvennaya-trava-futbolnogo-polya/ HTTP/1.0" 304 - "-" "Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.82 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
172.107.33.218 - - [23/Mar/2022:13:29:48 +0300] "GET //feed/ HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
172.107.33.218 - - [23/Mar/2022:13:29:49 +0300] "GET //blog/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
172.107.33.218 - - [23/Mar/2022:13:29:49 +0300] "GET //web/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
172.107.33.218 - - [23/Mar/2022:13:29:49 +0300] "GET //wordpress/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
172.107.33.218 - - [23/Mar/2022:13:29:49 +0300] "GET //wp/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
172.107.33.218 - - [23/Mar/2022:13:29:49 +0300] "GET //2020/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
172.107.33.218 - - [23/Mar/2022:13:29:50 +0300] "GET //2019/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
172.107.33.218 - - [23/Mar/2022:13:29:50 +0300] "GET //2021/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
172.107.33.218 - - [23/Mar/2022:13:29:50 +0300] "GET //shop/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
172.107.33.218 - - [23/Mar/2022:13:29:50 +0300] "GET //wp1/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
172.107.33.218 - - [23/Mar/2022:13:29:50 +0300] "GET //test/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
172.107.33.218 - - [23/Mar/2022:13:29:50 +0300] "GET //site/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
172.107.33.218 - - [23/Mar/2022:13:29:51 +0300] "GET //cms/wp-includes/wlwmanifest.xml HTTP/1.0" 301 - "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36"
80.250.211.149 - - [23/Mar/2022:13:33:44 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
91.244.252.244 - - [23/Mar/2022:13:34:39 +0300] "GET /bitrix/templates/bamard/template_styles.css?164752237566008 HTTP/1.0" 304 - "https://www.bamard-sport.ru/katalog/sportivnyj-parket/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.82 Safari/537.36"
20.75.128.100 - - [23/Mar/2022:13:36:44 +0300] "GET /upload/iblock/d47/2%20central%20stadium%20almaty.jpg HTTP/1.0" 301 380 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36"
20.75.128.100 - - [23/Mar/2022:13:36:51 +0300] "GET /upload/iblock/d47/2%20central%20stadium%20almaty.jpg HTTP/1.0" 404 10386 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36"
80.250.211.149 - - [23/Mar/2022:13:39:51 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
95.163.36.15 - - [23/Mar/2022:13:43:44 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
80.250.211.149 - - [23/Mar/2022:13:46:03 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
20.75.128.100 - - [23/Mar/2022:13:49:06 +0300] "GET /upload/iblock/73e/1%20arena%20khimki.jpg HTTP/1.0" 301 368 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36"
20.75.128.100 - - [23/Mar/2022:13:49:16 +0300] "GET /upload/iblock/73e/1%20arena%20khimki.jpg HTTP/1.0" 404 10385 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36"
87.251.83.70 - - [23/Mar/2022:13:50:50 +0300] "GET /uslugi/inzhenernye-sistemy/ HTTP/1.0" 301 359 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
80.250.211.149 - - [23/Mar/2022:13:52:21 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
66.249.64.142 - - [23/Mar/2022:13:53:40 +0300] "GET /vidy-sporta/basketbol/ HTTP/1.0" 304 - "-" "Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.82 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
80.250.211.149 - - [23/Mar/2022:13:58:54 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:14:05:18 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
5.183.29.115 - - [23/Mar/2022:14:05:26 +0300] "GET /bitrix/spread.php?s=VkpTVmNKMVRfU0FMRV9VSUQBODMwMQExNjc5MTM3NTI2AS8BAQEC&k=3b126fd82e4d68fd10046f97dd0c52c4 HTTP/1.0" 301 439 "https://www.bamard-sport.ru/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.74 Safari/537.36 Edg/99.0.1150.46"
95.163.36.15 - - [23/Mar/2022:14:05:41 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
5.183.29.115 - - [23/Mar/2022:14:05:49 +0300] "GET /search/index.php?q=%D0%BB%D0%B5%D0%BD%D1%82%D0%B0&s=%D0%9F%D0%BE%D0%B8%D1%81%D0%BA HTTP/1.0" 301 409 "https://www.bamard-sport.ru/katalog/product/euro-grass-m60/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.74 Safari/537.36 Edg/99.0.1150.46"
80.250.211.149 - - [23/Mar/2022:14:11:28 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
109.196.140.144 - - [23/Mar/2022:14:15:10 +0300] "GET / HTTP/1.0" 304 - "https://yandex.ru/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.82 Safari/537.36"
109.196.140.144 - - [23/Mar/2022:14:15:14 +0300] "GET /uslugi/stroitelstvo-futbolnykh-poley/iskusstvennoe/ HTTP/1.0" 304 - "https://www.bamard-sport.ru/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.82 Safari/537.36"
109.196.140.144 - - [23/Mar/2022:14:15:24 +0300] "GET /katalog/ HTTP/1.0" 304 - "https://www.bamard-sport.ru/uslugi/stroitelstvo-futbolnykh-poley/iskusstvennoe/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.82 Safari/537.36"
109.196.140.144 - - [23/Mar/2022:14:15:28 +0300] "GET /katalog/iskusstvennaya-trava-futbolnogo-polya/ HTTP/1.0" 304 - "https://www.bamard-sport.ru/katalog/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.82 Safari/537.36"
80.250.211.149 - - [23/Mar/2022:14:18:34 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
87.251.83.70 - - [23/Mar/2022:14:19:03 +0300] "GET /uslugi/sistemy-musco-lightning/ HTTP/1.0" 301 363 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
80.250.211.149 - - [23/Mar/2022:14:24:41 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:14:32:10 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:14:39:24 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:14:54:26 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
114.119.133.165 - - [23/Mar/2022:14:57:08 +0300] "GET /robots.txt HTTP/1.0" 301 338 "-" "Mozilla/5.0 (compatible;PetalBot;+https://webmaster.petalsearch.com/site/petalbot)"
80.250.211.149 - - [23/Mar/2022:15:02:17 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
91.232.80.11 - - [23/Mar/2022:15:02:38 +0300] "GET / HTTP/1.0" 304 - "https://yandex.ru/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:96.0) Gecko/20100101 Firefox/96.0"
114.119.138.250 - - [23/Mar/2022:15:04:37 +0300] "GET /upload/iblock/183/maxigrass-f12.pdf HTTP/1.0" 301 363 "-" "Mozilla/5.0 (Linux; Android 7.0;) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36 (compatible; PetalBot;+https://webmaster.petalsearch.com/site/petalbot)"
80.250.211.149 - - [23/Mar/2022:15:09:25 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:15:15:42 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
66.249.89.94 - - [23/Mar/2022:15:18:24 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 374 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
66.249.89.77 - - [23/Mar/2022:15:18:25 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 331 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
80.250.211.149 - - [23/Mar/2022:15:21:47 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:15:25:04 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:15:31:10 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:15:37:15 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:15:44:23 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
207.46.13.156 - - [23/Mar/2022:15:47:01 +0300] "GET /katalog/tekhnika-dlya-ukladki-sportivnykh-pokrytiy/turfroller/ HTTP/1.0" 301 394 "-" "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"
207.46.13.125 - - [23/Mar/2022:15:48:00 +0300] "GET /katalog/product/boflex-stadium-28mm/ HTTP/1.0" 301 368 "-" "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"
80.250.211.149 - - [23/Mar/2022:15:50:52 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
20.75.128.100 - - [23/Mar/2022:16:21:11 +0300] "GET /upload/iblock/7d1/5%20bgtu.jpg HTTP/1.0" 301 358 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36"
141.8.142.66 - - [23/Mar/2022:16:35:11 +0300] "GET /upload/iblock/690/01_s.jpg HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; YandexImages/3.0; +http://yandex.com/bots)"
80.250.211.149 - - [23/Mar/2022:16:50:01 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:16:57:46 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:17:04:52 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:17:10:58 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:17:17:22 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:17:23:31 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
95.163.36.15 - - [23/Mar/2022:17:25:21 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
80.250.211.149 - - [23/Mar/2022:17:30:08 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
207.46.13.156 - - [23/Mar/2022:17:31:05 +0300] "GET /kontakty/ HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"
80.250.211.149 - - [23/Mar/2022:17:37:15 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:17:44:27 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:17:51:48 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:18:06:09 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
80.250.211.149 - - [23/Mar/2022:18:13:08 +0300] "POST /autodiscover/autodiscover.xml HTTP/1.0" 301 357 "-" "Microsoft Office/15.0 (Windows NT 6.1; Microsoft Outlook 15.0.5415; Pro)"
95.163.36.14 - - [23/Mar/2022:18:50:39 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
95.163.36.6 - - [23/Mar/2022:19:11:08 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
95.163.36.8 - - [23/Mar/2022:19:26:04 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
66.249.88.174 - - [23/Mar/2022:19:41:18 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 374 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
66.249.88.178 - - [23/Mar/2022:19:41:18 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 331 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
66.249.88.178 - - [23/Mar/2022:19:41:19 +0300] "GET / HTTP/1.0" 304 - "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
95.163.36.4 - - [23/Mar/2022:19:49:41 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
207.46.13.217 - - [23/Mar/2022:19:53:41 +0300] "GET /js/jquery.formstyler.min.js HTTP/1.0" 301 355 "-" "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)"
207.46.13.217 - - [23/Mar/2022:19:53:43 +0300] "GET /js/height.js HTTP/1.0" 301 340 "-" "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)"
40.77.167.60 - - [23/Mar/2022:19:55:50 +0300] "GET /bitrix/templates/bamard/components/bitrix/menu/top-main/script.js?1542706233627 HTTP/1.0" 301 407 "-" "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)"
95.163.36.7 - - [23/Mar/2022:20:05:22 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
95.163.36.4 - - [23/Mar/2022:20:24:45 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
185.5.249.185 - - [23/Mar/2022:20:36:51 +0300] "HEAD / HTTP/1.0" 301 - "https://hoteltukan.ru/nomera-i-tseny/" "Mozilla/5.0 (compatible; MSIE5.00; Windows 2009)"
213.180.203.3 - - [23/Mar/2022:20:38:30 +0300] "GET /robots.txt HTTP/1.0" 301 338 "-" "Mozilla/5.0 (compatible; YandexBot/3.0; +http://yandex.com/bots)"
95.108.213.67 - - [23/Mar/2022:20:38:37 +0300] "GET /bitrix/templates/bamard/components/bitrix/menu/top-main/style.css?16158822664874 HTTP/1.0" 301 408 "-" "Mozilla/5.0 (compatible; YandexMetrika/4.0; +http://yandex.com/bots)"
141.8.142.85 - - [23/Mar/2022:20:38:40 +0300] "GET /bitrix/templates/bamard/components/bitrix/catalog/katalog/style.css?1542706230768 HTTP/1.0" 301 409 "-" "Mozilla/5.0 (compatible; YandexMetrika/4.0; +http://yandex.com/bots)"
5.255.253.173 - - [23/Mar/2022:20:38:54 +0300] "GET /bitrix/templates/bamard/flash-slider/slider.css HTTP/1.0" 301 375 "-" "Mozilla/5.0 (compatible; YandexMetrika/4.0; +http://yandex.com/bots)"
87.250.224.200 - - [23/Mar/2022:20:38:57 +0300] "GET /robots.txt HTTP/1.0" 301 338 "-" "Mozilla/5.0 (compatible; YandexBot/3.0; +http://yandex.com/bots)"
5.45.207.133 - - [23/Mar/2022:20:39:01 +0300] "GET /bitrix/templates/bamard/components/bitrix/catalog/uslugi/bitrix/catalog.section/.default/style.css?15427062681586 HTTP/1.0" 301 441 "-" "Mozilla/5.0 (compatible; YandexMetrika/4.0; +http://yandex.com/bots)"
95.163.36.13 - - [23/Mar/2022:20:44:11 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
5.255.253.124 - - [23/Mar/2022:20:46:10 +0300] "GET /ds-comf/ds-form/main.php?m=getcss HTTP/1.0" 301 361 "-" "Mozilla/5.0 (compatible; YandexMetrika/4.0; +http://yandex.com/bots)"
207.46.13.125 - - [23/Mar/2022:21:00:02 +0300] "GET /maegagr.html HTTP/1.0" 301 344 "-" "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"
95.163.36.7 - - [23/Mar/2022:21:06:34 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
207.46.13.156 - - [23/Mar/2022:21:24:27 +0300] "GET /readers/iskusstwennyiiji_gazon_dlya_sportiwnyiih_sooruzheniji.html HTTP/1.0" 301 398 "-" "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"
95.163.36.13 - - [23/Mar/2022:21:37:28 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
207.46.13.125 - - [23/Mar/2022:21:40:14 +0300] "GET /vidy-sporta/rollerkey-khokkey-na-rolikakh/ HTTP/1.0" 301 374 "-" "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"
66.249.64.154 - - [23/Mar/2022:21:46:03 +0300] "GET /upload/iblock/414/maxigrass-m40.pdf HTTP/1.0" 301 367 "-" "Googlebot/2.1 (+http://www.google.com/bot.html)"
95.163.36.5 - - [23/Mar/2022:21:47:53 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
66.249.64.142 - - [23/Mar/2022:21:50:07 +0300] "GET /katalog/product/regumond-matte-1000/ HTTP/1.0" 304 - "-" "Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.82 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
95.163.36.13 - - [23/Mar/2022:22:06:09 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
46.8.50.166 - - [23/Mar/2022:22:13:44 +0300] "GET /katalog/iskusstvennaya-trava-futbolnogo-polya/ HTTP/1.0" 304 - "https://www.bamard-sport.ru/katalog/" "Mozilla/5.0 (iPhone; CPU iPhone OS 15_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.3 Mobile/15E148 Safari/604.1"
46.8.50.166 - - [23/Mar/2022:22:14:05 +0300] "GET /bitrix/spread.php?s=VkpTVmNKMVRfU0FMRV9VSUQBODMwMgExNjc5MTY2ODQ1AS8BAQEC&k=8ebbedb806e405f124405ea23206eca6 HTTP/1.0" 301 439 "https://www.bamard-sport.ru/" "Mozilla/5.0 (iPhone; CPU iPhone OS 15_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.3 Mobile/15E148 Safari/604.1"
5.45.207.146 - - [23/Mar/2022:22:26:11 +0300] "GET /bitrix/templates/bamard/components/bitrix/catalog.section/.default/style.css?15936898894351 HTTP/1.0" 301 419 "-" "Mozilla/5.0 (compatible; YandexMetrika/4.0; +http://yandex.com/bots)"
95.163.36.4 - - [23/Mar/2022:22:29:00 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
162.0.210.47 - - [23/Mar/2022:22:29:32 +0300] "GET /personal/ HTTP/1.0" 301 337 "http://bamard-sport.ru/personal/" "Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.85 Safari/537.36"
95.163.36.14 - - [23/Mar/2022:22:44:14 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
95.163.36.4 - - [23/Mar/2022:23:05:46 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
66.249.81.154 - - [23/Mar/2022:23:12:59 +0300] "GET /.well-known/traffic-advice HTTP/1.0" 301 359 "-" "Chrome Privacy Preserving Prefetch Proxy"
95.163.36.6 - - [23/Mar/2022:23:32:13 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
66.249.89.94 - - [23/Mar/2022:23:45:34 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 374 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
66.249.89.77 - - [23/Mar/2022:23:45:35 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 331 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
95.163.36.13 - - [23/Mar/2022:23:47:27 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
66.249.89.67 - - [23/Mar/2022:23:53:04 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 374 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
66.249.89.77 - - [23/Mar/2022:23:53:04 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 331 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
66.249.89.67 - - [23/Mar/2022:23:53:58 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 374 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
66.249.89.77 - - [23/Mar/2022:23:53:59 +0300] "GET /readers/stroitelstwo_ledowyiih_katkow.html HTTP/1.0" 301 331 "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
66.249.89.77 - - [23/Mar/2022:23:53:59 +0300] "GET / HTTP/1.0" 304 - "-" "FeedFetcher-Google; (+http://www.google.com/feedfetcher.html)"
87.251.83.70 - - [23/Mar/2022:23:55:56 +0300] "GET /uslugi/stroitelstvo-sportivnyh-sooruzheny/ HTTP/1.0" 301 374 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0"
95.163.36.4 - - [24/Mar/2022:00:05:11 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"
95.163.36.4 - - [12/Aug/2023:18:19:29 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"\n
95.163.36.4 - - [12/Aug/2023:18:25:50 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"\n
95.163.36.4 - - [12/Aug/2023:18:27:49 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"\n
95.163.36.4 - - [12/Aug/2023:18:30:04 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"\n
95.163.36.4 - - [12/Aug/2023:18:58:15 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"\n
95.163.36.4 - - [12/Aug/2023:19:01:10 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"\n
===========================================
Sort by top Code:
   6328 200
    550 301
     95 304
     75 404
      1 403
Terminated. Cleaning ...


```

### Второй запуск

```shell

sincere@sincere-ubuntuotus:~/vagrantdocs/lesson10$ ./top_ip_limit.sh ru.access.log
Control File lasttimestampfile.date has data. Read timestampdate from file
SELECT LAST SECONDS: CurrentTime 1691855995  - LastTime of Run  1691855810  =  185 last seconds
Time when script was runned last time 12/авг/2023:18:56:50
===========================================
Analyze Date From Log File. Wait please...
===========================================
Analyze string 7046 of 7047 ./ru.access.log  - String 7046 add to analyse  (MinDate:  1691855810 < DateOfString:  1691855893 < CurrentDate:  169Analyze string 7047 of 7047 ./ru.access.log  - String 7047 add to analyse  (MinDate:  1691855810 < DateOfString:  1691855895 < CurrentDate:  1691855995 )===========================================
Sort by top ip:
      1 95.163.36.4 304
      1 194.58.113.39 301
===========================================
Sort by URL:
      1 /sitemap.xml
      1 /
===========================================
Error WEB Servers From Last Time:
95.163.36.4 - - [12/Aug/2023:18:58:15 +0300] "GET /sitemap.xml HTTP/1.0" 304 - "-" "Mozilla/5.0 (compatible; Linux x86_64; Mail.RU_Bot/Fast/2.0; +http://go.mail.ru/help/robots)"\n
===========================================
Sort by top Code:
      1 304
      1 301
Terminated. Cleaning ...



```










