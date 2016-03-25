#!/bin/bash

APP="mesosdns"
APP_ID="mesosdnsprod"

CLUSTERNAME=$(ls /mapr)

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh

APP_URL_ROOT="https://github.com/mesosphere/mesos-dns/releases/download/"
APP_VER="v0.5.2"
APP_URL_FILE="mesos-dns-${APP_VER}-linux-amd64"

cd ${APP_ROOT}/${APP}_packages
wget ${APP_URL_ROOT}${APP_VER}/${APP_URL_FILE}

chmod +x ./${APP_URL_FILE}


echo ""
echo ""
echo "Mesos DNS version $APP_VER obtained in stored in ${APP_ROOT}/${APP}_packages"
echo "Ready for instance install"
echo "${APP_ROOT}/install_instance.sh"
echo ""
echo ""

