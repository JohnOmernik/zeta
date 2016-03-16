#!/bin/bash

MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

INST_DIR="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/schema-registry"

if [ -d "$INST_DIR" ]; then
    echo "The Installation Directory already exists at $INST_DIR"
    echo "Installation will not continue over that, please rename or delete the existing directory to install fresh"
    exit 1
fi
if [ ! -d "/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/confluent_base" ]; then
    echo "Cannot install Schema Registry without confluent base package"
    echo "Please install confluent_base first"
    echo "Exiting"
    exit 1
fi


echo "Making Directories for schema-registry"
mkdir -p ${INST_DIR}
cp -R ./conf ${INST_DIR}/
cp install_instance.sh ${INST_DIR}/
chmod +x ${INST_DIR}/install_instance.sh

echo "Schema Registry Base Installed"
echo "To install an individual Schema Registry instance run:"
echo ""
echo "> /mapr/$CLUSTERNAME/mesos/${MESOS_ROLE}/schema-registry/install_instance.sh"
echo ""
