#!/bin/bash

IMAGE=mk-builder
NAME=mk-builder

# Check for existing containers
EXISTING="$(docker ps -aq --filter=name=${NAME})"
if test -n "${EXISTING}"; then
    # Container exists; is it running?
    RUNNING=$(docker inspect ${EXISTING} | awk '/"Running":/ { print $2 }')
    if test "${RUNNING}" = "false,"; then
	# Remove stopped container
	echo docker rm ${EXISTING}
    elif test "${RUNNING}" = "true,"; then
	# Container already running; error
	echo "Error:  container '${NAME}' already running" >&2
	exit 1
    else
	# Something went wrong
	echo "Error:  unable to determine status of " \
	    "existing container '${EXISTING}'" >&2
	exit 1
    fi
fi

docker run --rm \
    -it --privileged \
    -u `id -u`:`id -g` \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v /dev/dri:/dev/dri \
    -v $HOME:$HOME \
    -v $PWD:$PWD \
    -w $PWD \
    -e DISPLAY \
    -h ${NAME} --name ${NAME} \
    ${IMAGE} "$@"
