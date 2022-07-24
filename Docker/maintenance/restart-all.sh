#!/bin/bash

#if [ ! -t 1 ]; then
#	exit
#fi

if [ "${1}" == "filter" -a "${2}" != "" ]; then
	PATHSEARCH="/var/scripts/docker/*${2}*"
else
	PATHSEARCH="/var/scripts/docker/*"
fi

for i in ${PATHSEARCH}; do
	if [ -d "${i}" ]; then
		if [ ! -f ${i}/disabled -a "${i}" != "/var/scripts/docker/scripts" ]; then
			for j in ${i}/print-instance-args_*.sh ; do
				INSTANCE=`basename $j `   #Just the file
				INSTANCE=${INSTANCE:20}   #Remove the first 20 chars (print-instance-args_)
				INSTANCE="_"${INSTANCE:0:-3} #Remove the last  3 chars (.sh)
				if [ "${INSTANCE:1}" == "main" ]; then
					INSTANCE=""
				fi
				if [ "${INSTANCE:1}" == "*" ]; then
					break;
				fi
				if [ ! -f ${i}/disabled_${INSTANCE:1} ]; then
					${i}/restart.sh ${INSTANCE:1} | tee /dev/null
					sleep 1
					RET=`${i}/check.sh ${INSTANCE:1} `
					if [ "${RET}" == "" ]; then
						echo It appears this container stopped - ` echo ${i} ${INSTANCE:1} | awk -F/ {'print $NF'} `
					fi
				fi
			done
		fi
	fi
done
