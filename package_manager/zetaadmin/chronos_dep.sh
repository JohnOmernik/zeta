#!/bin/bash

CLUSTERNAME=$(ls /mapr)
. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_prod.sh

. /mapr/$CLUSTERNAME/mesos/kstore/prod/chronos/chronosprod.sh

if [ "$#" -ne 1 ]; then
    echo "Script takes a json file as argument"
    exit 1;
fi

curl -u "$CHRONOSPROD_USER:$CHRONOSPROD_PASS" -i -L -H 'Content-Type: application/json' -X POST -d@"$@" http://$ZETA_CHRONOS_HOST:$ZETA_CHRONOS_PORT/scheduler/dependency




