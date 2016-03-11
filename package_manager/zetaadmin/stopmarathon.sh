#!/bin/bash
MARATHON_INSTANCE="prod"

CLUSTERNAME=$(ls /mapr)
. /mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_${MARATHON_INSTANCE}.sh

for MASTER in $ZETA_MARATHON_MASTERS
do
   PIDCMD="ps ax|grep \"marathon-assembly\"|grep -v grep|grep -v stopmarathon|grep marathon${MARATHON_INSTANCE}|sed -r \"s/^\s+//\"|cut -d\" \" -f1"
   PID=$(ssh $MASTER "$PIDCMD" 2> /dev/null)

    echo "Killing Marthon as PID: $PID on $MASTER"
    ssh $MASTER "sudo kill $PID" 2> /dev/null
done
