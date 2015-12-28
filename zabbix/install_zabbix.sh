#!/bin/bash

curdir=`pwd`
tools="mysql-dev net-snmp-devel curl-devel perl-DBI php-gd php-mysql php-bcmath php-mbstring 
php-xml"

root_mysql_password=""

zabbix_log_path="/tmp/"
zabbix_pid_path="/tmp/"
zabbix_php="zabbix_php"
zabbix_uri="http://www.fossies.org/linux/misc/zabbix-2.4.7.tar.gz"
zabbix_file="$(basename $zabbix_uri)"
zabbix_dir="$(echo $zabbix_file | sed s/\.tar\.gz//g)"
zabbix_mysql_user="zabbix_user"
zabbix_mysql_password=""
zabbix_mysql_url="localhost"
zabbix_configure="--prefix=/usr/local/zabbix 
--with-mysql 
--with-net-snmp 
--with-libcurl 
--enable-server 
--enable-agent 
--enable-proxy"

zabbix_agent_user="zabbix_agent"
zabbix_agent_password=""

www_dir="/home/www"

usage_string="usage: $0 password_of_root password_of_zabbix password_of_zabbix_agent"
PATH=/usr/local/mysql/bin:$PATH

sqlcmd_make()
{
	SQLCMD="create database if not exists zabbix character set utf8;"
	SQLCMD+="use mysql;"
	SQLCMD+="grant all privileges on zabbix.* to $zabbix_mysql_user@'$zabbix_mysql_url' identified by '$zabbix_mysql_password';"
	SQLCMD+="grant usage on *.* to $zabbix_agent_user@'$zabbix_mysql_url' identified by '$zabbix_agent_password'"
}

usage()
{
	echo -e "$usage_string"
	exit 1
}

if [ $# -lt 3 ];then
	echo "ERROR: need more parameters!"
	usage
fi

root_mysql_password="$1"
zabbix_mysql_password="$2"
zabbix_agent_password="$3"

groupadd -f zabbix
useradd -g zabbix -m zabbix

if [ ! -f "$zabbix_file" ];then
	wget --tries=10 --connect-timeout=60 "$zabbix_uri"
fi

if [ ! -d "$zabbix_dir" ];then
	tar -zxf "$zabbix_file" || exit 1;
fi

set -e

yum -y install $tools

sqlcmd_make
mysql -h 127.0.0.1 -u root --password="$root_mysql_password" -e "$SQLCMD"

cd "${zabbix_dir}/database/mysql"
mysql -h 127.0.0.1 -u root --password="$root_mysql_password" zabbix < schema.sql
mysql -h 127.0.0.1 -u root --password="$root_mysql_password" zabbix < images.sql
mysql -h 127.0.0.1 -u root --password="$root_mysql_password" zabbix < data.sql


cd "${curdir}/$zabbix_dir"
./configure $zabbix_configure
make -j$(cat "/proc/cpuinfo" | grep processor | wc -l)
make install

mkdir -p /etc/zabbix
mkdir -p /etc/zabbix/zabbix_agentd.conf.d
mkdir -p /etc/zabbix/zabbix_server.conf.d
cp -rf ./conf/* /etc/zabbix/
chown -R zabbix:zabbix /etc/zabbix

cd "$curdir"
# zabbix scripts
mkdir -p /home/zabbix/scripts

set +e
# copy scripts files
cp -f scripts.* /home/zabbix/scripts/
chmod u+x /home/zabbix/scripts/scripts.*

# copy zabbix userparameter file
cp -f userparameter_server* /etc/zabbix/zabbix_server.conf.d/
cp -f userparameter_agentd* /etc/zabbix/zabbix_agentd.conf.d/

# copy zabbix service file
cp -f init.d.zabbix_server	 /etc/init.d/zabbix_server
cp -f init.d.zabbix_agentd   /etc/init.d/zabbix_agentd

set -e
# copy zabbix configure file
cp -f conf.zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf
cp -f conf.zabbix_server.conf /etc/zabbix/zabbix_server.conf

path_replace()
{
	# $1 PidFile  $2 zabbix_agentd.pid $3 /tmp/ $4 /etc/zabbix/zabbix_agentd.conf
	sed -i "s#^${1}=.*${2}#${1}=${3}${2}#g" "$4"
}

# alert zabbix configure file: LogFile£¬ PidFile
path_replace PidFile zabbix_agentd.pid $zabbix_pid_path /etc/zabbix/zabbix_agentd.conf
path_replace LogFile zabbix_agentd.log $zabbix_log_path /etc/zabbix/zabbix_agentd.conf

path_replace PidFile zabbix_server.pid $zabbix_pid_path /etc/zabbix/zabbix_server.conf
path_replace LogFile zabbix_server.log $zabbix_log_path /etc/zabbix/zabbix_server.conf

# alert zabbix_server confingure file
sed -i "s#^DBName=.*#DBName=zabbix#g" /etc/zabbix/zabbix_server.conf
sed -i "s#^DBUser=.*#DBUser=${zabbix_mysql_user}#g" /etc/zabbix/zabbix_server.conf
sed -i "s#^DBPassword=.*#DBPassword=${zabbix_mysql_password}#g" /etc/zabbix/zabbix_server.conf

# alert zabbix_agentd configure file
sed -i "s#^Hostname=.*#Hostname=$(hostname)#g" /etc/zabbix/zabbix_agentd.conf


##### userparameter configure
# userparameter_mysql
cp -f conf.my.cnf /etc/zabbix/my.cnf
sed -i "s#^user\s+=.*#user=${zabbix_agent_user}#g" /etc/zabbix/my.cnf
sed -i "s#^password\s*=.*#password=${zabbix_agent_password}#g" /etc/zabbix/my.cnf
sed -i "s#/var/lib/zabbix#/etc/zabbix#g" /etc/zabbix/zabbix_agentd.conf.d/userparameter_agentd_mysql.conf

set +e

# copy php frontend files
if [ -d "$zabbix_php" ];then
	cp -rf "$zabbix_php" "${www_dir}/zabbix"
else
	tar -zxf "${zabbix_php}.tar.gz" || cp -rf "${zabbix_dir}/frontends/php" "${www_dir}/zabbix" || exit 1;
fi

set -e
chown -R zabbix:zabbix  "${www_dir}/zabbix"

# copy nginx conf file
cp -f conf.nginx.zabbix.conf /etc/nginx/conf.d/zabbix.conf

echo "install complete!"
echo "you should configure php.ini, like"
echo -e "vim php.ini
max_execution_time = 300
max_input_time = 300
memory_limit = 128M
post_max_size = 32M
date.timezone = Asia/Shanghai
mbstring.func_overload=2"

echo ""
echo "run zabbix: service zabbix_server start"
echo "run zabbix: service zabbix_agentd start"
echo ""

echo "in php 7.0.0 and newer, you should alter the file 
${www_dir}/zabbix/include/classes/setup/CFontendSetup.php
   if(version_compare(PHP_VERSION, '5.6', '>=') && version_compare(PHP_VERSION, '7.0.0', '<')){
         $result[] = $this->checkPhpAlwaysPopulateRawPostData();
   }"
echo ""

echo "open browser with http://zabbixIP/zabbix complete the frontend configure"
echo ""






