#!/bin/bash

CLUSTERNAME=$(ls /mapr)

ROLE_GUESS=$(echo "$(realpath "$0")"|cut -d"/" -f5)

APP="mesosui"
re="^[a-z0-9]+$"
if [[ ! "${APP}" =~ $re ]]; then
    echo "App name can only be lowercase letters and numbers"
    exit 1
fi


read -e -p "We autodetected the Mesos Role as ${ROLE_GUESS}. Please enter the Mesos role to use for this ${APP} instance install: " -i $ROLE_GUESS MESOS_ROLE

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

APP_ROOT="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/${APP}"
WORK_DIR="/tmp"

echo "Preparing Temp Area to build ${APP}"
sudo rm -rf $WORK_DIR/${APP}
cd $WORK_DIR
mkdir ${APP}

cd ${WORK_DIR}/${APP}
APP_URL_ROOT="https://github.com/Capgemini/"
APP_URL_FILE="mesos-ui.git"

cat > ./Dockerfile << EOF1
FROM ${ZETA_DOCKER_REG_URL}/minnpmgulppython
RUN apk --update add git && rm -rf /vat/cache/apk/*
RUN git clone ${APP_URL_ROOT}${APP_URL_FILE}
RUN cd mesos-ui && npm install && gulp build
WORKDIR /mesos-ui
CMD ["python -V"]
EOF1

sudo docker build -t ${ZETA_DOCKER_REG_URL}/mesosui .
sudo docker push ${ZETA_DOCKER_REG_URL}/mesosui

echo ""
echo ""
echo "Docker file built and pushed to registry for ${APP}"
echo "Now install the instance file with:"
echo "> ${APP_ROOT}/install_instance.sh"
echo ""
echo ""

