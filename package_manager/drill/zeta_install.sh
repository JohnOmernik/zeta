#!/bin/bash


MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

INST_DIR="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/drill"

if [ -d "$INST_DIR" ]; then
    echo "The Installation Directory already exists at $INST_DIR"
    echo "Installation will not continue over that, please rename or delete the existing directory to install fresh"
    exit 1
fi
echo "Making Directories for Drill"
mkdir -p ${INST_DIR}
cp -R ./libjpam ${INST_DIR}/
mkdir -p ${INST_DIR}/extrajars
echo "Place extra jars in this folder including storage plugin jars, or udf jars" > ${INST_DIR}/extrajars/README.txt
mkdir -p ${INST_DIR}/drill_packages
cp get_drill_release.sh ${INST_DIR}/
cp install_drill_instance.sh ${INST_DIR}/

chmod +x ${INST_DIR}/get_drill_release.sh
chmod +x ${INST_DIR}/install_drill_instance.sh


