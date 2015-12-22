#!/bin/bash

tools_compiler="make cmake automake autoconf gcc gcc-c++"
tools_nginx_dep="zlib zlib-devel openssl openssl-devel pcre pcre-devel curl libcurl-devel libcrypt "
tools_mysql_dep="bison bison-devel ncurses-devel"
tools_php_dep="mhash libiconv libmcrypt libjpeg-devel libpng-devel 
libxml2-devel freetype gd-devel zip curl libcurl-devel "
tools_other="lrzsz wget git svn"
tools="$tools_compiler $tools_nginx_dep $tools_mysql_dep $tools_php_dep $tools_other"

yum -y install $tools
