#!/bin/bash

APP="schema-registry"

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

if [ ! -d "/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/confluent_base" ]; then
    echo "Cannot install ${APP} without confluent base package"
    echo "Please install confluent_base first"
    echo "Exiting"
    exit 1
fi

echo "Making Directory for ${APP}"
mkdir -p ${APP_ROOT}
echo ""
echo "Copying Files for ${APP}"
cp -R ./conf ${APP_ROOT}/
cp install_instance.sh ${APP_ROOT}/
cp start_instance.sh ${APP_ROOT}/
chmod +x ${APP_ROOT}/install_instance.sh
echo ""
echo "${APP} Base Installed"
echo "To install an individual ${APP} instance run:"
echo ""
echo "> ${APP_ROOT}/install_instance.sh"
echo ""

