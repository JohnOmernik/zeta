#!/bin/bash

APP="mesosui"
CLUSTERNAME=$(ls /mapr)
MESOS_ROLE="prod"

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh


WORK_DIR="/tmp" # Used for creating tmp information
rm -rf ${WORK_DIR}/${APP}
cd ${WORK_DIR}
mkdir -p ${WORK_DIR}/${APP}
cd ${WORK_DIR}/${APP}

##############
#Provide example GIT Settings

APP_GIT_URL="https://github.com"
APP_GIT_USER="Capgemini"
APP_GIT_REPO="mesos-ui"


mkdir -p ${APP_ROOT}/${APP}_packages/dockerbuild

cat > ${APP_ROOT}/${APP}_packages/dockerbuild//Dockerfile << EOF1
FROM ${ZETA_DOCKER_REG_URL}/minnpmgulppython
RUN apk --update add git && rm -rf /vat/cache/apk/*
RUN git clone ${APP_GIT_URL}/${APP_GIT_USER}/${APP_GIT_REPO}
RUN cd mesos-ui && npm install && gulp build
WORKDIR /mesos-ui
CMD ["python -V"]
EOF1

cd ${APP_ROOT}/${APP}_packages/dockerbuild
sudo docker build -t ${ZETA_DOCKER_REG_URL}/mesosui .
sudo docker push ${ZETA_DOCKER_REG_URL}/mesosui


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
