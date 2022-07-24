#!/bin/bash

#if [ ! -t 1 ]; then
#	exit
#fi

if [ "${1}" == "filter" -a "${2}" != "" ]; then
	PATHSEARCH="/var/scripts/docker/*${2}*"
else
	PATHSEARCH="/var/scripts/docker/*"
fi

#Issue stop to unhealthy containers (that are running)
UNHEALTHY_CONTAINERS=$(
	for i in $(docker ps -a -q); do
		docker inspect --format='{{.ID}} {{.Name}} Status:{{.State.Status}} {{json .State.Health}}' $i 2>/dev/null
	done \
		| grep -v \
		-e ' Status:exited ' \
		-e ' Status:paused ' \
		-e ' Status:removing ' \
		-e ' null$' \
		-e '"Status":"healthy"' \
		-e '"Status":"starting"' \
		-e '"Status":"unhealthy","FailingStreak":0' \
		-e 'zNotReal$'
)
echo "${UNHEALTHY_CONTAINERS}" | while read i; do
	if [ "${i}" == "" ]; then
		continue
	fi
	ID="$(echo "${i}" | awk {'print $1'})"
	NAME="$(echo "${i}" | awk {'print $2'} | sed 's|^/||g')"
	STATE="$(echo "${i}" | awk '{$1 = ""; $2 = ""; print $0}')"
	echo 'Container ('"${NAME}"') is unhealthy, killing it: `'"${STATE}"'`'
	docker stop "${ID}" > /dev/null 2>&1
done

#Start up containers that aren't running, but should be
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
				RET=`${i}/check.sh ${INSTANCE:1} `
				if [ ! -f ${i}/disabled_${INSTANCE:1} ]; then
					if [ "${RET}" == "" ]; then
						echo It is not running, starting it - ` echo ${i} ${INSTANCE:1} | awk -F/ {'print $NF'} `
						${i}/run.sh ${INSTANCE:1} | tee /dev/null
						sleep 1
						RET=`${i}/check.sh ${INSTANCE:1} `
						if [ "${RET}" == "" ]; then
							echo It appears this container stopped - ` echo ${i} ${INSTANCE:1} | awk -F/ {'print $NF'} `
						fi
					else
						if [ -t 1 ]; then
							echo It is running - ` echo ${i} ${INSTANCE:1} | awk -F/ {'print $NF'} `
						fi
					fi
				fi
			done
		fi
	fi
done

#Check for functional force vpn process
test -e /var/scripts/force-vpn-containers.sh || exit 0
RUNNING=$(pgrep -f /var/scripts/force-vpn-containers.sh | wc -w)
if [ "${RUNNING}" == "0" ]; then
	systemctl restart force-vpn-containers-daemon.service
fi
