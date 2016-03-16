#!/bin/bash

MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

. /mapr/$CLUSTERNAME/mesos/kstore/$MESOS_ROLE/secret/credential.sh

APP_ID="kafkaprod"
INST_DIR="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/confluent_base"

if [ -d "$INST_DIR" ]; then
    echo "The Installation Directory already exists at $INST_DIR"
    echo "Installation will not continue over that, please rename or delete the existing directory to install fresh"
    exit 1
fi
echo "Making Directories for confluent_base"
mkdir -p ${INST_DIR}
mkdir -p ${INST_DIR}/dockerbuild

cp build.sh ${INST_DIR}/

chmod +x ${INST_DIR}/build.sh
cd ${INST_DIR}
${INST_DIR}/build.sh

echo ""
echo ""
echo "Confluent Base Docker Image Created and pushed to Docker Registry. Confluent Packages such as Schema Registry and Kafka-REST will now build successfully"
echo "To rebuild just execute ${INST_DIR}/build.sh"
echo ""
echo ""
