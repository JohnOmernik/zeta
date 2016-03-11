#!/bin/bash

CLUSTERNAME=$(ls /mapr)
. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_prod.sh

for NODE in $ZETA_NODES
do
    echo $NODE;scp $1 ${NODE}:$2
done



