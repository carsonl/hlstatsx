#!/bin/bash

docker ps -a -q \
	| xargs --no-run-if-empty docker rm 2> /dev/null
docker images \
	| grep -v latest \
	| sort -k 3 -r \
	| awk {'print $3" "$1":"$2'} \
	| uniq -d -w 13 -D \
	| awk {'print $2'} \
	| xargs --no-run-if-empty docker rmi 2>/dev/null
docker images -a --filter "dangling=true" \
	| awk {'print $3'} \
	| sort \
	| uniq \
	| xargs --no-run-if-empty docker rmi 2>/dev/null
docker images -a \
	| grep -v latest \
	| awk {'print $3'} \
	| sort \
	| uniq \
	| xargs --no-run-if-empty docker rmi 2>/dev/null
docker images -a \
	| grep '^<none> ' \
	| awk {'print $3'} \
	| sort \
	| uniq \
	| xargs --no-run-if-empty docker rmi 2>/dev/null
docker images -a \
	| grep '^<none> ' \
	| awk {'print $1":"$2'} \
	| sort \
	| uniq \
	| xargs --no-run-if-empty docker rmi 2>/dev/null

#docker images
#echo docker rmi -f "<Insert Image IDs from above>"
