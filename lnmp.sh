#!/bin/bash

set -e




if [ `whoami` != "root" ]
then
  echo "run this script as root must!"
  exit 1
fi

. utility.sh

# tool lib install
tools.sh

# nginx install

# mysql

# php & php-fpm

