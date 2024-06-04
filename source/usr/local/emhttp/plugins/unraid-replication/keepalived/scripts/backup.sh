#!/bin/bash
# Get variables from config
CONFIG="$(cat /boot/config/plugins/unraid-replication/settings.cfg)"
INSTANCE_TYPE="$(echo "${CONFIG}" | grep 'INSTANCE_TYPE' | cut -d '=' -f2 | sed 's/\"//g')"
TMP_PATH="$(echo "${CONFIG}" | grep 'TMP_PATH' | cut -d '=' -f2 | sed 's/\"//g')"
DOCKER_REPLICATION="$(echo "${CONFIG}" | grep 'DOCKER_REPLICATION' | cut -d '=' -f2 | sed 's/\"//g')"
LXC_REPLICATION="$(echo "${CONFIG}" | grep 'LXC_REPLICATION' | cut -d '=' -f2 | sed 's/\"//g')"
VM_REPLICATION="$(echo "${CONFIG}" | grep 'VM_REPLICATION' | cut -d '=' -f2 | sed 's/\"//g')"

# Set default temporary path if none is set
if [ -z "${TMP_PATH}" ]; then
  TMP_PATH="/tmp/unraid-replication"
fi

# Send messages depending on instance type
if [ "${INSTANCE_TYPE}" == "client" ]; then
  /usr/local/emhttp/plugins/dynamix/scripts/notify -e "keepalived" -d "Master Server is available!<br/>Registering as Backup Server" -l "/Settings/unraid-replication"
  if [ "${DOCKER_REPLICATION}" == "enabled" ]; then
    # Get all Autostart containers
    # !!! Still not sure if the file /var/lib/docker/unraid-autostart should be used !!!
    CONTAINERS="$(docker ps -a --format "{{.Names}}")"
    if [[ -z "${CONTAINERS}" || "${CONTAINERS}" == "null" ]]; then
      return
    fi
    IFS=$'\n'
    for container in ${CONTAINERS}; do
      docker container stop ${container}
    done
  fi
  if [ "${LXC_REPLICATION}" == "enabled" ]; then
    LXC_SETTINGS="$(cat /boot/config/plugins/lxc/plugin.cfg)"
    LXC_PATH="$(cat /boot/config/plugins/lxc/lxc.conf | grep 'lxcpath' | cut -d '=' -f2 | sed 's/\"//g')"
    CONTAINERS="$(lxc-ls --line)"
    if [ -z "${CONTAINERS}" ]; then
      return
    fi
    IFS=$'\n'
    for container in ${CONTAINERS}; do
      lxc-stop ${container}
    done
  fi
  if [ "${VM_REPLICATION}" == "enabled" ]; then
    echo "TBD"
  fi
  # Check if reverse replication is set
  if [ -f "${TMP_PATH}/reverseReplication" ]; then
    /usr/local/emhttp/plugins/dynamix/scripts/notify -e "Reverse Replication" -d "Reverse Replication started...<br/>Please wait until you are notified that Reverse Replication finished!" -i "alert" -l "/Settings/unraid-replication"
    /usr/local/emhttp/plugins/unraid-replication/scripts/reverse_replication
    /usr/local/emhttp/plugins/dynamix/scripts/notify -e "Reverse Replication" -d "Reverse Replication finished!" -l "/Settings/unraid-replication"
  fi
fi
