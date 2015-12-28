#!/bin/bash

curdir=`pwd`
php_url="http://php.net/distributions/php-7.0.1.tar.gz"
php_file="$(basename "$php_url")"
php_dir="$(echo $php_file | sed s/\.tar\.gz//g)"

php_prefix="/usr/local/php"

php_configure="--prefix=${php_prefix} 
--with-config-file-path=/etc
--with-MySQL=/usr/local/mysql 
--with-mysqli=/usr/local/mysql/bin/mysql_config 
--with-fpm-user=php
--with-fpm-group=www
--enable-safe-mode 
--enable-ftp 
--enable-zip 
--enable-bcmath 
--enable-mbstring 
--enable-sockets
--with-gettext  
--with-jpeg-dir=/usr/lib  
--with-png-dir=/usr/lib  
--with-freetype-dir=/usr/lib 
--with-iconv 
--with-libXML-dir=/usr/lib 
--with-XMLrpc  
--with-zlib-dir=/usr/lib 
--with-gd 
--with-mhash  
--with-openssl 
--enable-gd-native-ttf 
--with-curl 
--with-curlwrappers 
--enable-fpm 
--enable-fastCGI 
--enable-force-CGI-redirect"

if [ ! -f "$php_file" ];then
	wget --tries=10 --connect-timeout=60 "$php_url"
fi

if [ ! -d "$php_dir" ];then
	tar -zxf "$php_file"
fi

groupadd -f -r www
useradd -s /sbin/nologin -g www -r php

set -e
cd "$php_dir"
./configure $php_configure
make -j$(cat "/proc/cpuinfo" | grep processor | wc -l)
make install

cd "$curdir"
#cp -f php.ini-production /etc/php.ini
cp -f conf.php.ini /etc/php.ini

#cp -f $php_prefix/etc/php-fpm.conf.default /etc/php-fpm.conf
cp -f conf.php-fpm.conf /etc/php-fpm.conf

#cp -f $php_prefix/etc/php-fpm.d/www.conf.default $php_prefix/etc/php-fpm.d/www.conf
cp -f conf.php-fpm.www.conf $php_prefix/etc/php-fpm.d/www.conf

cp -f init.d.php-fpm /etc/init.d/php-fpm
chmod u+x /etc/init.d/php-fpm
