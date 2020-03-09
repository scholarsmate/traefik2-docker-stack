#!/usr/bin/env bash

# Find the possible containers
containers=$(docker ps | grep postgres | awk '{print $1}')
for container in $containers; do
  echo "Found container " $container
  list=$(docker inspect --format='{{ .Config.Env }}' $container)
  echo "$list"
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
    docker exec $container /bin/bash -c "PGPASSWORD=$POSTGRES_PASSWORD /usr/bin/pg_dump -U $POSTGRES_USER $POSTGRES_DB" | gzip -9 > "$POSTGRES_DB"_backup.sql.$(date +%Y%m%d).gz
  else
    echo "[WARN] POSTGRES_PASSWORD, POSTGRES_USER or POSTGRES_DB not populated for container $container." >&2
  fi
done
