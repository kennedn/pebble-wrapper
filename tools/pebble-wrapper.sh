#!/bin/bash

# Set up args for podman or docker  depending on the container runtime installed
CONTAINER_RUNTIME="podman"
EXTRA_RUN_ARGS="--userns=keep-id"

#CONTAINER_RUNTIME="docker"
#EXTRA_RUN_ARGS=""

IMAGE='docker.io/kennedn/pebble-wrapper:latest'


# If clean-containers passed, set a flag that will run a `"${CONTAINER_RUNTIME}" rm` once image_ids is obtained
CLEAN=
[ "$1" == "clean-containers" ] && CLEAN=1

# Obtain list of running containers with the pebble base image
image_ids=$("${CONTAINER_RUNTIME}" ps --filter "ancestor=${IMAGE}" --format '{{.ID}}')

image_id=
# If list is not empty, check if any have the current directory mounted
if [ -n "${image_ids}" ]; then
  image_id=$("${CONTAINER_RUNTIME}" inspect ${image_ids} | jq -r --arg pwd "$(pwd)" '[.[] | select (.Mounts[].Destination == "/pebble" and .Mounts[].Source == $pwd)][0].Id | select (. != null)')
  [ -n "${CLEAN}" ] && "${CONTAINER_RUNTIME}" kill ${image_ids}
fi

[ -n "${CLEAN}" ] && exit 0

# If no running containers have the current directory mounted, create one
if [ -z "${image_id}" ]; then
  image_id=$("${CONTAINER_RUNTIME}" run ${EXTRA_RUN_ARGS} -d -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.x11-unix  -v ~/.Xauthority:/home/pebble/.Xauthority --entrypoint /bin/bash --net=host --entrypoint="sleep" -v .:/pebble ${IMAGE} infinity)
fi
# Pass all args to the pebble tool in the container that has the current directory mounted
"${CONTAINER_RUNTIME}" exec -it -w="/pebble" ${image_id} pebble $@
