#!/bin/bash

CLUSTERNAME=$(ls /mapr)

ROLE_GUESS=$(echo "$(realpath "$0")"|cut -d"/" -f5)

APP="%YOURAPPNAME%"

re="^[a-z0-9]+$"
if [[ ! "${APP}" =~ $re ]]; then
    echo "App name can only be lowercase letters and numbers"
    exit 1
fi

read -e -p "We autodetected the Mesos Role as ${ROLE_GUESS}. Please enter the Mesos role to use for this ${APP} instance install: " -i $ROLE_GUESS MESOS_ROLE

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

APP_ROOT="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/${APP}"


# Provide a working dir
WORK_DIR="/tmp"


echo "Preparing Temp Area to build ${APP}"
rm -rf $WORK_DIR/${APP}
cd $WORK_DIR
mkdir ${APP}

# Provide example URLS This one is for Kafka Mesos
APP_URL_ROOT="https://archive.apache.org/dist/kafka/0.9.0.1/"
APP_URL_FILE="kafka_2.10-0.9.0.1.tgz"

## Future work setup a Docker container to do the building in

cd ${WORK_DIR}/${APP}
mkdir ./build

echo "Getting and building ${APP}"
#Do what your app needs, this example is for kafka-mesos

git clone https://github.com/mesos/kafka
cd kafka

./gradlew jar -x test
echo ""
echo "Built without the tests due to bug in mesos-kafka issue # 184"
echo ""

APP_MESOS_VER=$(ls -1|grep jar|sed "s/kafka-mesos-//g"|sed "s/.jar//g")

cp kafka-mesos-*.jar ../build/
cp kafka-mesos.sh ../build/

cd ..
cd build

wget ${APP_URL_ROOT}${APP_URL_FILE}

APP_TGZ="${APP}-mesos-${APP_MESOS_VER}.tgz"

tar zcf ${APP_TGZ} ./*

if [ -f "${APP_ROOT}/${APP}_packages/${APP_TGZ}" ]; then
    echo "This package already exists. We can exit now, without overwriting, or you can overwrite with the package you just built"
    read -e -p "Should we overwrite ${APP_TGZ} located in ${APP_ROOT}/${APP}_packages with the currently built package? (Y/N): " -i "N" OW
    if [ "$OW" != "Y" ]; then
        echo "Your answer was not Y therefore we are exiting"
        exit 1
    fi
fi

mv ${APP_TGZ} ${APP_ROOT}/${APP}_packages/
echo ""
echo "Built ${APP_TGZ} using ${APP_URL_FILE} and moved to ${APP_ROOT}/${APP}_packages/"
echo ""


cd ${WORK_DIR}
rm -rf ${WORK_DIR}/${APP}
