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
#Do this for all
grep -r 'deb .*https:' "${DIRNAME}" -l | grep -v ' ' | xargs -I___ sed -i -E 's|^deb( .*)? https://|deb\1 http://HTTPS///|g' ___
#Iterate for each 'instance'
INSTANCECOUNT=0
for i in ${DIRNAME}/print-instance-args_*.sh ; do
	INSTANCE=`basename $i `   #Just the file
	INSTANCE=${INSTANCE:20}   #Remove the first 20 chars (print-instance-args_)
	INSTANCE="_"${INSTANCE:0:-3} #Remove the last  3 chars (.sh)
	if [ "${1}" == "main" ]; then
		set -- "" "${@:2}"
	fi
	if [ "${INSTANCE:1}" == "main" ]; then
		INSTANCE=""
	fi
	if [ "${INSTANCE:1}" == "*" ]; then
		break;
	else
		INSTANCECOUNT=` expr ${INSTANCECOUNT} + 1 `
	fi
	if [ "${1}" == "${INSTANCE:1}" -o "${1}" == "" ]; then
		if [ "${MATCHED}" == "1" ]; then
			break
		fi
		if [ "${1}" == "${INSTANCE:1}" ]; then
			MATCHED=1
		fi
		#Do this for each of them (or the match)
		#echo Name: ${NAME}, DirName: ${DIRNAME}, Instance: ${INSTANCE:1}, Counter: ${INSTANCECOUNT}.
		if [ ! -d /u01/Docker/${NAME}${INSTANCE}/ ]; then
			echo Build-Nothing > /dev/null
		fi
	fi
done
if [ "${INSTANCECOUNT}" == "0" ]; then
	echo $0: No instances found, nothing was done. >&2
fi
