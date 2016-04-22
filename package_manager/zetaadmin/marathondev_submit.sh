#!/bin/bash
CLUSTERNAME=$(ls /mapr)
MARATHON_INSTANCE="dev"

MARATHON_URL="http://${ZETA_MARATHON_ENV}.${ZETA_MESOS_DOMAIN}:${ZETA_MARATHON_PORT}/v2/apps"

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

if [ "${MARATHON_USER}" == "" ]; then
    curl -X POST -H "Content-Type: application/json" $MARATHON_URL -d@$MARJSON
else
    curl -X POST -u "$MARATHON_USER:$MARATHON_PASS" -H "Content-Type: application/json" $MARATHON_URL -d@$MARJSON
fi
