#!/bin/bash

APP="confluentbase"

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
mkdir -p ${APP_ROOT}/dockerbuild

cp build_docker.sh ${APP_ROOT}/

chmod +x ${APP_ROOT}/build_docker.sh

echo ""
echo ""
echo "Confluent Base Docker Image build scripts installed to ${APP_ROOT}"
echo "To build and push to Docker Registry, execute ${APP_ROOT}/build.docker.sh"
echo "> ${APP_ROOT}/build_docker.sh"
echo ""
echo ""
