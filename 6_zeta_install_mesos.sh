#!/bin/bash

CLUSTERNAME=$(ls /mapr)
. /mapr/$CLUSTERNAME/user/zetaadm/cluster.conf

echo "Downloading: ${MESOS_RPM_ROOT}${MESOS_RPM}"
wget ${MESOS_RPM_ROOT}${MESOS_RPM}

sudo rpm -i ${MESOS_RPM}

