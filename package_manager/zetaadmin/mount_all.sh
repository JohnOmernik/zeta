#!/bin/bash

CLUSTERNAME=$(ls /mapr)
. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_prod.sh


echo "Mounting /mapr on all nodes"

for NODE in $ZETA_NODES
do
#   ssh $NODE "hostname;sudo mount -t nfs -o nfsvers=3,noatime,rw,nolock,hard,intr $NODE:/mapr /mapr"
   echo "ssh $NODE \"hostname;sudo mount -t nfs -o nfsvers=3,noatime,rw,nolock,hard,intr $NODE:/mapr /mapr\""

done
