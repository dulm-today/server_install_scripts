#!/bin/bash


EVAL_RUN_ERROR="_error.log"
ECHO_LINE_ADD=32
ECHO_LINE=32

echo_check()
{
	local num=
	local len=
  if [ -n "$1" ];then
    len=`expr length "$1"`
    num=$ECHO_LINE
    while [ $num -lt $len ]
    do
      num=$[ num + ECHO_LINE_ADD ]
    done
    printf "%-""$num""s" "$*"
  else
      # retvalue
    if [[ "$2" =~ ^[0-9]+$ ]];then
      if [ $2 -eq 0 ];then
        printf "%s" "[   OK   ]"
      else
        printf "%s" "[ FAILED ]"
      fi
    else
      printf "[ %s ]" "$2"
    fi      
  fi
}

eval_run()
{
  local retvalue=
  echo_check "$* ..."
  eval "$* &>$EVAL_RUN_ERROR"
  retvalue=$?
  if [ $retvalue -ne 0 ];then
    echo_check "" 1
    echo ""
    cat $EVAL_RUN_ERROR | while read line
    do
      echo $line
    done
  else
    echo_check "" 0
  fi
  echo ""
  return $retvalue
}

eval_run_exit()
{
	local retvalue=
	eval_run "$*"
	retvalue=$?
	if [ $retvalue -ne 0 ];then
		exit 1
	fi
}

# $1 filename
file_exist()
{
	local retvalue=
	echo_check "check file exists: $1 ..."
	if [ -e "$1" ];then
		echo_check "" 0
		retvalue=0
	else
		echo_check "" 1
		retvalue=1
	fi
	echo ""
	return $retvalue
}

file_exist_exit()
{
	local retvalue=
	file_exist "$1"
	retvalue=$?
	if [ $retvalue -ne 0 ];then
		exit 1
	fi
}

file_executable()
{
	local retvalue=
	echo_check "check file executable: $1 ..."
	if [ -x "$1" ];then
		echo_check "" 0
		echo ""
	else
		echo_check "" 1
		echo ""
		eval_run_exit "chmod ug+x $1"
	fi
}

dir_exist()
{
	local retvalue=
	echo_check "check dir exists: $1 ..."
	if [ -d "$1" ];then
		echo_check "" 0
		retvalue=0
	else
		echo_check "" 1
		retvalue=1
	fi
	echo ""
	return $retvalue
}

dir_exist_exit()
{
	local retvalue=
	dir_exist "$1"
	retvalue=$?
	if [ $retvalue -ne 0 ];then
		exit 1
	fi
}

dir_exist_create()
{
	local retvalue=
	local var=
	echo_check "check dir exist: $1 ..."
	if [ -d "$1" ];then
		echo_check "" 0
		echo ""
		retvalue=0
	elif [ -e "$1" ];then
		echo_check "" 1
		echo -e "  file \"$1\" already exists!"
		exit 1
	else
		echo_check "" "CREATE"
		echo ""
		if [ $2 -eq 0 ];then
			eval_run_exit "mkdir -p $1"
		else
			echo_check "create [y/*]?"
			read var
			if [ $var == "y" -o $var == "Y" ];then
				eval_run_exit "mkdir -p $1"
			else
				exit 1
			fi
		fi
	fi
	return $retvalue
}

ask()
{
	printf "%s [y/*]?" "$1"
	read var
	if [ $var == "y" -o $var == "Y" ];then
		return 0
	else
		return 1
	fi
}

real_path()
{
	local realpath=$(dirname $1)
	cd $realpath || { echo ""; return 1; }
	realpath="`pwd`$(basename $1)"
	cd "$CURDIR"
	echo "$realpath"
}

max()
{
	if [ $1 -ge $2 ];then
		echo "$1"
	else
		echo "$2"
	fi
}


