#!/bin/bash


CLUSTERNAME=$(ls /mapr)

ROLE_GUESS=$(echo "$(realpath "$0")"|cut -d"/" -f5)

APP="drill"

read -e -p "We autodetected the Mesos Role as ${ROLE_GUESS}. Please enter the Mesos role to use for this ${APP} instance install: " -i $ROLE_GUESS MESOS_ROLE

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

APP_ROOT="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/${APP}"

WORK_DIR="/tmp"

echo "Preparing Temp Area to build ${APP}"
rm -rf ${WORK_DIR}/${APP}
cd ${WORK_DIR}
mkdir ${APP}

#Multiple sources can be used, but we prefer the packaged RPMs from MapR so it works with all features. Sometimes that's a dev release, sometimes its from the main repo"

APP_URL_ROOT="http://mapr-9166720.s3.amazonaws.com/"
#APP_URL_ROOT="http://package.mapr.com/releases/ecosystem-5.x/redhat/"

APP_URL_FILE="mapr-drill-1.6.0.201603141532-1.noarch.rpm"
#APP_URL_FILE="mapr-drill-1.4.0.201601071151-1.noarch.rpm"


cd ${WORK_DIR}/${APP}

wget ${APP_URL_ROOT}${APP_URL_FILE}

echo "if rpm2cpio and cpio are not installed, this will fail. If so, just install them and run again"

rpm2cpio ${APP_URL_FILE} | cpio -idmv

APP_VER=$(ls ./opt/mapr/drill/)

APP_TGZ="${APP_VER}.tgz"

mv ./opt/mapr/drill/${APP_VER} ./

cd ${APP_VER}

echo "Moving default conf to conf_orig"
mv ./conf ./conf_orig
echo "Adding libjpam and extrajars to distribution"
cp -R ${APP_ROOT}/libjpam ./
cp ${APP_ROOT}/extrajars/* ./jars/3rdparty/

cd ..

echo "Packaging new tgz for execution in Mesos"
tar zcf ${APP_TGZ} ${APP_VER}

if [ -f "${APP_ROOT}/${APP}_packages/${APP_TGZ}" ]; then
    echo "This package already exists. We can exit now, without overwriting, or you can overwrite with the package you just built"
    read -e -p "Should we overwrite ${APP_TGZ} located in ${APP_ROOT}/${APP}_packages with the currently built package? (Y/N): " -i "N" OW
    if [ "$OW" != "Y" ]; then
        echo "Your answer was not Y therefore we are exiting"
        exit 1
    fi
fi


echo "Moving to ${APP} location at ${APP_ROOT}/${APP}_packages"
mv ${APP_TGZ} ${APP_ROOT}/${APP}_packages/
echo ""
echo "${APP} Ver: ${APP_VER} installed to ${APP_ROOT}/${APP}_packages/"
echo "Ready for use in instance"
echo ""

cd ${WORK_DIR}
rm -rf ${WORK_DIR}/${APP}
