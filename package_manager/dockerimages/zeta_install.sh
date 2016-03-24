#!/bin/bash

#!/bin/bash

APP="dockerimages"

re="^[a-z0-9]+$"

if [[ ! "${APP}" =~ $re ]]; then
    echo "App name can only be lowercase letters and numbers"
    exit 1
fi
read -e -p "Please enter the Mesos Role you wish to install ${APP} to: " -i "prod" MESOS_ROLE

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh


APP_ROOT="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/${APP}"

if [ -d "${APP_ROOT}" ]; then
    echo "The Installation Directory already exists at ${APP_ROOT}"
    echo "Installation will not continue over that, please rename or delete the existing directory to install fresh"
    exit 1
fi

echo "Making Directories for ${APP}"
mkdir -p ${APP_ROOT}

cp -R ./* ${APP_ROOT}/
rm ${APP_ROOT}/zeta_install.sh
chmod +x ${APP_ROOT}/build_images.sh

cd ${APP_ROOT}

for D in ./*; do
    if [ -d "${D}" ]; then
        sed -i "s/FROM zeta/FROM ${ZETA_DOCKER_REG_URL}/" ${D}/Dockerfile
    fi
done




echo "Base Docker Image Build script installed to ${APP_ROOT}"
echo "To Build and push to Docker Registry, run: ${APP_ROOT}/build_images.sh"
echo ""
echo "Images can be rebuilt at anytime with the build_images.sh script"
echo ""

