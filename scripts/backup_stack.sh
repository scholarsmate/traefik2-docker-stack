#!/usr/bin/env bash

# Sample backup script

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

set -e

today=$(date +"%Y%m%d")
STACK=${STACK:-devops}
BACKUP_DIR=${BACKUP_DIR:-/mnt/data/backups}
VOLUME_DIR=${VOLUME_DIR:-/var/lib/docker/volumes}

# The backup directory should exist, if not it could be indicative of an NFS
# issue and we don't want to create it because that would be on local filesystem.
if [[ ! -d "${BACKUP_DIR}" ]]; then
  echo "Backup diretory \"${BACKUP_DIR}\" does not exist" >&2
  exit 1
fi

SERVICES="${STACK}_jira ${STACK}_confluence ${STACK}_gitlab ${STACK}_rocketchat ${STACK}_mongo ${STACK}_nexus ${STACK}_prometheus ${STACK}_grafana"
VOLUMES="${STACK}_jira_data ${STACK}_confluence_data ${STACK}_gitlab_config ${STACK}_gitlab_data ${STACK}_gitlab_logs ${STACK}_grafana_data ${STACK}_nexus_data ${STACK}_portainer_data ${STACK}_prometheus_data ${STACK}_rocketchat_uploads ${STACK}_rocketchat_db"

# Stop all active services (aside from databases)
for svc in $SERVICES; do
    docker service scale ${svc}=0
done

sleep 5m

# Backup postgres containers using pg_dump
containers=$(docker ps | grep postgres | awk '{print $1}')
for container in $containers; do
  list=$(docker inspect --format='{{ .Config.Env }}' $container)
  my_array=($(echo $list | tr " " "\n"))
  POSTGRES_DB=""
  POSTGRES_USER=""
  POSTGRES_PASSWORD=""
  for value in "${my_array[@]}"; do
    #echo "$value"
    if [[ "$value" =~ POSTGRES_DB=.* ]]; then
      POSTGRES_DB="$(cut -d'=' -f2 <<<$value)"
      echo "POSTGRES_DB=$POSTGRES_DB"
    fi
    if [[ "$value" =~ POSTGRES_USER=.* ]]; then
      POSTGRES_USER="$(cut -d'=' -f2 <<<$value)"
      echo "POSTGRES_USER=$POSTGRES_USER"
    fi
    if [[ "$value" =~ POSTGRES_PASSWORD=.* ]]; then
      POSTGRES_PASSWORD="$(cut -d'=' -f2 <<<$value)"
      echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"
    fi
  done
  if [[ -n "$POSTGRES_DB" && -n "$POSTGRES_USER" && -n "$POSTGRES_PASSWORD" ]]; then
    docker exec $container /bin/bash -c "PGPASSWORD=$POSTGRES_PASSWORD /usr/bin/pg_dump -U $POSTGRES_USER $POSTGRES_DB" | gzip -9 > "${BACKUP_DIR}/${POSTGRES_DB}_backup.sql.$(date +%Y%m%d).gz"
  else
    echo "[WARN] POSTGRES_PASSWORD, POSTGRES_USER or POSTGRES_DB not populated for container $container." >&2
  fi
done

# Backup all volumes
for vol in ${VOLUMES}; do
    tar -czvf "${VOLUME_DIR}/${vol}" "${BACKUP_DIR}/${vol}-${today}.tar.gz"
    chown vagrant:vagrant "${BACKUP_DIR}/${vol}-${today}.tar.gz"
done

# Restart services
for svc in $SERVICES; do
    docker service scale ${svc}=1
done
