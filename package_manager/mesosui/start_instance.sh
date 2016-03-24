#!/bin/bash
CLUSTERNAME=$(ls /mapr)

ROLE_GUESS=$(echo "$(realpath "$0")"|cut -d"/" -f5)


APP="mesosui"

re="^[a-z0-9]+$"
if [[ ! "${APP}" =~ $re ]]; then
    echo "App name can only be lowercase letters and numbers"
    exit 1
fi

APP_ID="mesosuiprod"
if [[ ! "${APP_ID}" =~ $re ]]; then
    echo "Instance name can only be lowercase letters and numbers"
    exit 1
fi

APP_UP=$(echo $APP | tr '[:lower:]' '[:upper:]')

read -e -p "We autodetected the Mesos Role as ${ROLE_GUESS}. Please enter the Mesos role to use for this instance install: " -i $ROLE_GUESS MESOS_ROLE

read -e -p "We autodetected the instance for ${APP} startup to be ${APP_ID_GUESS}. Please enter the instance name for ${APP} startup: " -i ${APP_ID} APP_ID

APP_ROOT="/mapr/$CLUSTERNAME/mesos/${MESOS_ROLE}/${APP}"
APP_HOME="${APP_ROOT}/${APP_ID}"

MARATHON_SUBMIT="/home/zetaadm/zetaadmin/marathon${MESOS_ROLE}_submit.sh"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

if [ ! -d "${APP_HOME}" ]; then
    echo "${APP_HOME} does not exist. Are you sure your ${APP} instance ${APP_ID} is installed properly?"
    exit 1
fi

$MARATHON_SUBMIT ${APP_HOME}/${APP_ID}.marathon


THOST="ZETA_${APP_UP}_HOST"
TPORT="ZETA_${APP_UP}_PORT"

eval RHOST=\$$THOST
eval RPORT=\$$TPORT


echo ""
echo ""
echo "Your ${APP} Instance is running"
echo "It can be found: http://${RHOST}:${RPORT}"
echo ""
echo ""

