#!/usr/bin/env bash

set -e

today=$(date +"%Y%m%d")
SVC_DOMAIN=${SVC_DOMAIN:-domain.com}
BACKUP_DIR=${BACKUP_DIR:-/mnt/backups/}

# Make the backup directory
sudo mkdir -p "${BACKUP_DIR}"
sudo chown vagrant:vagrant "${BACKUP_DIR}"

echo "Backing up GitLab..."
if [[  $(docker service ls | grep -c devops_gitlab) > 0 ]]; then
  docker service rm devops_gitlab
fi
sleep 5m
if [[ -d /var/lib/docker/volumes/devops_gitlab_config/ ]]; then
  sudo tar -czvf "${BACKUP_DIR}devops_gitlab_config${today}.tar.gz" /var/lib/docker/volumes/devops_gitlab_config/
  sudo chown vagrant:vagrant "${BACKUP_DIR}devops_gitlab_config${today}.tar.gz"
fi
if [[ -d /var/lib/docker/volumes/devops_gitlab_data/ ]]; then
  sudo tar -czvf "${BACKUP_DIR}devops_gitlab_data${today}.tar.gz" /var/lib/docker/volumes/devops_gitlab_data/
  sudo chown vagrant:vagrant "${BACKUP_DIR}devops_gitlab_data${today}.tar.gz"
fi
if [[ -d /var/lib/docker/volumes/devops_gitlab_logs/ ]]; then
  sudo tar -czvf "${BACKUP_DIR}devops_gitlab_logs${today}.tar.gz" /var/lib/docker/volumes/devops_gitlab_logs/
  sudo chown vagrant:vagrant "${BACKUP_DIR}devops_gitlab_logs${today}.tar.gz"
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
if [[ -d /var/lib/docker/volumes/devops_jira_data/ ]]; then
  sudo tar -czvf "${BACKUP_DIR}devops_jira_data${today}.tar.gz" /var/lib/docker/volumes/devops_jira_data/
  sudo chown vagrant:vagrant "${BACKUP_DIR}devops_jira_data${today}.tar.gz"
fi
if [[ -d /var/lib/docker/volumes/devops_confluence_data/ ]]; then
  sudo tar -czvf "${BACKUP_DIR}devops_confluence_data${today}.tar.gz" /var/lib/docker/volumes/devops_confluence_data/
  sudo chown vagrant:vagrant "${BACKUP_DIR}devops_confluence_data${today}.tar.gz"
fi
SVC_DOMAIN="${SVC_DOMAIN}" docker stack deploy -c /vagrant/svcrepo/atlassian/docker-compose.yml devops

echo "Backing up RocketChat..."
if [[  $(docker service ls | grep -c devops_rocketchat) > 0 ]]; then
  docker service rm devops_rocketchat
fi
sleep 5m
if [[ -d /var/lib/docker/volumes/devops_jira_rocketchat_uploads/ ]]; then
  sudo tar -czvf "${BACKUP_DIR}devops_rocketchat_uploads${today}.tar.gz" /var/lib/docker/volumes/devops_rocketchat_uploads/
  sudo chown vagrant:vagrant "${BACKUP_DIR}devops_rocketchat_uploads${today}.tar.gz"
fi
if [[ -d /var/lib/docker/volumes/devops_rocketchat_db/ ]]; then
  sudo tar -czvf "${BACKUP_DIR}devops_rocketchat_db${today}.tar.gz" /var/lib/docker/volumes/devops_rocketchat_db/
  sudo chown vagrant:vagrant "${BACKUP_DIR}devops_rocketchat_db${today}.tar.gz"
fi
SVC_DOMAIN="${SVC_DOMAIN}" docker stack deploy -c /vagrant/svcrepo/rocketchat/docker-compose.yml devops

echo "Backing up Nexus..."
if [[  $(docker service ls | grep -c devops_nexus) > 0 ]]; then
  docker service rm devops_nexus
fi
sleep 5m
if [[ -d /var/lib/docker/volumes/devops_jira_nexus_data/ ]]; then
  sudo tar -czvf "${BACKUP_DIR}devops_nexus_data${today}.tar.gz" /var/lib/docker/volumes/devops_nexus_data/
  sudo chown vagrant:vagrant "${BACKUP_DIR}devops_nexus_data${today}.tar.gz"
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
if [[ -d /var/lib/docker/volumes/devops_jira_prometheus_data/ ]]; then
  sudo tar -czvf "${BACKUP_DIR}devops_prometheus_data${today}.tar.gz" /var/lib/docker/volumes/devops_prometheus_data/
  sudo chown vagrant:vagrant "${BACKUP_DIR}devops_prometheus_data${today}.tar.gz"
fi
if [[ -d /var/lib/docker/volumes/devops_jira_grafana_data/ ]]; then
  sudo tar -czvf "${BACKUP_DIR}devops_grafana_data${today}.tar.gz" /var/lib/docker/volumes/devops_grafana_data/
  sudo chown vagrant:vagrant "${BACKUP_DIR}devops_grafana_data${today}.tar.gz"
fi
SVC_DOMAIN="${SVC_DOMAIN}" docker stack deploy -c /vagrant/svcrepo/metrics/docker-compose.yml devops

echo "Backups complete."
