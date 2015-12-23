#!/bin/bash

# status
isinstall=1
curdir=`pwd`

echo_nginx_module_src="https://github.com/openresty/echo-nginx-module.git"
echo_nginx_module_dir="echo-nginx-module"

nginx_version="1.8.0"
nginx_file="nginx-${nginx_version}.tar.gz"
nginx_src="http://nginx.org/download/nginx-${nginx_version}.tar.gz"

nginx_sbin="/usr/sbin/nginx"
nginx_prefix="/home/nginx"

configure_install_path="--prefix=${nginx_prefix} 
--sbin-path=/usr/sbin/nginx 
--conf-path=/etc/nginx/nginx.conf 
--error-log-path=/var/log/nginx/error.log 
--pid-path=/var/run/nginx.pid 
--lock-path=/var/lock/subsys/nginx 
--http-log-path=/var/log/nginx/access.log"

configure_install_module="--with-http_ssl_module 
--with-http_stub_status_module 
--with-http_gzip_static_module 
--with-pcre 
--add-module=${curdir}/$echo_nginx_module_dir"

configure_install_other="--user=nginx 
--group=www"

configure_install="$configure_install_path 
$configure_install_module 
$configure_install_other"

configure_prev=""
configure_add=""


usage_string="usage: $0 [option]\n
options:\n
    install              install nginx\n
    resinstall <value>   reinstall nginx\n"

while [ $# -ne 0 ]
do
	case "$1" in
		install)
			isinstall=1
			;;
		reinstall)
			isinstall=2
			configure_add="$2"
			shift
			;;
		*)
			echo "ERROR: unknow parameter $1"
			exit 1
			;;
	esac
	shift
done

if [ $isinstall -eq 1 ];then
	configure_prev="$configure_install"
elif [ $isinstall -eq 2 ];then
	configure_prev="$configure_install"
fi

groupadd -f -r www
useradd -s /sbin/nologin -g www -r nginx

if [ ! -d "$echo_nginx_module_dir" ];then
	git clone "$echo_nginx_module_src"
fi

if [ ! -f "$(basename $nginx_src)" ];then
	wget --tries=10 --connect-timeout=60 "$nginx_src"
fi

if [ ! -d "$(basename $nginx_src | sed s/\.tar\.gz//g)" ];then
	tar -zxf "$(basename $nginx_src)"
fi

set -e
cd "$(basename $nginx_src | sed s/\.tar\.gz//g)"

./configure $configure_prev $configure_add
make -j$(cat /proc/cpuinfo | grep processor | wc -l)

set +e
if [ $isinstall -eq 1 ];then
	set -e
	make install
elif [ $isinstall -eq 2 ];then
	set -e
	cp -f "$nginx_sbin" "${nginx_sbin}.bak"
	cp ./objs/nginx "$nginx_sbin"
	exit 0
fi

cd "$curdir"

set +e
if [ ! -f /etc/init.d/nginx ];then
	cp init.d.nginx /etc/init.d/nginx
	chmod u+x /etc/init.d/nginx
fi

if [ -f ./conf.nginx.conf ];then
	cp -f ./conf.nginx.conf /etc/nginx/nginx.conf
fi


