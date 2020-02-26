#!/usr/bin/env bash

echo '##########################################################################'
echo '#               About to run teardown.sh script                          #'
echo '##########################################################################'

set -ex

docker stack rm devops
docker network rm traefik-proxy >/dev/null 2>&1 || true
