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