#!/bin/bash

MESOS_ROLE="prod"
CLUSTERNAME=$(ls /mapr)
. /mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh


echo "Stopping Agents"

for AGENT in $ZETA_MESOS_AGENTS
do
   echo "Killing Mesos Agent on $AGENT"
   ssh $AGENT "hostname; sudo killall mesos-slave" 2>/dev/null
done
sleep 2

echo "Stopping Masters"
for MASTER in $ZETA_MESOS_MASTERS
do
   echo "Killing Mesos Master on $MASTER"
   ssh $MASTER "hostname; sudo killall mesos-master" 2>/dev/null
done

