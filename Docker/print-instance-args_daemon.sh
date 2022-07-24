#!/bin/bash

NAME=`basename $( dirname ${BASH_SOURCE[0]} )`
if [ "${NAME}" == "." ]; then
	NAME=`basename $(pwd)`
fi
DIRNAME=`dirname ${BASH_SOURCE[0]}`
DIRNAME=`readlink -f ${DIRNAME}`
if [ "${DIRNAME}" == "." ]; then
	DIRNAME=`pwd`
fi
INSTANCECOUNT=0
for i in ${DIRNAME}/print-instance-args_*.sh ; do
	INSTANCE=`basename $i `   #Just the file
	INSTANCE=${INSTANCE:20}   #Remove the first 20 chars (print-instance-args_)
	INSTANCE="_"${INSTANCE:0:-3} #Remove the last  3 chars (.sh)
	if [ "${INSTANCE:1}" == "main" ]; then
		INSTANCE=""
	fi
	if [ "${INSTANCE:1}" == "*" ]; then
		break;
	else
		INSTANCECOUNT=` expr ${INSTANCECOUNT} + 1 `
	fi
	if [ "${1}" == "${INSTANCE:1}" ]; then
		if [ "${MATCHED}" == "1" ]; then
			break
		fi
		if [ "${1}" == "${INSTANCE:1}" ]; then
			MATCHED=1
		fi
		#Do this for each of them (or the match)
		#echo Name: ${NAME}, DirName: ${DIRNAME}, Instance: ${INSTANCE:1}, Counter: ${INSTANCECOUNT}.
		test -e "${DIRNAME}"/env.list && echo '--env-file '"${DIRNAME}"/env.list
		#echo '--env DB_ADDR="<db-host>"
		#echo '--env DB_NAME="<db-name>"
		#echo '--env DB_USER="<db-username>"
		#echo '--env DB_PASS="<db-password>"
		echo '--init'
		echo '--label VPN=false'
		echo '--publish 27500:27500/udp'
		echo '--volume /u01/Docker/'${NAME}'/:/srv/logs/:rw'
		if [ ! -d /u01/Docker/${NAME}/ ]; then
			mkdir -p /u01/Docker/${NAME}/
		fi
	fi
done
if [ "${INSTANCECOUNT}" == "0" ]; then
	echo ${0}: No instances found, nothing was done. >&2
fi
#EXTRA Run: /docker-entrypoint.bash daemon
