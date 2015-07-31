#!/bin/bash

set -e




if [ `whoami` != "root" ]
then
  echo "use this script need user root"
  exit 1
fi

. utility.sh

# tool lib install

# nginx install

# mysql

# php & php-fpm

