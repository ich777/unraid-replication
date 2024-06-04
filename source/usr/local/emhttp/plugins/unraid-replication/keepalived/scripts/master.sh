#!/bin/bash
# Get variables from config
CONFIG="$(cat /boot/config/plugins/unraid-replication/settings.cfg)"
INSTANCE_TYPE="$(echo "${CONFIG}" | grep 'INSTANCE_TYPE' | cut -d '=' -f2 | sed 's/\"//g')"
DOCKER_REPLICATION="$(echo "${CONFIG}" | grep 'DOCKER_REPLICATION' | cut -d '=' -f2 | sed 's/\"//g')"
LXC_REPLICATION="$(echo "${CONFIG}" | grep 'LXC_REPLICATION' | cut -d '=' -f2 | sed 's/\"//g')"
VM_REPLICATION="$(echo "${CONFIG}" | grep 'VM_REPLICATION' | cut -d '=' -f2 | sed 's/\"//g')"

# Send messages depending on instance type
if [ "${INSTANCE_TYPE}" == "host" ]; then
  /usr/local/emhttp/plugins/dynamix/scripts/notify -e "keepalived" -d "Registering as Master Server!" -l "/Settings/unraid-replication"
elif [ "${INSTANCE_TYPE}" == "client" ]; then
  /usr/local/emhttp/plugins/dynamix/scripts/notify -e "keepalived" -d "Master Server not reachable! Registering as Master Server!" -i "alert" -l "/Settings/unraid-replication"
  if [ "${DOCKER_REPLICATION}" == "enabled" ]; then
    # Get variables and start container which have autostart enabled
    DOCKER_REPLICATION_JSON="$(cat /boot/config/plugins/unraid-replication/replication_cfg/docker.json | jq -r '.[]')"
    CONTAINERS="$(echo "$DOCKER_REPLICATION_JSON" | jq -r '.NAME')"
    if [[ -z "${CONTAINERS}" || "${CONTAINERS}" == "null" ]]; then
      return
    fi
    IFS=$'\n'
    for container in ${CONTAINERS}; do
      if [ "$(echo ${DOCKER_REPLICATION_JSON} | jq -r --arg name "${container}" 'select(.NAME == $name) | .AUTOSTART')" == "on" ]; then
        docker container start ${container}
      fi
    done
  fi
  if [ "${LXC_REPLICATION}" == "enabled" ]; then
    # Get variables and start container which have autostart enabled
    LXC_REPLICATION_JSON="$(cat /boot/config/plugins/unraid-replication/replication_cfg/lxc.json | jq -r '.[]')"
    CONTAINERS="$(echo "${LXC_REPLICATION_JSON}" | jq -r '.NAME')"
    if [ -z "${CONTAINERS}" ]; then
      return
    fi
    IFS=$'\n'
    for container in ${CONTAINERS}; do
      if [ "$(echo ${LXC_REPLICATION_JSON} | jq -r --arg name "${container}" 'select(.NAME == $name) | .AUTOSTART')" == "on" ] ; then
        lxc-start ${container}
      fi
    done
  fi
  if [ "${VM_REPLICATION}" == "enabled" ]; then
    echo "TBD"
  fi
fi
