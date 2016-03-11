#!/bin/bash
CLUSTERNAME=$(ls /mapr)
MARATHON_INSTANCE="prod"

. /mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_${MARATHON_INSTANCE}.sh
. /mapr/${CLUSTERNAME}/mesos/kstore/${MARATHON_INSTANCE}/marathon/marathon.sh

# This is for prod.

MARATHON_URL="http://marathon${MARATHON_INSTANCE}.${ZETA_MESOS_DOMAIN}:${ZETA_MARATHON_PORT}/v2/apps"

echo "$MARATHON_URL"

MARJSON=$1
MARHOST=$2
if [ "$MARHOST" != "" ]; then
    MARATHON_URL="http://${MARHOST}:${ZETA_MARATHON_PORT}/v2/apps"
fi

if [ "$MARJSON" == "" ]; then
   echo "Run this as a proper prived used passing the name of the json file you want to start as the only variables"
   exit 0
fi

curl -X POST -u "$MARATHON_USER:$MARATHON_PASS" -H "Content-Type: application/json" $MARATHON_URL -d@$MARJSON
