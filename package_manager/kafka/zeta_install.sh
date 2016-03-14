#!/bin/bash


echo "This package is not ready for install: exiting"
exit 1


MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

INST_DIR="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/kafka"

if [ -d "$INST_DIR" ]; then
    echo "The Installation Directory already exists at $INST_DIR"
    echo "Installation will not continue over that, please rename or delete the existing directory to install fresh"
    exit 1
fi
echo "Making Directories for kafka"
mkdir -p $INST_DIR
mkdir -p ${INST_DIR}/${ZETA_KAFKA_ENV}

APP_ID="kafkaprod"

cat > /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP_ID}.sh << EOL1
#!/bin/bash
export ZETA_KAFKA_ENV="${APP_IP}"
export ZETA_KAFKA_ZK="\${ZETA_ZK}/\${ZETA_KAFKA_ENV}"
EOL1



cd $INST_DIR
echo "Getting and building mesos kakfa

git clone https://github.com/mesos/kafka

cd kafka

./gradlew jar
