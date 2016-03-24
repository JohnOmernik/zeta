#!/bin/bash

APP="drill"

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
mkdir -p ${APP_ROOT}/${APP}_packages
mkdir -p ${APP_ROOT}/extrajars

cp -R ./libjpam ${APP_ROOT}/

# Add Readme to extrajars
echo "Place extra jars in this folder including storage plugin jars, or udf jars" > ${APP_ROOT}/extrajars/README.txt


cp get_drill_release.sh ${APP_ROOT}/
cp install_instance.sh  ${APP_ROOT}/
cp start_instance.sh ${APP_ROOT}/


chmod +x ${APP_ROOT}/get_drill_release.sh
chmod +x ${APP_ROOT}/install_instance.sh


echo ""
echo "${APP} Package installed to ${MESOS_ROLE}. Next steps:"
echo ""
echo "1. Make some ${APP} tgzs to run in Zeta with ${APP_ROOT}/get_${APP}_release.sh"
echo "2. Install a specific ${APP} instance with ${APP_ROOT}/install_instance.sh"
echo "3. Configure your setup with ${APP_ROOT}/\$YOUR_INSTANCE/configure_instance.sh"
echo ""

