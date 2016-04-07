#!/bin/bash

APP="drill"
CLUSTERNAME=$(ls /mapr)

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh


WORK_DIR="/tmp" # Used for creating tmp information
rm -rf ${WORK_DIR}/${APP}
cd ${WORK_DIR}
mkdir -p ${WORK_DIR}/${APP}
cd ${WORK_DIR}/${APP}

##############
# Provide example URLS Downloads
APP_URL_ROOT="http://package.mapr.com/releases/ecosystem-5.x/redhat/"
APP_URL_FILE="mapr-drill-1.6.0.201603302146-1.noarch.rpm"

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


##############
# Finanlize location of pacakge

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
rm -rf ${WORK_DIR}/${APP}
