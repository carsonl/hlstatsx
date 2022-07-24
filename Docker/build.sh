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

cd /var/scripts/docker/${NAME}

if [ -f disabled ]; then
	touch already-disabled
else
	touch disabled
fi

if [ -f $(dirname ${BASH_SOURCE[0]})/build-extra.sh ]; then
	$(dirname ${BASH_SOURCE[0]})/build-extra.sh ${1}
fi

if [ "${1}" == "--no-cache" ]; then
	NOCACHE="--no-cache"
else
	NOCACHE=""
fi

if [ -f Dockerfile ]; then
	docker build $NOCACHE -t gadjet/${NAME}:latest -t gadjet/${NAME}:`date +%s` .
fi

if [ -f already-disabled ]; then
	rm already-disabled
else
	rm disabled
fi

cd - > /dev/null
