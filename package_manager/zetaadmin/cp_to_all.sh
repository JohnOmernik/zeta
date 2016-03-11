#!/bin/bash

MESOS_ROLE="prod"
CLUSTERNAME=$(ls /mapr)

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

for NODE in $ZETA_NODES
do
    echo $NODE;scp $1 ${NODE}:$2
done



