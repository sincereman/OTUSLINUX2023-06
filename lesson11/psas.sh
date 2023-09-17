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