#!/bin/bash

APP="%YOURAPPNAME%"
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

#wget ${APP_URL_ROOT}${APP_URL_FILE}
#tar zxf ${APP_URL_FILE}

##############
#Provide example GIT Settings

#APP_GIT_URL="https://github.com"
#APP_GIT_USER="mesos"
#APP_GIT_REPO="kafka"
#git clone ${APP_GIT_URL}/${APP_GIT_USER}/${APP_GIT_REPO}
#cd ${APP_GIT_REPO}

##############
# Provide Example Docker Pull
# We use the already built Docker Registry This could change in the future
# APP_SRC_DOCKER_REPO="registery"
# APP_SRC_DOCKER_IMAGE="2"
#sudo docker pull ${APP_SRC_DOCKER_REPO}:${APP_SRC_DOCKER_IMAGE}




##############
# Finanlize location of pacakge

# Tag and upload docker image if needed locally if needed (zeta is for local, but consider using the env variables for the roles)

#sudo docker tag ${APP_SRC_DOCKER_REPO}:${APP_SRC_DOCKER_IMAGE} zeta/${APP_SRC_DOCKER_REPO}:${APP_SRC_DOCKER_IMAGE}
#sudo docker push zeta/${APP_SRC_DOCKER_REPO}:${APP_SRC_DOCKER_IMAGE}

# or

# tar up the package with the version and copy to ${APP_ROOT}/${APP}_packages
# APP_TGZ="${APP}-mesos-${APP_MESOS_VER}.tgz"

#tar zcf ${APP_TGZ} ./*
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
