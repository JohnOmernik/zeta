#!/bin/bash

APP="kafka"
CLUSTERNAME=$(ls /mapr)

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh


WORK_DIR="/tmp" # Used for creating tmp information
rm -rf ${WORK_DIR}/${APP}
cd ${WORK_DIR}
mkdir -p ${WORK_DIR}/${APP}
cd ${WORK_DIR}/${APP}


##############
# Provide Kafka URLs
APP_URL_ROOT="https://archive.apache.org/dist/kafka/0.9.0.1/"
APP_URL_FILE="kafka_2.10-0.9.0.1.tgz"

##############
# Kafka Mesos Git Repo

APP_GIT_URL="https://github.com"
APP_GIT_USER="mesos"
APP_GIT_REPO="kafka"

mkdir -p ./build

git clone ${APP_GIT_URL}/${APP_GIT_USER}/${APP_GIT_REPO}
cd ${APP_GIT_REPO}
./gradlew jar -x test
echo ""
echo "Built without the tests due to bug in mesos-kafka issue # 184"
echo ""
# Get the version built 
APP_MESOS_VER=$(ls -1|grep jar|sed "s/kafka-mesos-//g"|sed "s/.jar//g")
cp kafka-mesos-*.jar ../build/
cp kafka-mesos.sh ../build/

# Go to the build  directory
cd ..
cd build
wget ${APP_URL_ROOT}${APP_URL_FILE}


##############
# Finanlize location of pacakge

# tar up the package with the version and copy to ${APP_ROOT}/${APP}_packages
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

##############
# Provide next step instuctions
echo ""
echo ""
echo "${APP} release is prepped for use and uploaded to docker registry or copied to ${APP}_packages as ${APP_TGZ}"
echo "Next step is to install a running instace of ${APP}"
echo ""
echo "> ${APP_ROOT}/install_instance.sh"
echo ""
echo ""



##############
# Clean up Work Dir
cd ${WORK_DIR}
rm -rf ${WORK_DIR}/${APP}
