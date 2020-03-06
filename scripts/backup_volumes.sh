#!/usr/bin/env bash

set -e

SVC_DOMAIN=${SVC_DOMAIN:-domain.com}
today=$(date +"%Y%m%d")

echo "Backing up GitLab..."
docker service rm devops_gitlab
sudo tar -czvf ${today}-devops_gitlab_config.tar.gz /var/lib/docker/volumes/devops_gitlab_config/
sudo tar -czvf ${today}-devops_gitlab_data.tar.gz /var/lib/docker/volumes/devops_gitlab_data/
sudo tar -czvf ${today}-devops_gitlab_logs.tar.gz /var/lib/docker/volumes/devops_gitlab_logs/
SVC_DOMAIN=${SVC_DOMAIN} docker stack deploy -c /vagrant/svcrepo/gitlab/docker-compose.yml devops

echo "Backing up Jira and Confluence..."
docker service rm devops_jira
docker service rm devops_confluence
sudo tar -czvf ${today}-devops_jira_data.tar.gz /var/lib/docker/volumes/devops_jira_data/
sudo tar -czvf ${today}-devops_confluence_data.tar.gz /var/lib/docker/volumes/devops_confluence_data/
SVC_DOMAIN=${SVC_DOMAIN} docker stack deploy -c /vagrant/svcrepo/atlassian/docker-compose.yml devops

echo "Backing up RocketChat..."
docker service rm devops_rocketchat
sudo tar -czvf ${today}-devops_rocketchat_uploads.tar.gz /var/lib/docker/volumes/devops_rocketchat_uploads/
sudo tar -czvf ${today}-devops_rocketchat_db.tar.gz /var/lib/docker/volumes/devops_rocketchat_db/
SVC_DOMAIN=${SVC_DOMAIN} docker stack deploy -c /vagrant/svcrepo/rocketchat/docker-compose.yml devops

echo "Backing up Nexus..."
docker service rm devops_nexus
sudo tar -czvf ${today}-devops_nexus_data.tar.gz /var/lib/docker/volumes/devops_nexus_data/
SVC_DOMAIN=${SVC_DOMAIN} docker stack deploy -c /vagrant/svcrepo/nexus/docker-compose.yml devops

echo "Backing up Prometheus and Grafana..."
docker service rm devops_prometheus
docker service rm devops_grafana
sudo tar -czvf ${today}-devops_prometheus_data.tar.gz /var/lib/docker/volumes/devops_prometheus_data/
sudo tar -czvf ${today}-devops_grafana_data.tar.gz /var/lib/docker/volumes/devops_grafana_data/
SVC_DOMAIN=${SVC_DOMAIN} docker stack deploy -c /vagrant/svcrepo/metrics/docker-compose.yml devops

echo "Backups complete."
