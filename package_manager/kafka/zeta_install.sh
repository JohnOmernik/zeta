#!/bin/bash

MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

. /mapr/$CLUSTERNAME/mesos/kstore/$MESOS_ROLE/secret/credential.sh

APP_ID="kafkaprod"
APP_PORT="21000"
INST_DIR="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/kafka"

if [ -d "$INST_DIR" ]; then
    echo "The Installation Directory already exists at $INST_DIR"
    echo "Installation will not continue over that, please rename or delete the existing directory to install fresh"
    exit 1
fi
echo "Making Directories for kafka"
mkdir -p ${INST_DIR}
mkdir -p ${INST_DIR}/${APP_ID}


cat > /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/kafka_${APP_ID}.sh << EOL1
#!/bin/bash
export ZETA_KAFKA_${APP_ID}_ENV="${APP_ID}"
export ZETA_KAFKA_${APP_ID}_ZK="\${ZETA_ZK}/${APP_ID}"
export ZETA_KAFKA_${APP_ID}_API_PORT="${APP_PORT}"
EOL1

. /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/kafka_${APP_ID}.sh 

cp initial_broker_setup.sh ${INST_DIR}/${APP_ID}/
chmod +x ${INST_DIR}/${APP_ID}/initial_broker_setup.sh

cd $INST_DIR

echo "Getting and building mesos kakfa"
git clone https://github.com/mesos/kafka
cd kafka

echo "Built without the tests due to bug in mesos-kafka issue # 184"
./gradlew jar -x test

KAFKA_MESOS_VER=$(ls -1|grep jar|sed "s/kafka-mesos-//g"|sed "s/.jar//g")

cp kafka-mesos-*.jar ../${APP_ID}/
cp kafka-mesos.sh ../${APP_ID}/
cd ..
cd ${APP_ID}

wget https://archive.apache.org/dist/kafka/0.9.0.1/kafka_2.10-0.9.0.1.tgz

tar zcf kafka-mesos-${KAFKA_MESOS_VER}.tgz ./*

tar zxf kafka_2.10-0.9.0.1.tgz

cat > /mapr/$CLUSTERNAME/mesos/${MESOS_ROLE}/kafka/${APP_ID}/kafka-mesos.properties << EOF
# Scheduler options defaults. See ./kafka-mesos.sh help scheduler for more details
debug=false

framework-name=${APP_ID}

master=zk://${ZETA_MESOS_ZK}

storage=zk:/kafka-mesos

# Need the /kafkaprod as the chroot for zk
zk=${ZETA_ZK}/${APP_ID}

# Need different port for each framework
api=http://${APP_ID}.${ZETA_MARATHON_ENV}.${ZETA_MESOS_DOMAIN}:${APP_PORT}

principal=${ROLE_PRIN}

secret=${ROLE_PASS}

EOF

cat > /mapr/$CLUSTERNAME/mesos/${MESOS_ROLE}/kafka/${APP_ID}/${APP_ID}.marathon << EOF2
{
"id": "${APP_ID}",
"instances": 1,
"cmd": "./kafka-mesos.sh scheduler /mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/kafka/${APP_ID}/kafka-mesos.properties",
"cpus": 1,
"mem": 768,
"ports":[${APP_PORT}],
"labels": {
    "PRODUCTION_READY":"True",
    "ZETAENV":"Prod",
    "CONTAINERIZER":"Mesos"
},
"uris": ["file:///mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/kafka/${APP_ID}/kafka-mesos-${KAFKA_MESOS_VER}.tgz"]
}

EOF2

echo ""
echo ""
/home/zetaadm/zetaadmin/marathon${MESOS_ROLE}_submit.sh ${INST_DIR}/${APP_ID}/${APP_ID}.marathon
echo ""
echo ""

echo "Kafka Installed: Please go to ${INST_DIR}/${APP_ID} and run initial_broker_setup.sh  to configure actual Kafka Brokers"
echo ""
echo "> cd ${INST_DIR}/${APP_ID}"
echo "> ./initial_broker_setup.sh"
