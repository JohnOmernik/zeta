#!/bin/bash

APP="dockerregv2"
CLUSTERNAME=$(ls /mapr)

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh


${MARATHON_SUBMIT} ${APP_HOME}/${APP_ID}.marathon

echo ""
echo ""
echo "$APP installed to ${APP_HOME} and started via Marathon"
echo ""
echo ""
