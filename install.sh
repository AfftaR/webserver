#!/bin/bash

# CONFIGURATION

# Base dir where all website files will be located
# source code, logs, pids, configs
WEB_DIR="/web"
WEB_USER="web"

# Install and configure mongodb
INSTALL_MONGO="YES"

INSTALL_POSTGRES="NO"
INSTALL_MYSQL="NO"
INSTALL_SUPERVISOR="NO"
INSTALL_NODE="NO"
INSTALL_MEMCACHED="NO"
INSTALL_REDIS="NO"
INSTALL_ELASTICSEARCH="NO"
INSTALL_SQUID="NO"

# Sysctl configuration
echo "vm.overcommit_memory=1" > /etc/sysctl.conf
sysctl -p

echo "vim config"
# Download vim config
wget -O ~/.vimrc http://dumpz.org/25712/nixtext/

if [ "$INSTALL_MONGO" == "YES" ]; then
    echo "Add extra apt repositories"
    echo "deb http://downloads-distro.mongodb.org/repo/debian-sysvinit dist 10gen" > /etc/apt/sources.list.d/mongodb.list
    # mongo key
    gpg --keyserver pgp.mit.edu --recv-keys 9ECBEC467F0CEB10
    gpg --armor --export 9ECBEC467F0CEB10 | apt-key add -
fi

if [ "$INSTALL_ELASTICSEARCH" == "YES" ]; then
    wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
    echo "deb http://packages.elastic.co/elasticsearch/1.5/debian stable main" | sudo tee  /etc/apt/sources.list.d/elasticsearch.list
fi

# WTF?
apt-get install -y debian-keyring

# Apt utils
apt-get install -y lsb-release

echo "apt.conf.d"
# Set stable repo the default repo
# Disable autoinstalling recommended packages
cat > /etc/apt/apt.conf.d/07custom << EOF
APT::Install-Suggested "false";
EOF

echo "apt pin config"
cat > /etc/apt/preferences.d/01custom << EOF
Explanation: see http://www.argon.org/~roderick/apt-pinning.html
Package: *
Pin: release o=Debian,a=stable
Pin-Priority: 900 

Package: *
Pin: release o=Debian,a=testing
Pin-Priority: 400 

Package: *
Pin: release o=Debian,a=unstable
Pin-Priority: 300 

Package: *
Pin: release o=Debian,a=experimental
Pin-Priority: 200 

Package: *
Pin: release o=Debian
Pin-Priority: -1

Package: elasticsearch
Pin: origin packages.elastic.co
Pin-Priority: 901

#Package: *
#Pin: origin some-domain.com
#Pin-Priority: 600 
EOF

apt-get install -y aptitude

echo "aptitude update"
# Update repositories
aptitude update

echo "Doing aptitude dist-upgrade"
aptitude dist-upgrade

# Setup locales
aptitude install -y locales 
echo "LANG=en_US.UTF-8" > /etc/default/locale
cat > /etc/locale.gen << EOF
en_US.UTF-8 UTF-8
ru_RU.UTF-8 UTF-8
EOF
locale-gen

echo "aptitude install"
# psmsic --> pkill
# apache-utils --> ab
# libxml2-dev libxslt1-dev --> build lxml from source
# libcurl4-openssl-dev --> build pycurl from source
# libjpeg8-dev libfreetype6-dev --> build PIL from source
# postgresql-server-dev-9.4 --> build psycopg from source
# libmysqld-dev --> build mysql driver from source
aptitude install -y \
    perl perl-modules perl-base \
    vim-nox \
    psmisc screen apache2-utils whois sudo less gettext \
    exim4 nginx-full \
    mercurial subversion git-core \
    python python-setuptools python-dev \
    libxml2-dev libxslt1-dev \
    gcc g++ \
    libcurl4-openssl-dev libmemcached-dev \
    libjpeg-dev libfreetype6-dev \
    libmysqld-dev \
    bind9-host \
    postgresql-server-dev-9.4 \
    unzip make \
    python-crypto geoip-database \
    libc-ares-dev \
    openvpn iftop iotop \
    numactl unrar \
    python3.4 python3.4-dev python3-setuptools\
    uwsgi uwsgi-plugin-python3

if [ "$INSTALL_POSTGRES" == "YES" ]; then
    aptitude install -y \
    postgresql-9.4 python-psycopg2
fi

if [ "$INSTALL_MYSQL" == "YES" ]; then
    aptitude install -y mysql-server-5.5
fi

if [ "$INSTALL_MEMCACHED" == "YES" ]; then
    aptitude install -y memcached
fi

if [ "$INSTALL_REDIS" == "YES" ]; then
    aptitude install -y redis-server
fi

if [ "$INSTALL_ELASTICSEARCH" == "YES" ]; then
    aptitude install -y elasticsearch
fi

# TODO:
# Find architecture name and version of installed dev libs
# and make correct symbolic links
#
# Debian 7 warkaround:
# ln -s /usr/lib/x86_64-linux-gnu/libjpeg.so /usr/lib
# ln -s /usr/lib/x86_64-linux-gnu/libfreetype.so /usr/lib
# ln -s /usr/lib/x86_64-linux-gnu/libz.so /usr/lib
#
# Ubuntu PIL hacks:
# ln -s /usr/lib/i386-linux-gnu/libjpeg.so /usr/lib/
# ln -s /usr/lib/i386-linux-gnu/libz.so /usr/lib/
# ln -s /usr/lib/i386-linux-gnu/libfreetype.so /usr/lib/

if [ "$INSTALL_MONGO" == "YES" ]; then
    aptitude install -y mongodb-10gen
fi

if [ "$INSTALL_SQUID" == "YES" ]; then
    aptitude install -y squid
fi

echo "vim default editor"
# Set vim default editor in the system
#echo 'export EDITOR="vim"' >> /root/.bashrc
update-alternatives --set editor /usr/bin/vim.nox

echo "python tools"
# Python libraries
easy_install -U pip
easy_install -U distribute
pip install -U virtualenv sr fabric pillow \
    pymongo lxml pycurl grab argparse redis qr

easy_install3 -U pip distribute
pip3 install -U virtualenv sr fabric pillow \
    pymongo lxml pycurl grab argparse redis qr

if [ "$INSTALL_SUPERVISOR" == "YES" ]; then
    pip install --upgrade --pre supervisor
    cat > /etc/supervisord.conf << EOF
[unix_http_server]
file=/var/run/supervisord.sock   ; (the path to the socket file)

#[inet_http_server]         ; inet (TCP) server disabled by default
#port=127.0.0.1:8888        ; (ip_address:port specifier, *:port for all iface)
#username=***              ; (default is no username (open server))
#password=***               ; (default is no password (open server))

[supervisord]
logfile=/var/log/supervisord.log ; (main log file;default $CWD/supervisord.log)
logfile_maxbytes=50MB        ; (max main logfile bytes b4 rotation;default 50MB)
logfile_backups=10           ; (num of main logfile rotation backups;default 10)
loglevel=info                ; (log level;default info; others: debug,warn,trace)
pidfile=/var/run/supervisord.pid ; (supervisord pidfile;default supervisord.pid)
nodaemon=false               ; (start in foreground if true;default false)
minfds=1024                  ; (min. avail startup file descriptors;default 1024)
minprocs=200                 ; (min. avail process descriptors;default 200)

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisord.sock ; use a unix:// URL  for a unix socket

#[program:sphinx]
#command=/usr/local/bin/searchd --nodetach
EOF

    cat > /etc/inid.d/supervisord << EOF
'#! /bin/sh
### BEGIN INIT INFO
# Provides:          supervisord
# Required-Start:    $local_fs $remote_fs $networking
# Required-Stop:     $local_fs $remote_fs $networking
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Starts supervisord - see http://supervisord.org
# Description:       Starts and stops supervisord as needed - see http://supervisord.org
### END INIT INFO

# Author: Leonard Norrgard <leonard.norrgard@refactor.fi>
# Version 1.0-alpha
# Based on the /etc/init.d/skeleton script in Debian.

# Please note: This script is not yet well tested. What little testing
# that actually was done was only on supervisor 2.2b1.

# Do NOT "set -e"
if [ -r /etc/default/supervisord ]; then
    . /etc/default/supervisord
fi
    

# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="Run a set of applications as daemons."
NAME=supervisord
DAEMON=/usr/local/bin/$NAME   # Supervisord is installed in /usr/bin by default, but /usr/sbin would make more sense.
SUPERVISORCTL=/usr/local/bin/supervisorctl
PIDFILE=/var/run/$NAME.pid
DAEMON_ARGS="--pidfile ${PIDFILE} -c /etc/supervisord.conf"
SCRIPTNAME=/etc/init.d/$NAME

# Exit if the package is not installed
[ -x "$DAEMON" ] || exit 0

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

#
# Function that starts the daemon/service
#
do_start()
{
	# Return
	#   0 if daemon has been started
	#   1 if daemon was already running
	#   2 if daemon could not be started
        [ -e $PIDFILE ] && return 1

	WEB_USER=$WEB_USER start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON -- \
		$DAEMON_ARGS \
		|| return 2
	# Add code here, if necessary, that waits for the process to be ready
	# to handle requests from services started subsequently which depend
	# on this one.  As a last resort, sleep for some time.
}

#
# Function that stops the daemon/service
#
do_stop()
{
	# Return
	#   0 if daemon has been stopped
	#   1 if daemon was already stopped
	#   2 if daemon could not be stopped
	#   other if a failure occurred
        [ -e $PIDFILE ] || return 1

	# Stop all processes under supervisord control.
	$SUPERVISORCTL stop all

	start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDFILE --name $NAME
	RETVAL="$?"
	[ "$RETVAL" = 2 ] && return 2
	# Wait for children to finish too if this is a daemon that forks
	# and if the daemon is only ever run from this initscript.
	# If the above conditions are not satisfied then add some other code
	# that waits for the process to drop all resources that could be
	# needed by services started subsequently.  A last resort is to
	# sleep for some time.
	start-stop-daemon --stop --quiet --oknodo --retry=0/30/KILL/5 --exec $DAEMON
	[ "$?" = 2 ] && return 2
	# Many daemons don't delete their pidfiles when they exit.
	rm -f $PIDFILE
	return "$RETVAL"
}

#
# Function that sends a SIGHUP to the daemon/service
#
do_reload() {
	#
	# If the daemon can reload its configuration without
	# restarting (for example, when it is sent a SIGHUP),
	# then implement that here.
	#
	start-stop-daemon --stop --signal 1 --quiet --pidfile $PIDFILE --name $NAME
	return 0
}

case "$1" in
  start)
	[ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME"
	do_start
	case "$?" in
		0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
		2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
	esac
	;;
  stop)
	[ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
	do_stop
	case "$?" in
		0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
		2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
	esac
	;;
  #reload|force-reload)
	#
	# If do_reload() is not implemented then leave this commented out
	# and leave 'force-reload' as an alias for 'restart'.
	#
	#log_daemon_msg "Reloading $DESC" "$NAME"
	#do_reload
	#log_end_msg $?
	#;;
  restart|force-reload)
	#
	# If the "reload" option is implemented then remove the
	# 'force-reload' alias
	#
	log_daemon_msg "Restarting $DESC" "$NAME"
	do_stop
	case "$?" in
	  0|1)
		do_start
		case "$?" in
			0) log_end_msg 0 ;;
			1) log_end_msg 1 ;; # Old process is still running
			*) log_end_msg 1 ;; # Failed to start
		esac
		;;
	  *)
	  	# Failed to stop
		log_end_msg 1
		;;
	esac
	;;
  *)
	#echo "Usage: $SCRIPTNAME {start|stop|restart|reload|force-reload}" >&2
	echo "Usage: $SCRIPTNAME {start|stop|restart|force-reload}" >&2
	exit 3
	;;
esac

:
EOF
fi

if [ "$INSTALL_POSTGRES" == "YES" ]; then
    echo "postgres web user"
    su postgres -c "cd /; createuser -s web"
fi

if [ "$INSTALL_MYSQL" == "YES" ]; then
    mysql -e "grant all privileges on *.* to web@localhost identified by 'web-**'"
fi

echo "nginx django-site template"
echo 'server {
    server_name .HOST;

    error_log (WEB_DIR)/log/HOST-error.log warn;
    access_log (WEB_DIR)/log/HOST-access.log;

    location /static/ {
        root (WEB_DIR)/moocd;
        charset utf-8;
    }   

    location ~ ^/(robots\.txt|favicon\.ico)$ {
        root (WEB_DIR)/PROJECT/static;
    }   

    location / { 
        include uwsgi_params;
        uwsgi_pass unix:(WEB_DIR)/run/PROJECT.sock;
    }   
}

server {
    server_name www.HOST;
    location / { 
        rewrite (.*) http://HOST$1 permanent;
    }   
}' | sed 's!(WEB_DIR)!'$WEB_DIR'!g' > /etc/nginx/host.template

echo "web user environment"
useradd -m web -s /bin/bash
cp ~/.vimrc /home/$WEB_USER
echo 'alias ave="source .env/bin/activate"' >> /home/$WEB_USER/.bashrc

mkdir /home/$WEB_USER/.ssh
cp ~/.ssh/authorized_keys /home/$WEB_USER/.ssh
chown -R web:web /home/$WEB_USER
mkdir $WEB_DIR $WEB_DIR/run $WEB_DIR/log $WEB_DIR/etc \
      $WEB_DIR/etc/uwsgi $WEB_DIR/etc/uwsgi/disabled
chown -R web:web $WEB_DIR
cat > /home/$WEB_USER/.hgrc << 'EOF'
[ui]
username = Name Name <x@x.com>

[extensions]
hgext.fetch=
hgext.record=
EOF
chown web:web /home/$WEB_USER/.hgrc

# Fix access to uwsgi directories
chown root:$WEB_USER /etc/uwsgi/apps-enabled
chown root:$WEB_USER /etc/uwsgi/apps-available
chmod -R g+rwX /etc/uwsgi/apps-enabled
chmod -R g+rwX /etc/uwsgi/apps-available

if [ "$INSTALL_SUPERVISOR" == "YES" ]; then
    addgroup supervisor
    usermod -aG supervisor $WEB_USER
fi

if [ "$INSTALL_MYSQL" == "YES" ]; then
echo '[client]
user=web
password=web-**' > /home/$WEB_USER/.my.cnf
fi

echo '[uwsgi]
processes = 2
socket = (WEB_DIR)/run/PROJECT.sock
home = (WEB_DIR)/PROJECT/.env
module = project.wsgi
chmod-socket = 666
master = true
touch-reload = (WEB_DIR)/PROJECT/project/wsgi.py
chdir = (WEB_DIR)/PROJECT
uid = web
gid = web
reload-on-rss = 500
limit-as = 500
logto = (WEB_DIR)/log/PROJECT-uwsgi.log
disable-logging = 1
post-buffering=100000
#plugin=python3' | sed 's!(WEB_DIR)!'$WEB_DIR'!g' > /etc/uwsgi/apps-available/template.ini

echo "auto-start"
# Настраиваем авто-запуск демонов, запускаем их
update-rc.d uwsgi defaults
update-rc.d nginx defaults
/etc/init.d/nginx start
/etc/init.d/uwsgi start

if [ "$INSTALL_POSTGRES" == "YES" ]; then
    update-rc.d postgresql defaults
    /etc/init.d/postgresql start
fi

if [ "$INSTALL_MYSQL" == "YES" ]; then
    update-rc.d mysql defaults
    /etc/init.d/mysql start
fi

if [ "$INSTALL_MONGO" == "YES" ]; then 
    update-rc.d mongodb defaults
    /etc/init.d/mongodb start
fi

if [ "$INSTALL_ELASTICSEARCH" == "YES" ]; then
    update-rc.d elasticsearch defaults
    /etc/init.d/elasticsearch start
fi

if [ "$INSTALL_SQUID" == "YES" ]; then

echo 'http_port 10000
# cache_peer 82.146.51.167 parent 8080 0 no-query default proxy-only login=*:*
# never_direct allow all

acl localhost src 127.0.0.1/32
acl all src all
http_access allow localhost
http_access deny all
icp_access deny all
cache_dir null /tmp
cache deny all
access_log /var/log/squid/access.log squid
via off
forwarded_for off

acl apache rep_header Server ^Apache
broken_vary_encoding allow apache' > /etc/squid/squid.conf

fi

# echo "console-setup"
# Отконфигурируем консоль
# dpkg-reconfigure console-setup

#echo "example-application"
## Настроим и запустим демонстрационное приложение
## Удалим дефолтный nginx сайт
#unlink /etc/nginx/sites-enabled/default
## Добавим nginx-конфиг для нового сайта
#cat /etc/nginx/host.template | sed 's/PROJECT/test/g' | sed 's/HOST/test.local/g' > /etc/nginx/sites-enabled/test.local
## Перезапустим nginx, чтобы он увидел новый конфиг
#killall -HUP nginx
## Создадим тестовое приложение
#mkdir $WEB_DIR/test
#cat > $WEB_DIR/test/app.py << EOF
##!/usr/bin/env python
## -*- coding: utf-8 -*-
#def application(env, start_response):
    #start_response('200 OK', [('Content-Type','text/html')])
    #return "Application 1 responsed OK"
#EOF
#chown -R web:web $WEB_DIR/test
## Создадим uwsgi-конфиг для нового сайта
#cat $WEB_DIR/etc/uwsgi/disabled/template.ini | sed 's/PROJECT/test/g' > $WEB_DIR/etc/uwsgi/test.ini
#chown web:web $WEB_DIR/etc/uwsgi/test.ini

# Disable in-memory /tmp which was enabled by default in debian squeeze
if [ -z "$(grep RAMTMP /etc/default/rcS)" ]; then
    echo "RAMTMP=no" >> /etc/default/rcS
else
    cat /etc/default/rcS | sed s/RAMTMP=yes/RAMTMP=no/g > /tmp/rcS; cp /tmp/rcS /etc/default/
fi

# Install custom curl
cd /root
wget http://curl.haxx.se/download/curl-7.32.0.tar.gz
tar zxf curl-7.32.0.tar.gz
cd curl-7.32.0
./configure --prefix=/opt/curl --enable-ares --without-libssh2\
            --disable-ipv6 --disable-ldap --disable-ldaps\
            --without-librtmp --disable-rtsp --disable-ftp --disable-dict\
            --disable-telnet --disable-tftp --disable-pop3 --disable-imap\
            --disable-smtp --disable-gopher --without-winssl --without-darwinssl\
            --without-winidn
make
make install

# Setup exim 
dpkg-reconfigure exim4-config

# Setup timezone
dpkg-reconfigure tzdata

if [ "$INSTALL_NODE" == "YES" ]; then
    apt-get install -y nodejs nodejs-legacy npm
    npm install -g bower
fi

# Change space reserved for root (from default 5% to 1%)
tune2fs -m1 $(findmnt -n -o SOURCE /)

echo "It is better to reboot now"



# Sphinx
# ======
# cd /tmp
# wget http://sphinxsearch.com/files/sphinx-2.1.8-release.tar.gz
# tar zxvf sphinx-2.1.8-release.tar.gz
# cd sphinx-2.1.8-release
# ./configure --prefix=/opt/sphinx --enable-id64 --sysconfdir=/etc/sphinxsearch --bindir=/usr/local/bin
# make -j4
# mkdir -p /opt/sphinx/share/man /opt/sphinx/var /opt/sphinx/var/data
# mkdir -p /var/sphinx
# checkinstall --pkgname=sphinx-custom --pkgversion=2.1.8 --nodoc
