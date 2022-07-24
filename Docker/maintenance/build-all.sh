#!/bin/bash

#Comment out the cron so it doesn't try to start half built containers
sed -i 's|^|#####NOPE |g' /var/scripts/docker/scripts/maintenance/check-all.sh

DELETE="yes"
FILTER=""
TASK=""
KILL="yes"
NOCACHE=""

if [ "${1}" == "" ]; then
	echo Please specify: ${BASH_SOURCE[0]} '<all|not_ubuntu|only_gadjet|filter [filter]> [no_image_cleanup] [no_kill] [no_cache]'
	sed -i 's|^#####NOPE ||g' /var/scripts/docker/scripts/maintenance/check-all.sh
	exit
fi

#Grab all the images, with valid names/tags
while [ "${1}" != "" ]; do
	if [ "${1}" == "all" ]; then
		TASK="${1}"
		shift
		IMAGES=`docker images                       | grep -v ^REPOSITORY | awk {'print $1":"$2'} | grep -v '<none>:<none>'`
	elif [ "${1}" == "not_ubuntu" ]; then
		TASK="${1}"
		shift
		IMAGES=`docker images | grep -v '^ubuntu '  | grep -v ^REPOSITORY | awk {'print $1":"$2'} | grep -v '<none>:<none>'`
	elif [ "${1}" == "only_gadjet" ]; then
		TASK="${1}"
		shift
		IMAGES=`docker images | grep    '^gadjet/'  | grep -v ^REPOSITORY | awk {'print $1":"$2'} | grep -v '<none>:<none>'`
	elif [ "${1}" == "filter" -a "${2}" != "" ]; then
		TASK="${1}"
		FILTER="${2}"
		shift
		shift
		IMAGES=`docker images | grep ${FILTER} | grep -v ^REPOSITORY | awk {'print $1":"$2'}`
	elif [ "${1}" == "no_kill" ]; then
		KILL="no"
		shift
	elif [ "${1}" == "no_image_cleanup" ]; then
		shift
		DELETE="no"
	elif [ "${1}" == "no_cache" ]; then
		shift
		NOCACHE="--no-cache"
	fi
done

if [ "${TASK}" == "" ]; then
	echo Please specify: ${BASH_SOURCE[0]} '<all|not_ubuntu|only_gadjet|filter [filter]> [no_image_cleanup] [no_kill] [no_cache]'
	sed -i 's|^#####NOPE ||g' /var/scripts/docker/scripts/maintenance/check-all.sh
	exit
fi

#Grab all the running and 'all' containers
if [ "${TASK}" == "filter" -a "${FILTER}" != "" ]; then
	NAME=${FILTER}
	RUNCONTAINERS=`docker ps -a -q -f status=running -f name=${NAME}$`
	CONTAINERS=`docker ps -a -q -f name=${NAME}$`
else
	RUNCONTAINERS=`docker ps -a -q -f status=running`
	CONTAINERS=`docker ps -a -q`
fi


if [ "${KILL}" != "no" ]; then
	#Kill all running
	if [ "${RUNCONTAINERS}" != "" ]; then
		echo . > /dev/null
		docker kill ${RUNCONTAINERS}
	fi
	#Remove ALL containers
	if [ "${CONTAINERS}" != "" ]; then
		echo . > /dev/null
		docker rm ${CONTAINERS}
	fi
fi

if [ "${DELETE}" != "no" ]; then
	#Remove all images with valid names/tags
	if [ "${IMAGES}" != "" ]; then
		echo . > /dev/null
		docker rmi ${IMAGES}
	fi
fi

#Grab all the image IDs this time, basically the ones with invalid names/tags
if [ "${TASK}" == "all" ]; then
	IMAGES=`docker images                       | grep -v ^REPOSITORY | awk {'print $3'}`
elif [ "${TASK}" == "not_ubuntu" ]; then
	IMAGES=`docker images | grep -v '^ubuntu '  | grep -v ^REPOSITORY | awk {'print $3'}`
elif [ "${TASK}" == "only_gadjet" ]; then
	IMAGES=`docker images | grep    '^gadjet/'  | grep -v ^REPOSITORY | awk {'print $3'}`
elif [ "${TASK}" == "filter" -a "${FILTER}" != "" ]; then
	IMAGES=`docker images | grep ${FILTER} | grep -v ^REPOSITORY | awk {'print $1":"$2'}`
else
	echo Please specify: ${BASH_SOURCE[0]} '<all|not_ubuntu|only_gadjet|filter [filter]>'
	sed -i 's|^#####NOPE ||g' /var/scripts/docker/scripts/maintenance/check-all.sh
	exit
fi

if [ "${DELETE}" != "no" ]; then
	#Remove all the images with invalid names
	if [ "${IMAGES}" != "" ]; then
		echo . > /dev/null
		docker rmi ${IMAGES}
	fi
fi

#Build all the containers
if [ "${TASK}" == "filter" -a "${FILTER}" != "" ]; then
	PATHSEARCH="/var/scripts/docker/*${FILTER}*"
else
	PATHSEARCH="/var/scripts/docker/*"
fi

#Do these first, so others can use them
ORDEREDPATH=()
ORDEREDPATH+=("/var/scripts/docker/0_proxy_apt-cacher-ng")
ORDEREDPATH+=("/var/scripts/docker/app_openvpn")
ORDEREDPATH+=("/var/scripts/docker/0_proxy_squid")
ORDEREDPATH+=("/var/scripts/docker/app_mariadb")
ORDEREDPATH+=("/var/scripts/docker/app_pgsql")
ORDEREDPATH+=("/var/scripts/docker/app_samba")
for i in "${ORDEREDPATH[@]}"; do
	if [ -d "${i}" ]; then
		if [ ! -f "${i}/disabled_build" -a "${i}" != "/var/scripts/docker/scripts" ]; then
			cd "${i}"
			echo '******************** Starting build of ' ${i} ' ********************'
			./build.sh
			test -e ./disabled || ./run.sh
			test -e ./disabled && echo ' ** Not running, it is disabled ** '
			cd - > /dev/null
			test -e ./disabled || sleep 8
		fi
	fi
done

#These can be done in no particular order
for i in ${PATHSEARCH}; do
	if [ -d "${i}" ]; then
		if [ "${i}" == "/var/scripts/docker/0_proxy_apt-cacher-ng" ]; then continue; fi
		if [ "${i}" == "/var/scripts/docker/app_openvpn" ]; then continue; fi
		if [ "${i}" == "/var/scripts/docker/0_proxy_squid" ]; then continue; fi
		if [ "${i}" == "/var/scripts/docker/app_mariadb" ]; then continue; fi
		if [ "${i}" == "/var/scripts/docker/app_pgsql" ]; then continue; fi
		if [ ! -f "${i}/disabled_build" -a "${i}" != "/var/scripts/docker/scripts" ]; then
			cd "${i}"
			echo '******************** Starting build of ' ${i} ' ********************'
			./build.sh "${NOCACHE}"
			cd - > /dev/null
		fi
	fi
done

#Uncomment the cron, so they all get started automatically if one dies (as usual)
sed -i 's|^#####NOPE ||g' /var/scripts/docker/scripts/maintenance/check-all.sh

if [ "${TASK}" == "filter" -a "${FILTER}" != "" ]; then
	if [ -t 1 ]; then
		flock -n /var/scripts/docker/scripts/maintenance/check-all.sh -c "/var/scripts/docker/scripts/maintenance/check-all.sh filter ${FILTER}"
	else
		flock -n /var/scripts/docker/scripts/maintenance/check-all.sh -c "/var/scripts/docker/scripts/maintenance/check-all.sh filter ${FILTER}" > /dev/null 2>&1
	fi
else
	if [ -t 1 ]; then
		flock -n /var/scripts/docker/scripts/maintenance/check-all.sh -c "/var/scripts/docker/scripts/maintenance/check-all.sh"
	else
		flock -n /var/scripts/docker/scripts/maintenance/check-all.sh -c "/var/scripts/docker/scripts/maintenance/check-all.sh" > /dev/null 2>&1
	fi
fi
