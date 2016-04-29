#!/bin/bash

APP="dockerimages"
CLUSTERNAME=$(ls /mapr)
. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_zeta_install.sh

# At this point ${APP_ROOT} is available and the directory is made.
mkdir -p ${APP_ROOT}/${APP}_packages
cd "$(dirname "$0")"

cp -R ./* ${APP_ROOT}/${APP}_packages
rm ${APP_ROOT}/${APP}_packages/zeta_install.sh
mv ${APP_ROOT}/${APP}_packages/install_instance.sh ${APP_ROOT}/
mv ${APP_ROOT}/${APP}_packages/build_images.sh ${APP_ROOT}/
chmod +x ${APP_ROOT}/install_instance.sh

echo ""
echo ""
echo "Base Docker Image packages installed to ${MESOS_ROLE} at ${APP_ROOT}"
echo "Now run ${APP_ROOT}/install_instance.sh"
echo ""
echo ""
