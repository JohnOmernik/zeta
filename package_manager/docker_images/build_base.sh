#!/bin/bash


MESOS_ROLE="prod"
CLUSTERNAME=$(ls /mapr)

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

cd "$(dirname "$0")"

REG="${ZETA_DOCKER_REG_URL}"


IMAGES="minopenjdk7 minjdk8 minpython2 rsyncbase minopenjre7 minopenjdk7mvn333 minjdk8mvn333"

for IMAGE in $IMAGES; do
    echo "Running on $IMAGE"
    cd $IMAGE
    sudo docker build -t ${REG}/${IMAGE} .
    sudo docker push ${REG}/${IMAGE}
    cd ..
done
