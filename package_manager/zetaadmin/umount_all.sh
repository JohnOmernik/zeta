#!/bin/bash

MESOS_ROLE="prod"
CLUSTERNAME=$(ls /mapr)
. /mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

echo "Umounting /mapr on all nodes"

for NODE in $ZETA_NODES
do
   echo "Umounting on $NODE"
   ssh $NODE "hostname;sudo umount /mapr"
done






