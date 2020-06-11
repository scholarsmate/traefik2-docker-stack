#!/usr/bin/env bash

#
# Sample backup script
#

if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] This script must be run as root" >&2
   exit 1
fi

set -e
mount -a
today=$(date +"%Y%m%d")
STACK=${STACK:-devops}
BACKUP_DIR=${BACKUP_DIR:-/mnt/data/backups}
VOLUME_DIR=${VOLUME_DIR:-/var/lib/docker/volumes}

SERVICES="${STACK}_jira ${STACK}_confluence ${STACK}_gitlab ${STACK}_rocketchat ${STACK}_mongo ${STACK}_nexus ${STACK}_sonar ${STACK}_prometheus ${STACK}_grafana"
VOLUMES="${STACK}_jira_data ${STACK}_confluence_data ${STACK}_gitlab_config ${STACK}_gitlab_data ${STACK}_gitlab_logs ${STACK}_grafana_data ${STACK}_nexus_data ${STACK}_sonarqube_data ${STACK}_sonarqube_bundled-plugins ${STACK}_sonarqube_conf  ${STACK}_sonarqube_extensions ${STACK}_portainer_data ${STACK}_prometheus_data ${STACK}_rocketchat_uploads ${STACK}_rocketchat_db"

# The backup directory should exist, if not it could be indicative of an NFS
# issue and we don't want to create it because that would be on local filesystem.
if [[ ! -d "${BACKUP_DIR}" ]]; then
  echo "[ERROR] Backup directory \"${BACKUP_DIR}\" does not exist" >&2
  exit 1
fi

# Stop all desired active services for volume backups
# (aside from postgres databases which we handle seperately or services that don't require backups, like traefik)
for svc in ${SERVICES}; do
    docker service scale ${svc}=0
done

# Give the services time to shut down
sleep 5m

# Backup postgres containers using pg_dump
containers=$(docker ps | grep postgres | awk '{print $1}')
for container in ${containers}; do
  list=$(docker inspect --format='{{ .Config.Env }}' $container)
  my_array=($(echo $list | tr " " "\n"))
  POSTGRES_DB=""
  POSTGRES_USER=""
  POSTGRES_PASSWORD=""
  for value in "${my_array[@]}"; do
    if [[ "$value" =~ POSTGRES_DB=.* ]]; then
      POSTGRES_DB="$(cut -d'=' -f2 <<<$value)"
      #echo "POSTGRES_DB=$POSTGRES_DB"
    fi
    if [[ "$value" =~ POSTGRES_USER=.* ]]; then
      POSTGRES_USER="$(cut -d'=' -f2 <<<$value)"
      #echo "POSTGRES_USER=$POSTGRES_USER"
    fi
    if [[ "$value" =~ POSTGRES_PASSWORD=.* ]]; then
      POSTGRES_PASSWORD="$(cut -d'=' -f2 <<<$value)"
      #echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"
    fi
  done
  if [[ -n "$POSTGRES_DB" && -n "$POSTGRES_USER" && -n "$POSTGRES_PASSWORD" ]]; then
    docker exec $container /bin/bash -c "PGPASSWORD=${POSTGRES_PASSWORD} pg_dump -U ${POSTGRES_USER} ${POSTGRES_DB}" | gzip -9 > "${BACKUP_DIR}/${POSTGRES_DB}_backup.sql.${today}.gz"
    chown vagrant:vagrant "${BACKUP_DIR}/${POSTGRES_DB}_backup.sql.${today}.gz"
  else
    echo "[WARN] POSTGRES_PASSWORD, POSTGRES_USER or POSTGRES_DB not populated for container $container." >&2
  fi
done

# Backup all desired volumes
for vol in ${VOLUMES}; do
    GZIP=-9 tar -czf "${BACKUP_DIR}/${vol}-${today}.tar.gz" "${VOLUME_DIR}/${vol}"
    chown vagrant:vagrant "${BACKUP_DIR}/${vol}-${today}.tar.gz"
done

# Restart services that were stopped
for svc in ${SERVICES}; do
    docker service scale ${svc}=1
done
