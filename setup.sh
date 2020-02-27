#!/usr/bin/env bash

SVC_DOMAIN=${SVC_DOMAIN:-domain.com}

echo '##########################################################################'
echo '#               About to run setup.sh script                             #'
echo '##########################################################################'
echo "SVC_DOMAIN=${SVC_DOMAIN}"

set -ex

docker pull moncho/dry

docker network create --driver overlay traefik-proxy >/dev/null 2>&1 || true
for app in traefik2 metrics portainer dbadmin atlassian gitlab nexus rocketchat; do
   SVC_DOMAIN="${SVC_DOMAIN}" docker stack deploy --compose-file $app/docker-compose.yml devops
done
