#!/bin/bash

APP="confluentbase"
CLUSTERNAME=$(ls /mapr)

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh

WORK_DIR="/tmp" # Used for creating tmp information
rm -rf ${WORK_DIR}/${APP}
cd ${WORK_DIR}
mkdir -p ${WORK_DIR}/${APP}
cd ${WORK_DIR}/${APP}

##############
# Provide example URLS Downloads

APP_URL_ROOT="http://packages.confluent.io/archive/2.0/"
APP_URL_FILE="confluent-2.0.1-2.11.7.tar.gz"


wget ${APP_URL_ROOT}${APP_URL_FILE}
mv ${APP_URL_FILE} ${APP_ROOT}/${APP}_packages/dockerbuild/

cat > ${APP_ROOT}/${APP}_packages/dockerbuild/Dockerfile << EOF
FROM ${ZETA_DOCKER_REG_URL}/minjdk8

ADD ${APP_URL_FILE} /

CMD ["java -version"]
EOF

cd ${APP_ROOT}/${APP}_packages/dockerbuild

sudo docker build -t ${ZETA_DOCKER_REG_URL}/${APP} .
sudo docker push ${ZETA_DOCKER_REG_URL}/${APP}

mv ${APP_ROOT}/${APP}_packages/dockerbuild/${APP_URL_FILE} ${APP_ROOT}/${APP}_packages/

##############
# Provide next step instuctions
echo ""
echo ""
echo "${APP} is installed"
echo "Since ${APP} is now downloaded, built, and pushed to local docker repo. No further action for this package is needed"
echo ""
echo ""

##############
# Clean up Work Dir
cd ${WORK_DIR}
rm -rf ${WORK_DIR}/${APP}
