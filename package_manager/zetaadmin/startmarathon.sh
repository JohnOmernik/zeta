#!/bin/bash
MARATHON_INSTANCE="prod"
CLUSTERNAME=$(ls /mapr)
. /mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_${MARATHON_INSTANCE}.sh

STARTSCRIPT="/mapr/$CLUSTERNAME/mesos/${MARATHON_INSTANCE}/marathon/launch_marathon.sh"

echo "Starting Marathon Masters:"

for MASTER in $ZETA_MARATHON_MASTERS
do
   CMD="ssh $MASTER $STARTSCRIPT"
   echo $CMD
#   $CMD
done

