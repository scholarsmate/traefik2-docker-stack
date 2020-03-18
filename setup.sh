#!/usr/bin/env bash

SVC_DOMAIN=${SVC_DOMAIN:-domain.com}
BACKUP_SCRIPT=${BACKUP_SCRIPT:-/vagrant/svcrepo/scripts/backup_stack.sh}

echo '##########################################################################'
echo '#               About to run setup.sh script                             #'
echo '##########################################################################'
echo "SVC_DOMAIN=${SVC_DOMAIN}"

set -ex

# Install dry docker manager for the terminal
docker pull moncho/dry
mkdir -p ~/bin/
cat << __EOF__ | tee ~/bin/dry
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock moncho/dry
__EOF__
chmod +x ~/bin/dry

# Setup backups to run at 2AM each day (sudo is needed to read the docker volumes)
if [[ -x "${BACKUP_SCRIPT}" ]]; then
   echo "0 2 * * * sudo ${BACKUP_SCRIPT}" | tee -a /var/spool/cron/vagrant
fi

# Deploy the stack
docker network create --driver overlay traefik-proxy >/dev/null 2>&1 || true
for app in traefik2 metrics portainer dbadmin backup atlassian gitlab nexus rocketchat; do
   SVC_DOMAIN="${SVC_DOMAIN}" docker stack deploy --compose-file $app/docker-compose.yml devops
done
