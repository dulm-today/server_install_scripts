#!/bin/bash

curdir=`pwd`

mysql_url="http://www.mysql.com//Downloads/MySQL-5.6/mysql-5.6.28.tar.gz"
mysql_file="$(basename "$mysql_url")"
mysql_dir="$(echo $mysql_file | sed s/\.tar\.gz//g)"
mysql_prefix="/usr/local/mysql"
mysql_data="/home/mysql"
mysql_conf="conf.my.conf"

#mysql config
root_passwd=""

usage_string="usage: $0 root_passwd"

cmake_args_make()
{
	CMAKE_ARGS="-DCMAKE_INSTALL_PREFIX=$mysql_prefix \
-DMYSQL_DATADIR=$mysql_data \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DDEFAULT_CHARSET=utf8 \
-DWITH_EXTRA_CHARSETS=all \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_DEBUG=0"

}

sql_cmd_make()
{
	SQLCMD="use mysql;"
	SQLCMD+="update user set Password=password('$root_passwd') where User='root';"
	SQLCMD+="delete from user where User='';"
	#SQLCMD+="drop database test;"

	#if [ "$DATABASE" != "*" ];then
	#	SQLCMD+="create database $DATABASE;"
	#fi

	#SQLCMD+="grant all on $DATABASE.* to $USERNAME@'%' identified by '$USERPASSWD';"
	#SQLCMD+="grant all on $DATABASE.* to $USERNAME@localhost identified by '$USERPASSWD';"
	SQLCMD+="flush privileges;"
}

usage()
{
	echo "$usage_string"
	exit 1
}

if [ $# -lt 1 ];then
	usage
fi

root_passwd="$1"

# remove old
rpm -e --nodeps $(rpm -qa | grep mysql)

if [ ! -f "$mysql_file" ];then
	wget --tries=10 --connect-timeout=60 "$mysql_url"
fi

if [ ! -d "$mysql_dir" ];then
	tar -zxf "$mysql_file"
fi

groupadd -f -r mysql
useradd -s /sbin/nologin -g mysql -r mysql

mkdir "$mysql_prefix"
mkdir "$mysql_data"

set -e 
cd "$mysql_dir"
cmake_args_make
cmake $CMAKE_ARGS
make -j$(cat "/proc/cpuinfo" | grep processor | wc -l)
make install

cd "$mysql_prefix"
chown -R mysql .
chgrp -R mysql .

scripts/mysql_install_db --user=mysql --basedir=$mysql_prefix --datadir=$mysql_data
chown -R mysql "$mysql_data"
cp -f "support-files/mysql.server" "/etc/init.d/mysqld"

cd "$curdir"

set +e
if [ -f "$mysql_conf" ];then
	cp "$mysql_conf" /etc/my.cnf
	sed -i "s#^basedir=.*#basedir="${mysql_prefix}"#g" /etc/my.cnf
	sed -i "s#^datadir=.*#datadir="${mysql_data}"#g" /etc/my.cnf
fi

set -e
/sbin/service mysqld start

sql_cmd_make
$mysql_prefix/bin/mysql -h 127.0.0.1 -uroot -e "$SQLCMD"
# mysql -h 127.0.0.1 -uroot -p


