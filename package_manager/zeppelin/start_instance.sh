#!/bin/bash

CLUSTERNAME=$(ls /mapr)

APP="zeppelin"

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh


${MARATHON_SUBMIT} ${APP_HOME}/${APP_ID}.marathon



TURL="ZETA_${APP_UP}_${APP_ID}_URL"
TPORT="ZETA_${APP_UP}_${APP_ID}_PORT"
TUSER="ZETA_${APP_UP}_${APP_ID}_USER"

eval RURL=\$$TURL
eval RPORT=\$$TPORT
eval RUSER=\$$TUSER

echo ""
echo ""
echo "$APP, installed to ${APP_HOME}, has been started via Marathon"
echo ""
echo "It can be accessed here: http://${RURL}"
echo ""
echo "${APP} Has one more step: user_config.sh"
echo "This step needs to be run as the user (${RUSER}) who will be using the instance ${APP_ID} instance of Zeppelin"
echo "It can be found in: "
echo ""
echo "/mapr/${CLUSTERNAME}/user/${RUSER}/${APP}/${APP_ID}/user_config.sh"
echo ""
echo ""
