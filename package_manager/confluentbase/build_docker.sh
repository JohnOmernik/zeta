#!/bin/bash

CLUSTERNAME=$(ls /mapr)

ROLE_GUESS=$(echo "$(realpath "$0")"|cut -d"/" -f5)

APP="confluentbase"

re="^[a-z0-9]+$"
if [[ ! "${APP}" =~ $re ]]; then
    echo "App name can only be lowercase letters and numbers"
    exit 1
fi


read -e -p "We autodetected the Mesos Role as ${ROLE_GUESS}. Please enter the Mesos role to use for this instance install: " -i $ROLE_GUESS MESOS_ROLE

APP_ROOT="/mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/${APP}"

# Source role files for info and secrets
. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh


cd ${APP_ROOT}/dockerbuild

APP_URL_ROOT="http://packages.confluent.io/archive/2.0/"
APP_URL_FILE="confluent-2.0.1-2.11.7.tar.gz"


wget ${APP_URL_ROOT}${APP_URL_FILE}


cat > ${APP_ROOT}/dockerbuild/Dockerfile << EOF
FROM ${ZETA_DOCKER_REG_URL}/minjdk8

ADD ${APP_URL_FILE} /

CMD ["java -version"]
EOF

sudo docker build -t ${ZETA_DOCKER_REG_URL}/${APP} .
sudo docker push ${ZETA_DOCKER_REG_URL}/${APP}

echo ""
echo ""
echo "${APP} image build with ${APP_URL_FILE} and pushed to ${ZETA_DOCKER_REG_URL}"
echo ""
echo ""
