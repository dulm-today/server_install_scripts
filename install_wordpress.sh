#!/bin/bash

wp_url="https://wordpress.org/wordpress-4.4.tar.gz"
wp_file="$(basename "$wp_url")"
wp_dir="$(echo $wp_file | sed s/\.tar\.gz//g)"

mysql_prefix="/usr/local/mysql"
mysql_root_passwd=""
www_dir="/home/www"
www_passwd=""

sqlcmd_make()
{
	SQLCMD="create database if not exists wordpress;
	grant all on wordpress.* to wordpress@localhost identified by \"$www_passwd\";"
}

usage_string="usage: $0 root_passwd wordpress_passwd"

usage()
{
	echo -e "$usage_string"
	exit 1
}

if [ $# -lt 2 ];then
	usage
fi

mysql_root_passwd="$1"
www_passwd="$2"

if [ ! -f "$wp_file" ];then
	wget "$wp_url"
fi

if [ ! -d "wordpress" ];then
	tar -zxf "$wp_file"
fi

set -e
mkdir -p "$www_dir"
sqlcmd_make
$mysql_prefix/bin/mysql -u root --password="$mysql_root_passwd" -e "$SQLCMD"
cp -af ./wordpress/* $www_dir/

