#!/bin/bash
CLUSTERNAME=$(ls /mapr)

ROLE_GUESS=$(pwd|cut -d"/" -f5)

APP_ID_GUESS=$(basename `pwd`)

APP="kafka-rest"

APP_UP=$(echo $APP | tr '[:lower:]' '[:upper:]')

read -e -p "We autodetected the Mesos Role as ${ROLE_GUESS}. Please enter the Mesos role to use for this instance install: " -i $ROLE_GUESS MESOS_ROLE

read -e -p "We autodetected the instance for ${APP} startup to be ${APP_ID_GUESS}. Please enter the instance name for ${APP} startup: " -i ${APP_ID_GUESS} APP_ID

APP_ROOT="/mapr/$CLUSTERNAME/mesos/${MESOS_ROLE}/${APP}"
APP_HOME="${APP_ROOT}/${APP_ID}"

MARATHON_SUBMIT="/home/zetaadm/zetaadmin/marathon${MESOS_ROLE}_submit.sh"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

if [ ! -d "${APP_HOME}" ]; then
    echo "${APP_HOME} does not exist. Are you sure your ${APP} instance ${APP_ID} is installed properly?"
    exit 1
fi
APP_ID_ENV=$(echo ${APP_ID}|tr "-" "_")
cd ${APP_HOME}

$MARATHON_SUBMIT ${APP_ID}.marathon

TWEB="ZETA_KAFKAREST_${APP_ID_ENV}_HOST"
TPORT="ZETA_KAFKAREST_${APP_ID_ENV}_PORT"
eval RWEB=\$$TWEB
eval RPORT=\$$TPORT

echo ""
echo ""
echo "Your ${APP} Instance is running:"
echo "The Rest API lives here: http://${RWEB}:${RPORT}"
echo ""
echo ""




