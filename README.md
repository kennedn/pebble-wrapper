# Pebble-Wrapper

### The Problem

The Pebble SDK has a pretty bad case of [code rot](https://en.wikipedia.org/wiki/Software_rot) nowadays. The world has moved on from reliance on Nodejs 10.x and Python2.7 but the pebble SDK has not. This is quickly becoming a blocker for would be app developers trying to install the SDK on their modern systems.

### The Solution

The pebble-wrapper side steps this issue by loosely wrapping `pebble` commands in a container runtime. A pre-made image that contains the SDK is spun up per project and commands are passed to the container runtime instead of being ran locally on the machine.

## Pre-requisites  

- Container runtime (docker/podman)
- jq (`sudo apt install jq`)

### Example pre-requisites setup on Ubuntu 22.04

```shell
sudo apt update
sudo apt install podman jq
```

## Installation

Download the contents of [tools/pebble-wrapper.sh](https://raw.githubusercontent.com/kennedn/pebble-wrapper/master/tools/pebble-wrapper.sh) from this repository:
```shell
curl -fsS https://raw.githubusercontent.com/kennedn/pebble-wrapper/master/tools/pebble-wrapper.sh > pebble-wrapper.sh
```

If you are using docker, you will need to re-configure the `CONTAINER_RUNTIME` and `EXTRA_RUN_ARGS` variables in the script, change:
```shell
# Set up args for podman or docker  depending on the container runtime installed
CONTAINER_RUNTIME="podman"
EXTRA_RUN_ARGS="--userns=keep-id"

#CONTAINER_RUNTIME="docker"
#EXTRA_RUN_ARGS=""
```
to:
```shell
# Set up args for podman or docker  depending on the container runtime installed
#CONTAINER_RUNTIME="podman"
#EXTRA_RUN_ARGS="--userns=keep-id"

CONTAINER_RUNTIME="docker"
EXTRA_RUN_ARGS=""
```

Set execute permissions on the script:
```shell
chmod 755 pebble-wrapper.sh
```

Configure the `pebble` alias for the script:
```shell
alias pebble="$(pwd)/pebble-wrapper.sh"
```

`cd` to your project folder:
```shell
cd some-project
```

Invoke the script 
```shell
pebble -h
```
NOTE: The first run will take a while as it needs to download the container image

## Behaviour

For each folder in which the pebble-wrapper script is invoked, a container will be spun up. Therefor, it is important to `cd` to the desired pebble project folder before invoking the script.

If a container is already running for the current folder, pebble commands will simply be passed to this container.

To clean-down pebble containers after you are finished developing:
`pebble clean-containers`

Besides this, with the alias set, the wrapper behaves exactly like the pebble tool. Please refer to the official [pebble-tool](https://developer.rebble.io/developer.pebble.com/guides/tools-and-resources/pebble-tool/index.html) documentation for usage outside of the wrapper functions.


## Known Issues

### Problem
`pebble install` does not work

To be able to return the prompt to the user, `pebble install` spins up a detached `qemu-pebble` process. This does not play nice with the `docker exec` command being run under the hood.

### Solution
Invoke `pebble install` with the `--logs` command line argument to make it stick around after spinning up `qemu-pebble`
