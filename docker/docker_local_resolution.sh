#!/bin/bash
# ------------------------------------------------------------------
# [Carlos Giraldo] Docker Local Container Resolution
#   This scripts add container hostnames/IP to the host /etc/hosts files
#   This enable access to containers by hostname in the Host.
# ------------------------------------------------------------------

VERSION=0.1.0
SUBJECT=docker_local_resolution.sh
USAGE="Usage: docker_local_resolution.sh enable|disable"

# --- Options processing -------------------------------------------
if [ "$#" -ne 1 ] ; then
    echo $USAGE
    exit 1;
fi

enable()
{
  mapfile -t RUNNING_CONTAINERS < <(docker ps -q)
  for CONTAINER_ID in "${RUNNING_CONTAINERS[@]}"
  do
    HOSTS_ENTRY=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} {{.Config.Hostname}} {{.Config.Hostname}}.{{.Config.Domainname}}' $CONTAINER_ID)
    echo "adding $HOSTS_ENTRY to /etc/hosts"
    echo "$HOSTS_ENTRY" | sudo tee -a /etc/hosts &>/dev/null
  done
}

disable()
{
  mapfile -t HOSTS_ENTRIES < <(grep -E '.pnda' /etc/hosts)
  for HOSTS_ENTRY in "${HOSTS_ENTRIES[@]}"
  do
  read -r -p "Remove $HOSTS_ENTRY entry in /etc/hosts? [Y/n] " REPLY
    if [[ ! $REPLY =~ ^[Nn]$ ]]
        then
        echo "Removing $HOSTS_ENTRY from /etc/hosts"
        sudo sed -i "/$HOSTS_ENTRY/d" /etc/hosts
    fi
   done
}


if [ "$1" == "enable" ] ; then
    enable
elif [ "$1" == "disable" ] ; then
    disable
else
   echo "wrong argument. Must be enable or disable."
   exit 1;
fi
