#!/bin/bash

echo "Create watchlogfile"

cat > /etc/sysconfig/watchlog << EOF
# Configuration file for my watchlog service
# Place it to /etc/sysconfig
# File and word in that file that we will be monit
WORD=ALERT
LOG=/var/log/watchlog.log
EOF

echo "Create a log file"

cat > /var/log/watchlog.log << 'EOF'
String1
String2
ALERT
String3
EOF

echo "Create a script watchlog.sh"

cat > /opt/watchlog.sh << 'EOF'
#!/bin/bash
WORD=$1
LOG=$2
DATE=`date`
if grep $WORD $LOG &> /dev/null
then
logger "$DATE: I found word, Master!"
else
exit 0
fi
EOF

echo "Make an executive"

chmod +x /opt/watchlog.sh


echo "Create a  watchlog.service"

cat > /lib/systemd/system/watchlog.service << 'EOF'
[Unit]
Description=My watchlog service
[Service]
User=root
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG
EOF


echo "Create a  watchlog.timer"

cat >> /lib/systemd/system/watchlog.timer << 'EOF'
[Unit]
Description=Run watchlog script every 30 second
[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service
[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload
systemctl enable watchlog.timer
systemctl start watchlog.timer


echo "part 2"

echo "Add package"
yum install -y -q epel-release
yum install -y -q spawn-fcgi php-cli httpd

echo "Add settings  spawn-fcgi..."

echo "OPTIONS=-u apache -g apache -s /var/run/spawn-fcgi/php-fcgi.sock -S -M 0600 -C 32 -F 1 -P /var/run/spawn-fcgi/spawn-fcgi.pid -- /usr/bin/php-cgi" >> /etc/sysconfig/spawn-fcgi

echo "Create Unit-файл for spawn-fcgi..."

cat > /etc/systemd/system/spawn-fcgi.service << 'EOF'
[Unit]
Description=spawn-fcgi
After=syslog.target
[Service]
Type=forking
User=apache
Group=apache
EnvironmentFile=/etc/sysconfig/spawn-fcgi
PIDFile=/var/run/spawn-fcgi/spawn-fcgi.pid
RuntimeDirectory=spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi $OPTIONS
ExecStop=
[Install]
WantedBy=multi-user.target
EOF

echo "Add a right"

chmod 664 /etc/systemd/system/spawn-fcgi.service

echo " Start a service spawn-fcgi.service"

systemctl daemon-reload
systemctl enable --now spawn-fcgi.service



Echo "HTTP SERVICE"

cp /usr/lib/systemd/system/httpd.service /etc/systemd/system/httpd@.service
sed -i 's*Environment=LANG=C*Environment=LANG=C\nEnvironmentFile=/etc/sysconfig/httpd-%i*g' /etc/systemd/system/httpd@.service
cat /etc/systemd/system/httpd@.service


at > /etc/sysconfig/httpd-conf1 << 'EOF'
OPTIONS=-f /etc/httpd/conf/httpd1.conf
EOF

cat > /etc/sysconfig/httpd-conf2 << 'EOF'
OPTIONS=-f /etc/httpd/conf/httpd2.conf
EOF


echo "Copy and settings file  httpd serice "

cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd1.conf
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd2.conf


# Use different ports
sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd1.conf
sed -i 's/Listen 80/Listen 8008/' /etc/httpd/conf/httpd2.conf

# Use different PID

echo "PidFile /var/run/httpd/httpd1.pid" >> /etc/httpd/conf/httpd1.conf
echo "PidFile /var/run/httpd/httpd2.pid" >> /etc/httpd/conf/httpd2.conf

#Запустим два инстанса httpd

#тут сработала защита от нестандартных портов
#поменял на разрешенные 8080 и 8008 так как semanage не хотел срабатывать


systemctl daemon-reload
systemctl enable --now httpd@conf1.service
systemctl enable --now httpd@conf2.service


#Проверим статус сервисов

systemctl status httpd@conf1.service
systemctl status httpd@conf2.service

netstat -tulnp | grep 8080
netstat -tulnp | grep 8008




