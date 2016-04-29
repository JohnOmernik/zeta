#!/bin/bash

APP="pyedwin"
CLUSTERNAME=$(ls /mapr)

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh


WORK_DIR="/tmp" # Used for creating tmp information
rm -rf ${WORK_DIR}/${APP}
cd ${WORK_DIR}
mkdir -p ${WORK_DIR}/${APP}
cd ${WORK_DIR}/${APP}

##############
# Provide example URLS Downloads
#APP_URL_ROOT="https://archive.apache.org/dist/kafka/0.9.0.1/"
#APP_URL_FILE="kafka_2.10-0.9.0.1.tgz"


##############
#Provide example GIT Settings
APP_GIT_URL="https://github.com"
APP_GIT_USER="johnomernik"
APP_GIT_REPO="pyedwin"
git clone ${APP_GIT_URL}/${APP_GIT_USER}/${APP_GIT_REPO}

cd ${APP_GIT_REPO}

sed -i "s@ZEPPELIN_JAR_PATH=~/pyedwin/zeppelin/zeppelin-interpreter@ZEPPELIN_JAR_PATH=zeppelin/zeppelin-interpreter@" ./build_interpreter.sh
APP_TGZ="pyedwin.tgz"

mkdir zeppelin/zeppelin-interpreter
cp /mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/zeppelin/zeppelin_packages/zeppelin-interpreter-0.6.0-incubating-SNAPSHOT.jar zeppelin/zeppelin-interpreter/
./build_interpreter.sh 1
./package_edwin.sh

tar zxf ./${APP_TGZ}
sed -i "s@\./edwin_main.json@/zeppelin/interpreter/pyedwin/edwin_main.json@" ./pyedwin/pyedwin.py
sed -i "s@\./edwin_org.json@${APP_PACKAGES}/edwin_org.json@" ./pyedwin/pyedwin.py
sed -i "s@\./edwin_user.json@/conf/edwin_user.json@" ./pyedwin/pyedwin.py

rm -rf ./${APP_TGZ}
tar zcf ./${APP_TGZ} ./pyedwin

echo ""
echo "Build complete"
echo ""
ls -1 /mapr/$CLUSTERNAME/$APP_DIR/$MESOS_ROLE/zeppelin/zeppelin_packages/*.tgz
echo ""
echo "Above are the zeppelin packages we have, we can install pyedwin into the master package if desired. This will take some time however."
read -e -p "Do you wish to install pyedwin to a Zeppelin package? " -i "Y" APP_ANSWER

if [ "$APP_ANSWER" == "Y" ]; then
    read -e -p "Please enter the name of the Zeppelin package to install pyedwin to: " -i "zeppelin-0.6.0-incubating-SNAPSHOT.tgz" APP_ZEP_TGZ
    if [ -f "/mapr/$CLUSTERNAME/${APP_DIR}/$MESOS_ROLE/zeppelin/zeppelin_packages/${APP_ZEP_TGZ}" ]; then
        APP_ZEP_VER=$(echo ${APP_ZEP_TGZ}|sed "s/\.tgz//")
        mkdir -p ${WORK_DIR}/${APP}/zep
        cd ${WORK_DIR}/${APP}/zep
        echo "Copying Zeppelin Instance Locally"
        cp /mapr/$CLUSTERNAME/${APP_DIR}/$MESOS_ROLE/zeppelin/zeppelin_packages/${APP_ZEP_TGZ} .
        echo "Untaring ${APP_ZEP_TGZ}"
        tar zxf ./${APP_ZEP_TGZ}
        echo "Untaring pyedwin ${WORK_DIR}/${APP}/${APP}/${APP_TGZ} into /${APP_ZEP_VER}/interpreter/"
        tar zxf ${WORK_DIR}/${APP}/${APP}/${APP_TGZ} -C ./${APP_ZEP_VER}/interpreter/
        rm ${APP_ZEP_TGZ}
        echo "retarring Zepplin package"
        tar zcf ./${APP_ZEP_TGZ} ./${APP_ZEP_VER}
        echo "Copying back to zeppelin_packages"
        cp ./${APP_ZEP_TGZ} /mapr/$CLUSTERNAME/${APP_DIR}/$MESOS_ROLE/zeppelin/zeppelin_packages/
    else
        echo "That Zeppelin package doesn't exist, not packing pyedwin"
    fi
fi


##############
if [ -f "${APP_ROOT}/${APP}_packages/${APP_TGZ}" ]; then
    echo "This package already exists. We can exit now, without overwriting, or you can overwrite with the package you just built"
    read -e -p "Should we overwrite ${APP_TGZ} located in ${APP_ROOT}/${APP}_packages with the currently built package? (Y/N): " -i "N" OW
    if [ "$OW" != "Y" ]; then
        echo "Your answer was not Y therefore we are exiting"
        exit 1
    fi
fi
cd ${WORK_DIR}/${APP}/${APP}
mv ${APP_TGZ} ${APP_ROOT}/${APP}_packages/

##############
# Provide next step instuctions
echo ""
echo ""
echo "${APP} release is prepped for use and uploaded to docker registry or copied to ${APP}_packages"
echo "Next step is to install a running instace of ${APP}"
echo ""
echo "> ${APP_ROOT}/install_instance.sh"
echo ""
echo ""



##############
# Clean up Work Dir
cd ${WORK_DIR}
sudo rm -rf ${WORK_DIR}/${APP}
