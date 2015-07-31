#!/bin/bash

if [ $# -ne 3 ]
then
  echo "Error: need 3 parameters!"
  exit 1
fi

. utility.sh || exit 1


CHECK_VERSION="$1"
CHECK_CMD="$2"
CHECK_WHEREIS="$3"

CHECK_CACHE_FILE="_tc.log"
CHECK_CACHE="_tc.cache"

export PATH=$PATH:/sbin:/usr/sbin:/usr/bin:/usr/local/bin

set +e

if [ -e $CHECK_CACHE_FILE ]
then
  eval_run_exit "rm -f $CHECK_CACHE_FILE"
fi

check_version_one()
{
	local retvalue=

	echo_check "checking $1 ..." 
	
	$1 --version &>$CHECK_CACHE
	retvalue=$?
	if [ $retvalue -ne 127 ];then
		echo_check "" 0

		line="$( cat $CHECK_CACHE | grep -v '^$' | sed -n '1p' )"
		echo -e " $line"
		
		return 0
	else
		echo_check "" 1
		echo ""
		return 1
	fi
}

check_version()
{
	local retvalue=

	while [ $# -ne 0 ]
	do
		check_version_one $1
		retvalue=$?
		if [ $retvalue -ne 0 ];then
			echo "$1" >> $CHECK_CACHE_FILE
		fi
		shift
	done
}

check_cmd_one()
{
	local retvalue=

	echo_check "checking $1 ..." 
	
	$1 &>$CHECK_CACHE
	retvalue=$?
	if [ $retvalue -ne 127 ];then
		echo_check "" 0
		echo ""
		return 0
	else
		echo_check "" 1
		read line < "$CHECK_CACHE"
		echo -e " $line"
		return 1
	fi
}

check_cmd()
{
	local retvalue=

	while [ $# -ne 0 ]
	do
		check_cmd_one $1
		retvalue=$?
		if [ $retvalue -ne 0 ];then
			echo "$1" >> $CHECK_CACHE_FILE
		fi
		shift
	done
}

get_whereis()
{
	shift
	echo "$*"
}

check_whereis_one()
{
	local retvalue=
	local value=
	echo_check "checking $1 ..."
	
	value=$(whereis $1)
	value=$(get_whereis $value)

	if [ -n "$value" ];then
		echo_check "" 0
		echo "  $value"
		return 0
	else
		echo_check "" 1
		echo ""
		return 1
	fi
}

check_whereis()
{
	local retvalue=

	while [ $# -ne 0 ]
	do	
		check_whereis_one $1
		retvalue=$?
		if [ $retvalue -ne 0 ];then
			echo "$1" >> $CHECK_CACHE_FILE
		fi
		shift
	done
}

check_all()
{
	check_version $CHECK_VERSION
	check_cmd $CHECK_CMD
	check_whereis $CHECK_WHEREIS

	echo "Check Finish!"

	# cmd not install
	if [ -e $CHECK_CACHE_FILE ];then
		if [ -s $CHECK_CACHE_FILE ];then
			echo "The command below not find:"
			echo -n "  "
			while read line
			do
				echo -n "$line "
			done < $CHECK_CACHE_FILE
			echo -e "\n"
			return 1
		fi
	fi

	return 0
}


autoinstall()
{
  
}

remove_cache()
{
	# remove case file
	if [ -e "$CHECK_CACHE" ];then
		rm -f $CHECK_CACHE
	fi

	if [ -e "$CHECK_CACHE_FILE" ];then
		rm -f $CHECK_CACHE_FILE
	fi
}



