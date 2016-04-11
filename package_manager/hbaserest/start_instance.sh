#!/bin/bash

CLUSTERNAME=$(ls /mapr)

APP="hbaserest"

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh


${MARATHON_SUBMIT} ${APP_HOME}/${APP_ID}.marathon

### Consider getting some variables to help the user
#TURL="ZETA_${APP_UP}_${APP_ID}_URL"

#eval RURL=\$$TURL


echo ""
echo ""
echo "$APP, installed to ${APP_HOME}, has been started via Marathon"
echo ""
echo ""

