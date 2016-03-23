#!/bin/bash
CLUSTERNAME=$(ls /mapr)

ROLE_GUESS=$(echo "$(realpath "$0")"|cut -d"/" -f5)

APP_ID_GUESS=$(basename $(dirname `realpath "$0"`))

APP="mesos-ui"


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

$MARATHON_SUBMIT ${APP_HOME}/${APP_ID}.marathon

echo ""
echo ""
echo "Your ${APP} Instance is running"
echo ""
echo ""

