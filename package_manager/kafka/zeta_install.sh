#!/bin/bash

APP="kafka"

read -e -p "Please enter the Mesos Role you wish to install ${APP} to:" -i "prod" MESOS_ROLE

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh


APP_ROOT="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/${APP}"

if [ -d "${APP_ROOT}" ]; then
    echo "The Installation Directory already exists at ${APP_ROOT}"
    echo "Installation will not continue over that, please rename or delete the existing directory to install fresh"
    exit 1
fi

echo "Making Directories for kafka"
mkdir -p ${APP_ROOT}
mkdir -p ${APP_ROOT}/${APP}_packages

#Scripts to move

cp get_kafka_release.sh ${APP_ROOT}/
cp install_instance.sh  ${APP_ROOT}/
cp initial_broker_setup.sh ${APP_ROOT}/

# Scripts to make executable (the config instance should not be executable as that is made +x when the instance is installed)
chmod +x ${APP_ROOT}/get_kafka_release.sh
chmod +x ${APP_ROOT}/install_instance.sh


echo ""
echo "${APP} Package installed to ${MESOS_ROLE}. Next steps:"
echo ""
echo "1. Make some ${APP} tgzs to run in Zeta with ${APP_ROOT}/get_${APP}_release.sh"
echo "2. Install a specific ${APP} instance with ${APP_ROOT}/install_instance.sh"
echo "3. Setup your brokers with ${APP_ROOT}/\$YOUR_INSTANCE/initial_broker_setup.sh"

