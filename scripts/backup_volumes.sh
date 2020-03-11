#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root / sudo" >&2
   exit 1
fi

set -e

today=$(date +"%Y%m%d")
SVC_DOMAIN=${SVC_DOMAIN:-domain.com}
BACKUP_DIR=${BACKUP_DIR:-/mnt/backups/}
VOLUME_DIR=${VOLUME_DIR:-/var/lib/docker/volumes/}

# Make the backup directory
mkdir -p "${BACKUP_DIR}"
chown vagrant:vagrant "${BACKUP_DIR}"

echo "Backing up GitLab..."
if [[  $(docker service ls | grep -c devops_gitlab) > 0 ]]; then
  docker service rm devops_gitlab
fi
sleep 5m
if [[ -d "${VOLUME_DIR}"devops_gitlab_config/ ]]; then
  tar -czvf "${BACKUP_DIR}devops_gitlab_config${today}.tar.gz" "${VOLUME_DIR}devops_gitlab_config/"
  chown vagrant:vagrant "${BACKUP_DIR}devops_gitlab_config${today}.tar.gz"
fi
if [[ -d "${VOLUME_DIR}"devops_gitlab_data/ ]]; then
  tar -czvf "${BACKUP_DIR}devops_gitlab_data${today}.tar.gz" "${VOLUME_DIR}devops_gitlab_data/"
  chown vagrant:vagrant "${BACKUP_DIR}devops_gitlab_data${today}.tar.gz"
fi
if [[ -d "${VOLUME_DIR}"devops_gitlab_logs/ ]]; then
  tar -czvf "${BACKUP_DIR}devops_gitlab_logs${today}.tar.gz" "${VOLUME_DIR}devops_gitlab_logs/"
  chown vagrant:vagrant "${BACKUP_DIR}devops_gitlab_logs${today}.tar.gz"
fi
  SVC_DOMAIN="${SVC_DOMAIN}" docker stack deploy -c /vagrant/svcrepo/gitlab/docker-compose.yml devops

echo "Backing up Jira and Confluence..."
if [[  $(docker service ls | grep -c devops_jira) > 0 ]]; then
  docker service rm devops_jira
fi
if [[  $(docker service ls | grep -c devops_confluence) > 0 ]]; then
  docker service rm devops_confluence
fi
sleep 5m
if [[ -d "${VOLUME_DIR}"devops_jira_data/ ]]; then
  tar -czvf "${BACKUP_DIR}devops_jira_data${today}.tar.gz" "${VOLUME_DIR}devops_jira_data/"
  chown vagrant:vagrant "${BACKUP_DIR}devops_jira_data${today}.tar.gz"
fi
if [[ -d "${VOLUME_DIR}"devops_confluence_data/ ]]; then
  tar -czvf "${BACKUP_DIR}devops_confluence_data${today}.tar.gz" "${VOLUME_DIR}devops_confluence_data/"
  chown vagrant:vagrant "${BACKUP_DIR}devops_confluence_data${today}.tar.gz"
fi
SVC_DOMAIN="${SVC_DOMAIN}" docker stack deploy -c /vagrant/svcrepo/atlassian/docker-compose.yml devops

echo "Backing up RocketChat..."
if [[  $(docker service ls | grep -c devops_rocketchat) > 0 ]]; then
  docker service rm devops_rocketchat
fi
sleep 5m
if [[ -d "${VOLUME_DIR}"devops_jira_rocketchat_uploads/ ]]; then
  tar -czvf "${BACKUP_DIR}devops_rocketchat_uploads${today}.tar.gz" "${VOLUME_DIR}devops_rocketchat_uploads/"
  chown vagrant:vagrant "${BACKUP_DIR}devops_rocketchat_uploads${today}.tar.gz"
fi
if [[ -d "${VOLUME_DIR}"devops_rocketchat_db/ ]]; then
  tar -czvf "${BACKUP_DIR}devops_rocketchat_db${today}.tar.gz" "${VOLUME_DIR}devops_rocketchat_db/"
  chown vagrant:vagrant "${BACKUP_DIR}devops_rocketchat_db${today}.tar.gz"
fi
SVC_DOMAIN="${SVC_DOMAIN}" docker stack deploy -c /vagrant/svcrepo/rocketchat/docker-compose.yml devops

echo "Backing up Nexus..."
if [[  $(docker service ls | grep -c devops_nexus) > 0 ]]; then
  docker service rm devops_nexus
fi
sleep 5m
if [[ -d "${VOLUME_DIR}"devops_jira_nexus_data/ ]]; then
  tar -czvf "${BACKUP_DIR}devops_nexus_data${today}.tar.gz" "${VOLUME_DIR}devops_nexus_data/"
  chown vagrant:vagrant "${BACKUP_DIR}devops_nexus_data${today}.tar.gz"
fi
SVC_DOMAIN="${SVC_DOMAIN}" docker stack deploy -c /vagrant/svcrepo/nexus/docker-compose.yml devops

echo "Backing up promethus and grafana..."
if [[  $(docker service ls | grep -c devops_prometheus) > 0 ]]; then
  docker service rm devops_prometheus
fi
if [[  $(docker service ls | grep -c devops_grafana) > 0 ]]; then
  docker service rm devops_grafana
fi
sleep 5m
if [[ -d "${VOLUME_DIR}"devops_jira_prometheus_data/ ]]; then
  tar -czvf "${BACKUP_DIR}devops_prometheus_data${today}.tar.gz" "${VOLUME_DIR}devops_prometheus_data/"
  chown vagrant:vagrant "${BACKUP_DIR}devops_prometheus_data${today}.tar.gz"
fi
if [[ -d "${VOLUME_DIR}"devops_jira_grafana_data/ ]]; then
  tar -czvf "${BACKUP_DIR}devops_grafana_data${today}.tar.gz" "${VOLUME_DIR}devops_grafana_data/"
  chown vagrant:vagrant "${BACKUP_DIR}devops_grafana_data${today}.tar.gz"
fi
SVC_DOMAIN="${SVC_DOMAIN}" docker stack deploy -c /vagrant/svcrepo/metrics/docker-compose.yml devops

echo "Backups complete."
