#!/bin/bash

MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh


INST_DIR="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/docker_images"

if [ -d "$INST_DIR" ]; then
    echo "The Installation Directory already exists at $INST_DIR"
    echo "Installation will not continue over that, please rename or delete the existing directory to install fresh"
    exit 1
fi
echo "Making Directories for kafka"
mkdir -p ${INST_DIR}

cp -R ./* ${INST_DIR}/
rm ${INST_DIR}/zeta_install.sh



REG="${ZETA_DOCKER_REG_URL}"

cd ${INST_DIR}

IMAGES="minopenjdk7 minjdk8 minpython2 rsyncbase minopenjre7 minopenjdk7mvn333 minjdk8mvn333"

for IMAGE in $IMAGES; do
    echo "Running on $IMAGE"
    cd $IMAGE
    sudo docker build -t ${REG}/${IMAGE} .
    sudo docker push ${REG}/${IMAGE}
    cd ..
done


echo "Docker Base Images were built and pushed"
echo "You can always do it again by running ${INST_DIR}/build_base.sh"
