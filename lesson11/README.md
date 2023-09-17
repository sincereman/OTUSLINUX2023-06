# Lesson 11 - работаем с процессами

## Цель: работать с процессами;

Описание/Пошаговая инструкция выполнения домашнего задания:

Что нужно сделать?




Задания на выбор:

    написать свою реализацию ps ax используя анализ /proc

    Результат ДЗ - рабочий скрипт который можно запустить

    написать свою реализацию lsof

    Результат ДЗ - рабочий скрипт который можно запустить

    дописать обработчики сигналов в прилагаемом скрипте, оттестировать, приложить сам скрипт, инструкции по использованию

    Результат ДЗ - рабочий скрипт который можно запустить + инструкция по использованию и лог консоли

    реализовать 2 конкурирующих процесса по IO. пробовать запустить с разными ionice

    Результат ДЗ - скрипт запускающий 2 процесса с разными ionice, замеряющий время выполнения и лог консоли

    реализовать 2 конкурирующих процесса по CPU. пробовать запустить с разными nice

    Результат ДЗ - скрипт запускающий 2 процесса с разными nice и замеряющий время выполнения и лог консоли
    В чат ДЗ отправьте ссылку на ваш git-репозиторий. Обычно мы проверяем ДЗ в течение 48 часов.
    Если возникнут вопросы, обращайтесь к студентам, преподавателям и наставникам в канал группы в Telegram.
    Удачи при выполнении!


## Описание домашнего задания.

### Выбираю задание 1 написать свою реализацию ps ax используя анализ /proc

    Результат ДЗ - рабочий скрипт который можно запустить

Посмотрим какую информацию выводит ps ax

```shell
root@sincere-ubuntuotus:/home/sincere/vagrantdocs/lesson11# ps ax -q 1144268
    PID TTY      STAT   TIME COMMAND
1144268 ?        Sl     0:00 /usr/lib/firefox/firefox -contentproc -childID 97 -isForBrowser -prefsLen 29956 -prefMapSize 234208 -jsInitLen 242416 -parentBuildID 20230805021307 -appDir /usr/lib/firefox/browser {470a145b-d6ef-48c4-8a63-c9f88e12e9ad} 14859 true tab

```
для увеличения процесса сложности возьмем другие ключи у ps -efl

```shell
root@sincere-ubuntuotus:/home/sincere/vagrantdocs/lesson11# ps -efl -q 1
F S UID          PID    PPID  C PRI  NI ADDR SZ WCHAN  STIME TTY          TIME CMD
4 S root           1       0  0  80   0 - 42417 ep_pol авг08 ?     00:00:10 /sbin/init splash


```
Рассмотрим ключи

   f           F         flags associated with the process, see the PROCESS FLAGS section.  (alias flag, flags).

   s           S         minimal state display (one character).  See section PROCESS STATE CODES for the different values.  See also
                         pr    stat if you want additional information displayed.  (alias state).

   pid         PID       a number representing the process ID (alias tgid).
   tgid        TGID      a number representing the thread group to which a task belongs (alias pid).  It is the process ID of the
                             thread group leader.

   ppid        PPID      parent process ID.

   c           C         processor utilization.  Currently, this is the integer value of the percent usage over the lifetime of the
                             process.  (see %cpu).

   pri         PRI       priority of the process.  Higher number means lower priority.


   ni          NI        nice value.  This ranges from 19 (nicest) to -20 (not nice to others), see nice(1).  (alias nice).

   nice        NI        see ni.(alias ni).

   tname       TTY       controlling tty (terminal).  (alias tt, tty).

   tt          TT        controlling tty (terminal).  (alias tname, tty).

   tty         TT        controlling tty (terminal).  (alias tname, tt).

   time        TIME      cumulative CPU time, "[DD-]HH:MM:SS" format.  (alias cputime).


   cputime     TIME      cumulative CPU time, "[DD-]hh:mm:ss" format.  (alias time).


   cmd         CMD       see args.  (alias args, command).


   args        COMMAND   command with all its arguments as a string.  Modifications to the arguments may be shown.  The output in this
                             column may contain spaces.  A process marked <defunct> is partly dead, waiting to be fully destroyed by its
                             parent.  Sometimes the process args will be unavailable; when this happens, ps will instead print the
                             executable name in brackets.  (alias cmd, command).  See also the comm format keyword, the -f option, and the
                             c option.
                             When specified last, this column will extend to the edge of the display.  If ps can not determine display
                             width, as when output is redirected (piped) into a file or another command, the output width is undefined (it
                             may be 80, unlimited, determined by the TERM variable, and so on).  The COLUMNS environment variable or --cols
                             option may be used to exactly determine the width in this case.  The w or -w option may be also be used to
                             adjust width.



Проведем анализ каталога  /proc



<detail>
4 R root     1145553 1144796  0  80   0 -  5032 -      14:18 pts/0    00:00:00 ps -efl
root@sincere-ubuntuotus:/home/sincere/vagrantdocs/lesson11# ps -efl -q 122
F S UID          PID    PPID  C PRI  NI ADDR SZ WCHAN  STIME TTY          TIME CMD
1 I root         122       2  0  60 -20 -     0 rescue авг08 ?     00:00:00 [md]
root@sincere-ubuntuotus:/home/sincere/vagrantdocs/lesson11# tree /proc/122
/proc/122
├── arch_status
├── attr
│   ├── apparmor
│   │   ├── current
│   │   ├── exec
│   │   └── prev
│   ├── context
│   ├── current
│   ├── display
│   ├── exec
│   ├── fscreate
│   ├── keycreate
│   ├── prev
│   ├── smack
│   │   └── current
│   └── sockcreate
├── autogroup
├── auxv
├── cgroup
├── clear_refs
├── cmdline
├── comm
├── coredump_filter
├── cpu_resctrl_groups
├── cpuset
├── cwd -> /
├── environ
├── exe -> [Error reading symbolic link information]
├── fd
├── fdinfo
├── gid_map
├── io
├── limits
├── loginuid
├── map_files
├── maps
├── mem
├── mountinfo
├── mounts
├── mountstats
├── net
│   ├── anycast6
│   ├── arp
│   ├── connector
│   ├── dev
│   ├── dev_mcast
│   ├── dev_snmp6
│   │   ├── eth0
│   │   ├── lo
│   │   ├── tun0
│   │   └── vboxnet0
│   ├── fib_trie
│   ├── fib_triestat
│   ├── icmp
│   ├── icmp6
│   ├── if_inet6
│   ├── igmp
│   ├── igmp6
│   ├── ip6_flowlabel
│   ├── ip6_mr_cache
│   ├── ip6_mr_vif
│   ├── ip_mr_cache
│   ├── ip_mr_vif
│   ├── ip_tables_matches
│   ├── ip_tables_names
│   ├── ip_tables_targets
│   ├── ipv6_route
│   ├── mcfilter
│   ├── mcfilter6
│   ├── netfilter
│   │   └── nf_log
│   ├── netlink
│   ├── netstat
│   ├── packet
│   ├── protocols
│   ├── psched
│   ├── ptype
│   ├── raw
│   ├── raw6
│   ├── route
│   ├── rt6_stats
│   ├── rt_acct
│   ├── rt_cache
│   ├── snmp
│   ├── snmp6
│   ├── sockstat
│   ├── sockstat6
│   ├── softnet_stat
│   ├── stat
│   │   ├── arp_cache
│   │   ├── ndisc_cache
│   │   └── rt_cache
│   ├── tcp
│   ├── tcp6
│   ├── udp
│   ├── udp6
│   ├── udplite
│   ├── udplite6
│   ├── unix
│   ├── wireless
│   └── xfrm_stat
├── ns
│   ├── cgroup -> cgroup:[4026531835]
│   ├── ipc -> ipc:[4026531839]
│   ├── mnt -> mnt:[4026531841]
│   ├── net -> net:[4026531840]
│   ├── pid -> pid:[4026531836]
│   ├── pid_for_children -> pid:[4026531836]
│   ├── time -> time:[4026531834]
│   ├── time_for_children -> time:[4026531834]
│   ├── user -> user:[4026531837]
│   └── uts -> uts:[4026531838]
├── numa_maps
├── oom_adj
├── oom_score
├── oom_score_adj
├── pagemap
├── patch_state
├── personality
├── projid_map
├── root -> /
├── sched
├── schedstat
├── sessionid
├── setgroups
├── smaps
├── smaps_rollup
├── stack
├── stat
├── statm
├── status
├── syscall
├── task
│   └── 122
│       ├── arch_status
│       ├── attr
│       │   ├── apparmor
│       │   │   ├── current
│       │   │   ├── exec
│       │   │   └── prev
│       │   ├── context
│       │   ├── current
│       │   ├── display
│       │   ├── exec
│       │   ├── fscreate
│       │   ├── keycreate
│       │   ├── prev
│       │   ├── smack
│       │   │   └── current
│       │   └── sockcreate
│       ├── auxv
│       ├── cgroup
│       ├── children
│       ├── clear_refs
│       ├── cmdline
│       ├── comm
│       ├── cpu_resctrl_groups
│       ├── cpuset
│       ├── cwd -> /
│       ├── environ
│       ├── exe -> [Error reading symbolic link information]
│       ├── fd
│       ├── fdinfo
│       ├── gid_map
│       ├── io
│       ├── limits
│       ├── loginuid
│       ├── maps
│       ├── mem
│       ├── mountinfo
│       ├── mounts
│       ├── net
│       │   ├── anycast6
│       │   ├── arp
│       │   ├── connector
│       │   ├── dev
│       │   ├── dev_mcast
│       │   ├── dev_snmp6
│       │   │   ├── eth0
│       │   │   ├── lo
│       │   │   ├── tun0
│       │   │   └── vboxnet0
│       │   ├── fib_trie
│       │   ├── fib_triestat
│       │   ├── icmp
│       │   ├── icmp6
│       │   ├── if_inet6
│       │   ├── igmp
│       │   ├── igmp6
│       │   ├── ip6_flowlabel
│       │   ├── ip6_mr_cache
│       │   ├── ip6_mr_vif
│       │   ├── ip_mr_cache
│       │   ├── ip_mr_vif
│       │   ├── ip_tables_matches
│       │   ├── ip_tables_names
│       │   ├── ip_tables_targets
│       │   ├── ipv6_route
│       │   ├── mcfilter
│       │   ├── mcfilter6
│       │   ├── netfilter
│       │   │   └── nf_log
│       │   ├── netlink
│       │   ├── netstat
│       │   ├── packet
│       │   ├── protocols
│       │   ├── psched
│       │   ├── ptype
│       │   ├── raw
│       │   ├── raw6
│       │   ├── route
│       │   ├── rt6_stats
│       │   ├── rt_acct
│       │   ├── rt_cache
│       │   ├── snmp
│       │   ├── snmp6
│       │   ├── sockstat
│       │   ├── sockstat6
│       │   ├── softnet_stat
│       │   ├── stat
│       │   │   ├── arp_cache
│       │   │   ├── ndisc_cache
│       │   │   └── rt_cache
│       │   ├── tcp
│       │   ├── tcp6
│       │   ├── udp
│       │   ├── udp6
│       │   ├── udplite
│       │   ├── udplite6
│       │   ├── unix
│       │   ├── wireless
│       │   └── xfrm_stat
│       ├── ns
│       │   ├── cgroup -> cgroup:[4026531835]
│       │   ├── ipc -> ipc:[4026531839]
│       │   ├── mnt -> mnt:[4026531841]
│       │   ├── net -> net:[4026531840]
│       │   ├── pid -> pid:[4026531836]
│       │   ├── pid_for_children -> pid:[4026531836]
│       │   ├── time -> time:[4026531834]
│       │   ├── time_for_children -> time:[4026531834]
│       │   ├── user -> user:[4026531837]
│       │   └── uts -> uts:[4026531838]
│       ├── numa_maps
│       ├── oom_adj
│       ├── oom_score
│       ├── oom_score_adj
│       ├── pagemap
│       ├── patch_state
│       ├── personality
│       ├── projid_map
│       ├── root -> /
│       ├── sched
│       ├── schedstat
│       ├── sessionid
│       ├── setgroups
│       ├── smaps
│       ├── smaps_rollup
│       ├── stack
│       ├── stat
│       ├── statm
│       ├── status
│       ├── syscall
│       ├── uid_map
│       └── wchan
├── timens_offsets
├── timers
├── timerslack_ns
├── uid_map
└── wchan

27 directories, 243 files


</detail>


PS (https://kb.novaordis.com/index.php/Linux_Process_Information)

```shell
root@sincere-ubuntuotus:/home/sincere/vagrantdocs/lesson11# ps -efl -q 122
F S UID          PID    PPID  C PRI  NI ADDR SZ WCHAN  STIME TTY          TIME CMD
1 I root         122       2  0  60 -20 -     0 rescue авг08 ?     00:00:00 [md]
```

*F* - Process flags

PROCESS FLAGS
       The sum of these values is displayed in the "F" column, which is provided by the flags output specifier:

               1    forked but didn't exec
               4    used super-user privileges

К сожалению не нашел где этот показатель в каталоге /proc


*S* - STAT - это 3 показатель 

root@sincere-ubuntuotus:/home/sincere/vagrantdocs/lesson11# cat /proc/122/stat
122 (md) *I* 2 0 0 0 -1 69238880 0 0 0 0 0 0 0 0 0 -20 1 0 16 0 0 18446744073709551615 0 0 0 0 0 0 0 2147483647 0 1 0 0 17 2 0 0 0 0 0 0 0 0 0 0 0 0 0

root@sincere-ubuntuotus:/home/sincere/vagrantdocs/lesson11# cat /proc/122/stat | awk '{printf $3}'
*I*

или         STAT=`grep -Po '(?<=State:\s)(\d+)' /proc/$PID/status`

*UID* - находим в  /proc/PID/status

Получаем *uid* и переводим в имя

grep -Po '(?<=Uid:\s)(\d+)' /proc/$pid/status

UID=`grep -Po '(?<=Uid:\s)(\d+)' /proc/$PID/status | id -nu`

```shell
root@sincere-ubuntuotus:/home/sincere/vagrantdocs/lesson11# cat /proc/122/uid_map | awk '{print $1}' | id -nu
root

```

*PID*

*PID*  - это номер каталога /proc/{PID}/

/proc/122

*PPID* - родительский PID

Оказалось что есть такой волшебный файлик status 

```shell

root@sincere-ubuntuotus:/home/sincere/vagrantdocs/lesson11# cat /proc/122/status 
Name:	md
Umask:	0000
State:	I (idle)
Tgid:	122
Ngid:	0
Pid:	122
*PPid:	2*
TracerPid:	0
Uid:	0	0	0	0
Gid:	0	0	0	0
FDSize:	64
Groups:	 
NStgid:	122
NSpid:	122
NSpgid:	0
NSsid:	0
Threads:	1
SigQ:	0/63127
SigPnd:	0000000000000000
ShdPnd:	0000000000000000
SigBlk:	0000000000000000
SigIgn:	ffffffffffffffff
SigCgt:	0000000000000000
CapInh:	0000000000000000
CapPrm:	000001ffffffffff
CapEff:	000001ffffffffff
CapBnd:	000001ffffffffff
CapAmb:	0000000000000000
NoNewPrivs:	0
Seccomp:	0
Seccomp_filters:	0
Speculation_Store_Bypass:	thread vulnerable
SpeculationIndirectBranch:	conditional enabled
Cpus_allowed:	ff
Cpus_allowed_list:	0-7
Mems_allowed:	00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000000,00000001
Mems_allowed_list:	0
voluntary_ctxt_switches:	2
nonvoluntary_ctxt_switches:	0

```

А в строчку вот тут

```shell
root@sincere-ubuntuotus:/home/sincere/vagrantdocs/lesson11# cat /proc/122/stat
122 (md) I 2 0 0 0 -1 69238880 0 0 0 0 0 0 0 0 0 -20 1 0 16 0 0 18446744073709551615 0 0 0 0 0 0 0 2147483647 0 1 0 0 17 2 0 0 0 0 0 0 0 0 0 0 0 0 0

```
4 - параметр это PPID


```shell
root@sincere-ubuntuotus:/home/sincere/vagrantdocs/lesson11# cat /proc/122/stat | awk '{print $4}'
2
```
*C* - CPU

из документации
```shell
/proc/[PID]/stat

    #14
    utime
    - CPU time spent in user code, measured in clock ticks
    #15 
    stime
    - CPU time spent in kernel code, measured in clock ticks
    #16
    cutime
    - Waited-for children's CPU time spent in user code (in clock ticks)
    #17
    cstime
    - Waited-for children's CPU time spent in kernel code (in clock ticks)
    #22
    starttime
    - Time when the process started, measured in clock ticks

    Hertz (number of clock ticks per second) of your system.
        In most cases, getconf CLK_TCK
        can be used to return the number of clock ticks.
        The sysconf(_SC_CLK_TCK)
        C function call may also be used to return the hertz value.

CalculationFirst we determine the total time spent for the process:
total_time = utime + stime
We also have to decide whether we want to include the time from children processes. If we do, then we add those values to total_time
:
total_time = total_time + cutime + cstime
Next we get the total elapsed time in seconds since the process started:
seconds = uptime - (starttime / Hertz)
Finally we calculate the CPU usage percentage:
cpu_usage = 100 * ((total_time / Hertz) / seconds)

```
PID=$1
PID=1
uptime=`cat /proc/uptime | awk '{print $1}'`
utime=`cat /proc/$PID/stat | awk '{print $14}'`
stime=`cat /proc/$PID/stat | awk '{print $15}'`
let "total_time=$utime+$stime"
starttime=`cat /proc/$PID/stat | awk '{print $22}'`
hertz=`getconf CLK_TCK`
let "seconds=($uptime-$starttime/$hertz)"
let "cpu_usage=100*(($total_time/$hertz))/$seconds"

echo $cpu_usage


*PRI*
        PRIORITY=`cat /proc/$PID/stat | awk '{print $18}'`

*NI*

        NICE=`cat /proc/$PID/stat | awk '{print $19}'`


*CMD*
        COMMANDLINE=`cat /proc/$PID/comm`

.


 Собираем в программу

```shell

#!/bin/bash

USAGE="SYNOPSIS: psas.sh PID"
# psas.sh PID - if PID is not exist then show all process

pid_array=''

if [ -z "$1" ]
then 
    pid_array=`ls /proc | grep -E '^[0-9]+$'`
else
    if [ "$1" = "help" ]
    then 
    echo $USAGE
    exit 1
    fi
    pid_array=$1 

fi


#*PID*  - это номер каталога /proc/{PID}/

printf "%4s %10s %6s %6s %5s %4s %4s %18s\n" "STAT" "UID" "PID" "PPID" "CPU" "PRI" "NI" "CMD"

for pid in $pid_array
        do
            PID=$pid
            if [ -r /proc/$PID/stat ]
            then

       

        STAT=`grep -Po '(?<=State:\s)(\w+)' /proc/$PID/status`
        USERID=`grep -Po '(?<=Uid:\s)(\d+)' /proc/$PID/status`
        USER=$( id -nu $USERID )
        PARENTPID=`grep -Po '(?<=PPid:\s)(\d+)' /proc/$PID/status`

#RemainingSweets=`expr $sweets - $children \* $PerChildShare`

        uptime=`cat /proc/uptime | awk '{print $1}'`
               
        utime=`cat /proc/$PID/stat | awk '{print $14}'`
        stime=`cat /proc/$PID/stat | awk '{print $15}'`
        total_time=`expr $utime + $stime`
        starttime=`cat /proc/$PID/stat | awk '{print $22}'`
        hertz=`getconf CLK_TCK`
        seconds=$( awk 'BEGIN {print ( '$uptime' - ('$starttime' / '$hertz'))}' )
        CPU=$( awk 'BEGIN {print ( 100 * ('$total_time' / '$hertz') / '$seconds')}')

        PRIORITY=`cat /proc/$PID/stat | awk '{print $18}'`
        NICE=`cat /proc/$PID/stat | awk '{print $19}'`
        COMMANDLINE=`cat /proc/$PID/comm`
        printf "%4s %10s %6i %6i %5.2f %4i %4i %18s\n" $STAT $USER $PID $PARENTPID $CPU $PRIORITY $NICE $COMMANDLINE



     fi
        done

```


Вывод



#### С указанием PID

```
root@sincere-ubuntuotus:/home/sincere/vagrantdocs/lesson11# ./psas.sh 1
STAT        UID    PID   PPID   CPU  PRI   NI                CMD
   S       root      1      0  0,00   20    0            systemd
```

#### Без указания PID

```
root@sincere-ubuntuotus:/home/sincere/vagrantdocs/lesson11# ./psas.sh | head -10
STAT        UID    PID   PPID   CPU  PRI   NI                CMD
   S       root      1      0  0,00   20    0            systemd
   I       root     10      2  0,00    0  -20       mm_percpu_wq
   S        gdm   1002    991  0,00   20    0    dbus-run-sessio
   S        gdm   1003   1002  0,00   20    0        dbus-daemon
   S        gdm   1004   1002  0,00   20    0    gnome-session-b
   S        gdm   1007      1  0,00   20    0    at-spi-bus-laun
   S    sincere 1011903  14859  0,00    0    0           Isolated
 Web         Co      0      0  0,00    0    0                   
   S    sincere 1011972  14859  0,00    0    0           Isolated
root@sincere-ubuntuotus:/home/sincere/vagrantdocs/lesson11# 
```


#### Выполнено
