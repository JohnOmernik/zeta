#!/bin/bash

APP="dockerregv2"
APP_DIR="mesos"
CLUSTERNAME=$(ls /mapr)
. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_zeta_install.sh

cd "$(dirname "$0")"


cp ./install_instance.sh ${APP_ROOT}/
cp ./get_package.sh ${APP_ROOT}/
cp ./start_instance.sh ${APP_ROOT}/

chmod +x ${APP_ROOT}/install_instance.sh
chmod +x ${APP_ROOT}/get_package.sh


echo ""
echo ""
echo "${APP} installed to role ${MESOS_ROLE} at ${APP_ROOT}"
echo "Next steps, get the image by running:"
echo "${APP_ROOT}/get_package.sh"
echo "Then install your instance with install_instance.sh"
echo ""
echo ""

