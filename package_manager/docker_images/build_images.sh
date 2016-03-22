#!/bin/bash

CLUSTERNAME=$(ls /mapr)

ROLE_GUESS=$(pwd|cut -d"/" -f5)

APP="docker_images"

read -e -p "We autodetected the Mesos Role as ${ROLE_GUESS}. Please enter the Mesos role to use for this instance install: " -i $ROLE_GUESS MESOS_ROLE

APP_ROOT="/mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/${APP}"

# Source role files for info and secrets
. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

REG="${ZETA_DOCKER_REG_URL}"

cd ${APP_ROOT}

IMAGES="minopenjdk7 minjdk8 minpython2 rsyncbase minopenjre7 minopenjdk7mvn333 minjdk8mvn333 minnpm minnpmgulppython"

for IMAGE in $IMAGES; do
    echo "Running on $IMAGE"
    cd $IMAGE
    sudo docker build -t ${REG}/${IMAGE} .
    sudo docker push ${REG}/${IMAGE}
    cd ..
done

echo ""
echo ""
echo "Docker Base Images were built and pushed to registry at ${REG}"
echo "You can always do it again by running ${APP_ROOT}/build_images.sh"
echo ""

