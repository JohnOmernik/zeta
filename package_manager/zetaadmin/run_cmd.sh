#!/bin/bash

MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)


if [ -f "/mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh" ]; then
    . /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh
else
    ZETA_NODES=$(cat /home/zetaadm/nodes.list|tr "\n" " ")
fi

cd "$(dirname "$0")"

for NODE in ${ZETA_NODES}
do
   ssh -o StrictHostKeyChecking=no $NODE $1 
done
