#!/bin/bash

CLUSTERNAME=$(ls /mapr)

APP="mesosui"
APP_ID="mesosuiprod"

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh

${MARATHON_SUBMIT} ${APP_HOME}/${APP_ID}.marathon

### Consider getting some variables to help the user
THOST="ZETA_${APP_UP}_HOST"
eval RHOST=\$$THOST

TPORT="ZETA_${APP_UP}_PORT"
eval RPORT=\$$TPORT

echo ""
echo ""
echo "$APP, installed to ${APP_HOME}, has been started via Marathon"
echo ""
echo "${APP_ID} can be found here:"
echo "http://${RHOST}:${RPORT}/"
echo ""
echo ""

