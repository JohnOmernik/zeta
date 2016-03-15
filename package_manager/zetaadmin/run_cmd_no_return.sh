#!/bin/bash

MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)
. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh
cd "$(dirname "$0")"

for NODE in ${ZETA_NODES}
do
   ssh -o StrictHostKeyChecking=no $NODE "nohup $1 > /dev/null 2>&1"e
done

