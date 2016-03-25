#!/bin/bash

APP="mesosdns"
APP_DIR="mesos"
MESOS_ROLE="prod"
CLUSTERNAME=$(ls /mapr)
. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_zeta_install.sh

# At this point ${APP_ROOT} is available and the directory is made.
mkdir -p ${APP_ROOT}/${APP}_packages
cd "$(dirname "$0")"

cp ./install_instance.sh ${APP_ROOT}/
cp ./get_package.sh ${APP_ROOT}/
chmod +x ${APP_ROOT}/install_instance.sh
chmod +x ${APP_ROOT}/get_package.sh


echo ""
echo ""
echo "Mesos DNS installed to ${MESOS_ROLE}"
echo "Next Steps:"
echo "${APP_ROOT}/get_package.sh"
echo "${APP_ROOT}/install_instance.sh"
echo ""
echo ""

