#!/bin/bash
CLUSTERNAME=$(ls /mapr)

ROLE_GUESS=$(echo "$(realpath "$0")"|cut -d"/" -f5)

APP_ID_GUESS=$(basename $(dirname `realpath "$0"`))

APP="drill"

re="^[a-z0-9]+$"
if [[ ! "${APP}" =~ $re ]]; then
    echo "App name can only be lowercase letters and numbers"
    exit 1
fi

APP_UP=$(echo $APP | tr '[:lower:]' '[:upper:]')

read -e -p "We autodetected the Mesos Role as ${ROLE_GUESS}. Please enter the Mesos role to use for this instance install: " -i $ROLE_GUESS MESOS_ROLE
APP_ROOT="/mapr/$CLUSTERNAME/mesos/${MESOS_ROLE}/${APP}"

read -e -p "We autodetected the instance for ${APP} startup to be ${APP_ID_GUESS}. Please enter the instance name for ${APP} startup: " -i ${APP_ID_GUESS} APP_ID

if [[ ! "${APP_ID}" =~ $re ]]; then
    echo "App instance can only be lowercase letters and numbers"
    exit 1
fi

APP_HOME="${APP_ROOT}/${APP_ID}"


. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

if [ ! -d "${APP_HOME}" ]; then
    echo "${APP_HOME} does not exist. Are you sure your ${APP} instance ${APP_ID} is installed properly?"
    exit 1
fi

cd ${APP_HOME}

echo ""

MARATHON_SUBMIT="/home/zetaadm/zetaadmin/marathon${MESOS_ROLE}_submit.sh"

$MARATHON_SUBMIT ${APP_ID}.marathon

TNAME="ZETA_DRILL_${APP_ID}_WEB_PORT"
eval TPORT=\$$TNAME

echo ""
echo ""
echo "Your Drill cluster should be run per your specs"
echo "The Web UI should be here: https://${APP_ID}.${ZETA_MARATHON_HOST}:${TPORT}"
echo ""
echo ""
