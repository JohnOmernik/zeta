#!/bin/bash

CLUSTERNAME=$(ls /mapr)
. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_prod.sh
cd "$(dirname "$0")"

for NODE in ${ZETA_NODES}
do
   ssh -o StrictHostKeyChecking=no $NODE $1 
done
