#!/bin/bash
APP="dockerimages"
APP_ID="dockerimagesbase"

CLUSTERNAME=$(ls /mapr)

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh

cp -R ${APP_ROOT}/${APP}_packages/* ${APP_HOME}/
cp ${APP_ROOT}/build_images.sh ${APP_HOME}/
chmod +x ${APP_HOME}/build_images.sh

cd ${APP_HOME}
for D in ./*; do
    if [ -d "${D}" ]; then
        sed -i "s/FROM zeta/FROM ${ZETA_DOCKER_REG_URL}/" ${D}/Dockerfile
    fi
done

echo ""
echo ""
echo "Base Docker Image packages installed to ${MESOS_ROLE} at ${APP_HOME}"
echo ""
echo "Now run ${APP_HOME}/build_images.sh to build all images and push to the Docker Registry"
echo ""
echo ""
