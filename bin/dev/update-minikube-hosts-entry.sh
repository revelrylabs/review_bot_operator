#!/bin/bash

# create a hosts entry to allow accessing a hostname via the minikube IP address

HOSTNAME=$1
ETC_HOSTS=/etc/hosts

if [ -z "$HOSTNAME" ]
then
  echo "ERROR: Please provide a hostname as the first argument"
  echo "e.g. update-minikube-hosts-entry.sh test-review-app-678.review.local"
  exit 1
fi

IP=$(minikube ip)
if [ -z "$IP" ]
then
  echo "Minikube IP could not be found. Aborting"
  exit 1
else
  echo "Minikube IP is $IP"
fi

EXISTING=$(grep $HOSTNAME $ETC_HOSTS)
HOSTS_LINE="$IP  $HOSTNAME"
if [ "$EXISTING" == "$HOSTS_LINE" ]
then
  echo "Hosts file already configured. Nothing to do."
  exit 0
fi

echo "Editing file $ETC_HOSTS. You may be asked for your 'sudo' password."

if [ -n "$EXISTING" ]
then
    echo "Entry '$EXISTING' will be replaced";
    echo "A backup will be created at $ETC_HOSTS.bak";
    sudo sed -i".bak" "/$HOSTNAME/d" $ETC_HOSTS
fi

sudo -- sh -c -e "echo '$HOSTS_LINE' >> $ETC_HOSTS";
