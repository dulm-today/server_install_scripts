#!/bin/bash

mysql_root_passwd=""
wordpress_passwd=""

scripts_file="tools.sh install_nginx.sh install_mysql.sh install_php.sh install_wordpress.sh"
usage_string="usage: $0 mysql_root_password wordpress_password"

usage()
{
	echo -e "$usage_string"
	exit 1
}

if [ `whoami` != "root" ];then
  echo "run this script as root must!"
  exit 1
fi

if [ $# -lt 2 ];then
	echo "ERROR: need more parameter!"
	usage
fi

mysql_root_passwd="$1"
wordpress_passwd="$2"

set -e


chmod u+x $scripts_file

# tool lib install
./tools.sh

# nginx install
./install_nginx.sh install

# mysql
./install_mysql.sh "$mysql_root_passwd"

# php & php-fpm
./install_php.sh

# wordpress
./install_wordpress.sh "$mysql_root_passwd" "$wordpress_passwd"


