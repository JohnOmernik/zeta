#!/bin/bash

CLUSTERNAME=$(ls /mapr)

APP="kafkamanager"

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh


${MARATHON_SUBMIT} ${APP_HOME}/${APP_ID}.marathon

### Consider getting some variables to help the user
THOST="ZETA_${APP_UP}_${APP_ID}_HOST"
TPORT="ZETA_${APP_UP}_${APP_ID}_PORT"

eval RHOST=\$$THOST
eval RPORT=\$$TPORT


echo ""
echo ""
echo "$APP, installed to ${APP_HOME}, has been started via Marathon"
echo ""
echo "It can be reached at:"
echo ""
echo "http://${RHOST}:${RPORT}"
echo ""
echo ""
