#!/bin/bash

MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)
. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh
. /mapr/$CLUSTERNAME/mesos/kstore/${MESOS_ROLE}/chronos/chronos.sh

if [ "$#" -ne 1 ]; then
    echo "Script takes a json file as argument"
    exit 1; 
fi

curl -u "$CHRONO_USER:$CHRONOS_PASS" -i -L -H 'Content-Type: application/json' -X POST -d@"$@" http://$ZETA_CHRONOS_HOST:$ZETA_CHRONOS_PORT/scheduler/dependency




