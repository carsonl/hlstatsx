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
	INSTANCE=` basename $i `   #Just the file
	INSTANCE=${INSTANCE:20}   #Remove the first 20 chars (print-instance-args_)
	INSTANCE="_"${INSTANCE:0:-3} #Remove the last  3 chars (.sh)
	if [ "${INSTANCE:1}" == "*" ]; then
		break;
	else
		INSTANCECOUNT=` expr ${INSTANCECOUNT} + 1 `
	fi
	if [ "${1}" == "main" ]; then
		set -- "" "${@:2}"
	fi
	if [ "${INSTANCE:1}" == "main" ]; then
		INSTANCE=""
		if [ "${2}" == "debug" -a "${1}" == "main" ]; then
			set -- "" "${@:2}"
		fi
	fi
	if [ "${1}" == "${INSTANCE:1}" -o "${1}" == "" -o "${1}" == "debug" ]; then
		if [ "${1}" == "debug" ]; then
			echo ERR: $0: You need to specify an instance name >&2
			break
		fi
		if [ "${MATCHED}" == "1" ]; then
			break
		fi
		if [ "${1}" == "${INSTANCE:1}" ]; then
			MATCHED=1
			shift;
		fi
		#Do this for each of them (or the match)
		#echo Name: ${NAME}, DirName: ${DIRNAME}, Instance: ${INSTANCE:1}, Counter: ${INSTANCECOUNT}.
		if [ "${1}" == "debug" ]; then
			MATCHED=1
			shift;
			if [ -t 1 ]; then
				TYPE="-i -t"
			else
				TYPE="-i"
			fi
			if [ "${*}" == "" ]; then
				set "bash"
			fi
			HIDEID=""
		else
			TYPE="-d"
			HIDEID=" | grep -E -v '^[0-9a-f]{64}$' "
			POTEXTRA=`tail -1 ${DIRNAME}/print-instance-args${INSTANCE:-"_main"}.sh | grep '^#EXTRA Run: ' | sed 's/^#EXTRA Run: //g'`
			if [ "${POTEXTRA}" != "" ]; then
				if [ "${POTEXTRA:0:4}" == "-it " ]; then
					POTEXTRA="${POTEXTRA:4}"
					if [ -t 1 ]; then
						TYPE="-i -t"
						HIDEID=""
					else
						TYPE="-t"
					fi
				elif [ "${POTEXTRA}" == "-i" ]; then
					POTEXTRA=""
					TYPE="-i"
				elif [ "${POTEXTRA}" == "-it" ]; then
					POTEXTRA=""
					if [ -t 1 ]; then
						TYPE="-i -t"
						HIDEID=""
					else
						TYPE="-t"
					fi
				fi
			fi
		fi

		DCID=`docker ps -q -a -f name="^/${NAME}${INSTANCE}[0-9]*$" -f status=running`
		if [ "${DCID}" != "" ]; then
			docker stop ${DCID}
		fi
		DCID=`docker ps -q -a -f name="^/${NAME}${INSTANCE}[0-9]*$" -f status=running`
		if [ "${DCID}" != "" ]; then
			docker kill ${DCID}
		fi
		DCID=`docker ps -q -a -f name="^/${NAME}${INSTANCE}[0-9]*$" -f status=exited`
		if [ "${DCID}" != "" ]; then
			if [ -t 1 ]; then
				docker rm -v ${DCID}
			else
				docker rm -v ${DCID} > /dev/null
			fi
		fi
		DCID=`docker ps -q -a -f name="^/${NAME}${INSTANCE}[0-9]*$" -f status=created`
		if [ "${DCID}" != "" ]; then
			if [ -t 1 ]; then
				docker rm -v ${DCID}
			else
				docker rm -v ${DCID} > /dev/null
			fi
		fi
		c="" #Set it to nothing, in case we do not allow multiple containers
		#Do we allow multiple containers, if so, find the next available number
		ALLOWMANY=$(grep '##AllowMultiple' ${DIRNAME}/print-instance-args${INSTANCE:-"_main"}.sh)
		if [ "${ALLOWMANY}" != "" ]; then
			#Check if there the main instance is running, and get ready to count
			MAYBEMORE=$(docker ps -a --format='{{.Names}}' --filter "name=^${NAME}${INSTANCE}$")
			if [ "${MAYBEMORE}" == "${NAME}${INSTANCE}" ]; then
				#Start counting and find the next available slot... in normal use, there would potentially only be one other running
				i=0
				while true; do
					((c=c+1))
					MAYBENEXT=$(docker ps -a --format='{{.Names}}' --filter "name=^${NAME}${INSTANCE}${c}$")
					if [ "${MAYBENEXT}" == "" ]; then
						break
					fi
					if [ "${c}" == "10" ]; then #10 should be enough, right?
						echo '--invalid_paramter_to_make_docker_warn_me'
						c=""
						break
					fi
				done
			fi
		fi
		DCID=`docker ps -q -a -f name=^/${NAME}${INSTANCE}$`
		if [ "${ALLOWMANY}" == "" ] && [ "${DCID}" != "" ]; then
			echo WARN ${0}: ${NAME}${INSTANCE} is already running, nothing was 'done'. >&2
		else
			#Replace spaces in quoted strings with escaped spaces
			RUNARGS=$( ${DIRNAME}/print-instance-args${INSTANCE:-"_main"}.sh ${INSTANCE:1} )
			RETVAL=$?
			if [ "${RETVAL}" != "0" ]; then
				echo "${0}: An error occurred processing \"${DIRNAME}/print-instance-args${INSTANCE:-"_main"}.sh\" ($RETVAL), bailing." >&2
				exit 60
			fi
			if [ "${*}" != "" ]; then
				CMDARGS=$( printf "%q " "${@}" )
			fi
			if [[ "${RUNARGS}" =~ "/mnt/mounts/" ]]; then
				mountpoint -q /mnt/mounts/
				RETVAL=$?
				if [ "${RETVAL}" != "0" ]; then
					echo ${0}: Supplementary filesystem not mounted, bailing. >&2
					exit 55
				fi
			fi
			eval $( echo docker run \
					--name "${NAME}${INSTANCE}${c}" \
					${TYPE} \
					\
					${RUNARGS} \
					\
					gadjet/${NAME}:latest \
					${POTEXTRA} \
					${CMDARGS} \
					${HIDEID}
			)
			if [ -t 1 ]; then
				docker ps -a -f name=^/${NAME}${INSTANCE}${c}$
			fi
			POST_DEBUG_CMD=$( grep '##PostDebugCMD' ${DIRNAME}/print-instance-args${INSTANCE:-"_main"}.sh | sed 's/^##PostDebugCMD: //g' )
			if [ "${POST_DEBUG_CMD}" != "" ]; then
				docker exec -d "${NAME}${INSTANCE}${c}" ${POST_DEBUG_CMD}
			fi
		fi
	fi
done
if [ "${INSTANCECOUNT}" == "0" ]; then
	echo ${0}: No instances found, nothing was 'done'. >&2
fi
