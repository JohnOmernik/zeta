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
export ZETA_KAFKA_API_PORT="21000"
EOL1

. /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP_ID}.sh 

cd $INST_DIR

echo "Getting and building mesos kakfa
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

stty -echo
printf "Please enter the Mesos ${MESOS_ROLE} role principal password: "
read PASS1
echo ""
stty echo

cat > /mapr/$CLUSTERNAME/mesos/${MESOS_ROLE}/kafka/${ZETA_KAFKA_ENV}/kafka-mesos.properties << EOF
# Scheduler options defaults. See `./kafka-mesos.sh help scheduler` for more details
debug=false

framework-name=${ZETA_KAFKA_ENV}

storage=zk:/kafka-mesos


master=zk://${ZETA_MESOS_ZK}

# Need the /kafkaprod as the chroot for zk
zk=${ZETA_KAFKA_ZK}

# Need different port for each framework
api=http://${ZETA_KAFKA_ENV}.${ZETA_MARATHON_ENV}.${ZETA_MESOS_DOMAIN}:${ZETA_KAFKA_API_PORT}

principal=zetaprodcontrol

secret=${PASS1}

EOF

cat > /mapr/$CLUSTERNAME/mesos/${MESOS_ROLE}/kafka/${ZETA_KAFKA_ENV}/${ZETA_KAFKA_ENV}.marathon >> EOF2
{
"id": "${ZETA_KAFKA_ENV}",
"instances": 1,
"cmd": "cd kafka && ./kafka-mesos.sh scheduler /mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/kafka/${ZETA_KAFKA_ENV}/kafka-mesos.properties",
"cpus": 1,
"mem": 256,
"ports":[],
"labels": {
    "PRODUCTION_READY":"True",
    "ZETAENV":"Prod",
    "CONTAINERIZER":"Mesos"
},
"uris": ["file:///mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/kafka/${ZETA_KAFKA_ENV}/kafka-mesos-${KAFKA_MESOS_VER}.tgz"]
}

EOF2


