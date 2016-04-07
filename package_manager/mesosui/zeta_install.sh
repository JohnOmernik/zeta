#!/bin/bash

APP="mesosui"

re="^[a-z0-9]+$"
if [[ ! "${APP}" =~ $re ]]; then
    echo "App name can only be lowercase letters and numbers"
    exit 1
fi

MESOS_ROLE="prod"

echo "${APP} must be installed to prod"

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

cp get_mesosui_release.sh ${APP_ROOT}/
cp install_instance.sh ${APP_ROOT}/
cp start_instance.sh ${APP_ROOT}/

chmod +x ${APP_ROOT}/get_mesosui_release.sh
chmod +x ${APP_ROOT}/install_instance.sh


echo ""
echo ""
echo "mesosui files installed to ${MESOS_ROLE}"
echo "Now build the docker file with:"
echo "> ${APP_ROOT}/get_mesosui_release.sh"
echo ""
echo ""
