#!/bin/bash

# TODO dnsmasq
# apt-get install -y dnsmasq
# put to /etc/dnsmasq.conf
#domain-needed
#bogus-priv
#neg-ttl=3600
#server=8.8.8.8
#server=8.8.4.4
#server=208.67.222.222 # opendns
#server=208.67.220.220 # opendns
#all-servers
#cache-size=10000
#dns-forward-max=300
#cat /etc/resolv.conf > /tmp/resolv.backup
#echo "nameserver 127.0.0.1" > /etc/resolv.conf
#cat /tmp/resolv.backup >> /etc/resolv.conf
#chattr +i /etc/resolv.conf
#systemctl stop named
#apt-get remove named # WTF?
#systemctl enable dnsmasq
#systemctl start dnsmasq

# TODO:
# net.ipv4.tcp_max_syn_backlog = 4096
# net.ipv4.tcp_syncookies = 1
# net.core.somaxconn = 1024
# select default editor for crontab
# remove comments from default crontabs of web and root users
# disable the fucking screen hotkey that locks screen
# mongo: enable wiredTiger engine & remove files from /var/lib/mongod
# simple default nginx website for exporting data

# CONFIGURATION
# Base dir where all website files will be located
# source code, logs, pids, configs
WEB_DIR="/web"
WEB_USER="web"
SERVER_NAME="DEFAULT_SERVER"

# Install and configure mongodb
INSTALL_MONGO="YES"
INSTALL_POSTGRES="NO"
INSTALL_MYSQL="NO"
INSTALL_SUPERVISOR="NO"
INSTALL_NODE="NO"
INSTALL_MEMCACHED="NO"
INSTALL_REDIS="NO"
INSTALL_ELASTICSEARCH="NO"

if [ $SERVER_NAME == "DEFAULT_SERVER" ]; then
    echo "[ERROR] You forgot to change \$SERVER_NAME variable"
    exit 1
fi

if ! grep -q "non-free" /etc/apt/sources.list; then
    echo '[ERROR] Not found "non-free" in /etc/apt/sources.list'
    exit 1
fi

if ! grep -q "jessie" /etc/apt/sources.list; then
    echo '[ERROR] Not found "jessie" in /etc/apt/sources.list'
    exit 1
fi

# Sysctl configuration
cat >> /etc/sysctl.conf << EOF
vm.overcommit_memory=1" >> /etc/sysctl.conf
net.ipv4.netfilter.ip_conntrack_max=1548576
net.ipv4.netfilter.ip_conntrack_tcp_timeout_established=1200
net.ipv4.tcp_fin_timeout=20
net.ipv4.tcp_keepalive_time=1800
net.ipv4.tcp_keepalive_probes=2
net.ipv4.tcp_keepalive_intvl=15
vm.swappiness=1
net.ipv4.ip_local_port_range="15000 61000"
#net.core.rmem_max = 16777216
#net.core.wmem_max = 16777216
#net.core.rmem_default = 16777216
#net.core.wmem_default = 16777216
#net.core.optmem_max = 40960
#net.ipv4.tcp_rmem = 4096 87380 16777216
#net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_no_metrics_save=1
EOF
sysctl -p

cat > /etc/rc.local << EOF
#!/bin/sh -e
echo 32768 > /sys/module/nf_conntrack/parameters/hashsize
exit 0
EOF

echo "vim config"
# Download vim config
wget -O ~/.vimrc http://dumpz.org/25712/nixtext/

if [ "$INSTALL_MONGO" == "YES" ]; then
    echo "Add extra apt repositories"
    echo "deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/3.0 main" > /etc/apt/sources.list.d/mongodb.list
    # mongo key
    apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
fi

if [ "$INSTALL_ELASTICSEARCH" == "YES" ]; then
    wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add -
    echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | tee /etc/apt/sources.list.d/elasticsearch-2.x.list
fi

echo "Add noatime to /etc/fstab"
cp /etc/fstab ~/fstab.backup
awk '$2=="/" && $3=="ext4" && $4!~/noatime/ {$4=$4",noatime"} 1' /etc/fstab > /tmp/fstab
mv /tmp/fstab /etc/fstab

# WTF?
apt-get install -y debian-keyring

# ??? systemctl enable rpcbind

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
apt-get update

echo "Doing aptitude dist-upgrade"
apt-get -y dist-upgrade

# Setup locales
apt-get install -y locales 
echo "LANG=en_US.UTF-8" > /etc/default/locale
cat > /etc/locale.gen << EOF
en_US.UTF-8 UTF-8
ru_RU.UTF-8 UTF-8
EOF
locale-gen

echo "apt-get install"
# psmsic --> pkill
# apache-utils --> ab
# libxml2-dev libxslt1-dev --> build lxml from source
# libcurl4-openssl-dev --> build pycurl from source
# libjpeg8-dev libfreetype6-dev --> build PIL from source
# postgresql-server-dev-9.4 --> build psycopg from source
# libmysqld-dev --> build mysql driver from source
apt-get install -y \
    perl perl-modules perl-base \
    vim-nox \
    psmisc screen apache2-utils whois sudo less gettext \
    exim4 nginx-full \
    mercurial subversion git-core \
    python python-setuptools python-dev \
    libxml2-dev libxslt1-dev \
    gcc g++ \
    libcurl4-openssl-dev libmemcached-dev libssl-dev \
    libjpeg-dev libfreetype6-dev \
    libmysqld-dev \
    bind9-host \
    postgresql-server-dev-9.4 \
    unzip make \
    python-crypto geoip-database \
    libc-ares-dev \
    openvpn iftop iotop \
    numactl unrar \
    python3.4 python3.4-dev python3-setuptools \
    pigz nfs-common curl firmware-linux-nonfree \
    lshw conntrack conntrackd

if [ "$INSTALL_POSTGRES" == "YES" ]; then
    apt-get install -y \
    postgresql-9.4 python-psycopg2
fi

if [ "$INSTALL_MYSQL" == "YES" ]; then
    apt-get install -y mysql-server-5.5
fi

if [ "$INSTALL_MEMCACHED" == "YES" ]; then
    apt-get install -y memcached
fi

if [ "$INSTALL_REDIS" == "YES" ]; then
    apt-get install -y redis-server
fi

if [ "$INSTALL_ELASTICSEARCH" == "YES" ]; then
    apt-get install -y openjdk-7-jre-headless elasticsearch
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
    apt-get install -y mongodb-org
fi

echo "vim default editor"
# Set vim default editor in the system
#echo 'export EDITOR="vim"' >> /root/.bashrc
update-alternatives --set editor /usr/bin/vim.nox

echo "python tools"

# First install python3 things
easy_install-3.4 -U pip distribute
pip3 install -U virtualenv sr pillow \
    pymongo lxml pycurl grab argparse redis qr gunicorn

# Second install python2 things to make them be default things
easy_install-2.7 -U pip
pip2 install -I distribute virtualenv sr pillow \
    pymongo lxml pycurl grab argparse redis qr gunicorn

if [ "$INSTALL_SUPERVISOR" == "YES" ]; then
    pip install -U supervisor
    cat > /etc/supervisord.conf << EOF
[unix_http_server]
file=/var/run/supervisor.sock
chmod=0770
chown=root:web

#[inet_http_server]
#port=*:9000
#username=***
#password=***

[supervisord]
logfile=/var/log/supervisord.log
logfile_maxbytes=500MB
logfile_backups=10
loglevel=info
pidfile=/var/run/supervisord.pid
nodaemon=false
minfds=1024
minprocs=200

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock

#[include]
#files = /web/site1/conf/supervisor.conf /web/site2/conf/supervisor.conf
EOF

    cat > /etc/systemd/system/supervisor.service << EOF
[Unit]
Description=Supervisor process control system for UNIX
Documentation=http://supervisord.org
After=network.target

[Service]
ExecStart=/usr/local/bin/supervisord -n -c /etc/supervisord.conf
ExecStop=/usr/local/bin/supervisorctl $OPTIONS shutdown
ExecReload=/usr/local/bin/supervisorctl $OPTIONS reload
KillMode=process
Restart=on-failure
RestartSec=50s

[Install]
WantedBy=multi-user.target
EOF
fi

if [ "$INSTALL_MONGO" == "YES" ]; then
     cat > /etc/init.d/disable-transparent-hugepages << EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:          disable-transparent-hugepages
# Required-Start:    $local_fs
# Required-Stop:
# X-Start-Before:    mongod mongodb-mms-automation-agent
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Disable Linux transparent huge pages
# Description:       Disable Linux transparent huge pages, to improve
#                    database performance.
### END INIT INFO

case \$1 in
  start)
    if [ -d /sys/kernel/mm/transparent_hugepage ]; then
      thp_path=/sys/kernel/mm/transparent_hugepage
    elif [ -d /sys/kernel/mm/redhat_transparent_hugepage ]; then
      thp_path=/sys/kernel/mm/redhat_transparent_hugepage
    else
      return 0
    fi

    echo 'never' > \${thp_path}/enabled
    echo 'never' > \${thp_path}/defrag

    unset thp_path
    ;;
esac
EOF
    chmod 755 /etc/init.d/disable-transparent-hugepages
    update-rc.d disable-transparent-hugepages defaults
    /etc/init.d/disable-transparent-hugepages start
fi

if [ "$INSTALL_POSTGRES" == "YES" ]; then
    echo "postgres web user"
    su postgres -c "cd /; createuser -s web"
    # TODO: update postgresql.conf
    # 1) set shared_buffers to 25% ram
    # 2) set effective_cache_size to 50% ram
    # 3) set synchronous_commit=off
fi

if [ "$INSTALL_MYSQL" == "YES" ]; then
    echo ""
    #mysql -e "grant all privileges on *.* to web@localhost identified by 'web-**'"
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
        include proxy_params;
        proxy_pass http://unix:(WEB_DIR)/run/PROJECT.sock:;
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
mkdir $WEB_DIR $WEB_DIR/run $WEB_DIR/log $WEB_DIR/etc
chown -R web:web $WEB_DIR
cat > /home/$WEB_USER/.hgrc << 'EOF'
[ui]
username = Name Name <x@x.com>

[extensions]
hgext.fetch=
hgext.record=
EOF
chown web:web /home/$WEB_USER/.hgrc


if [ "$INSTALL_SUPERVISOR" == "YES" ]; then
    systemctl daemon-reload
    systemctl enable supervisor
    systemctl start supervisor
    chown root:$WEB_USER /etc/supervisord.conf
    chmod g+rw /etc/supervisord.conf
fi

if [ "$INSTALL_MYSQL" == "YES" ]; then
echo '[client]
user=root
password=' > /home/$WEB_USER/.my.cnf
fi

echo "auto-start"
# Настраиваем авто-запуск демонов, запускаем их
/etc/init.d/nginx start

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
    systemctl enable elasticsearch
    systemctl start elasticsearch
fi

# Disable in-memory /tmp which was enabled by default in debian squeeze
if [ -z "$(grep RAMTMP /etc/default/rcS)" ]; then
    echo "RAMTMP=no" >> /etc/default/rcS
else
    cat /etc/default/rcS | sed s/RAMTMP=yes/RAMTMP=no/g > /tmp/rcS; cp /tmp/rcS /etc/default/
fi

# Install custom curl
cd /root
wget http://curl.haxx.se/download/curl-7.46.0.tar.gz
tar zxf curl-7.46.0.tar.gz
cd curl-7.46.0
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

echo $SERVER_NAME > /etc/hostname
echo "127.0.0.1 $SERVER_NAME" >> /etc/hosts
hostname $SERVER_NAME

echo '#!/bin/sh
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
echo "!!! All iptables rules removed !!!"
' > /sbin/fw_clear.sh
chmod u+x /sbin/fw_clear.sh

# TODO: put fw_clear.sh into into /etc/rc.local

echo "[DEBUG] Content of /etc/fstab. Check it is OK."
cat /etc/fstab
echo "[HINT] Reboot server to ensure you have not break something"
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
