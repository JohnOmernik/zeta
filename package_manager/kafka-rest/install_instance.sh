#!/bin/bash

MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

BASE_DIR="/mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/kafka-rest"

cd ${BASE_DIR}

echo "What should this kafka-rest instance name be? It will be appended to kafka-rest- to get the marathon app id"
read -e -p "Kafka-Rest name: " -i "$MESOS_ROLE" INST_NAME
echo ""

echo "What service port should we use? (Note, if this service port is in use, the marathon submit will fail)"
read -e -p "Service Port: " -i "48081" INST_PORT
echo ""

FULL_INST_NAME="kafka-rest-${INST_NAME}"

if [ -d "${BASE_DIR}/${FULL_INST_NAME}" ]; then
    echo "This instance name has alredy been taken. No Further actions taken"
    exit 1
fi


mkdir -p ${BASE_DIR}/${FULL_INST_NAME}
mkdir -p ${BASE_DIR}/${FULL_INST_NAME}/conf
cp ./conf/* ${BASE_DIR}/${FULL_INST_NAME}/conf/
cat > ${BASE_DIR}/${FULL_INST_NAME}/conf/kafka-rest.properties << EOF
schema.registry.url=http://${FULL_INST_NAME}.${ZETA_MARATHON_ENV}.${ZETA_MESOS_DOMAIN}:${INST_PORT}
zookeeper.connect=${ZETA_KAFKA_ZK}
host.name=${FULL_INST_NAME}.${ZETA_MARATHON_ENV}.${ZETA_MESOS_DOMAIN}
port=${INST_PORT}

EOF

cat >${BASE_DIR}/${FULL_INST_NAME}/${FULL_INST_NAME}.marathon << EOF1
{
  "id": "${FULL_INST_NAME}",
  "cpus": 1,
  "mem": 768,
  "instances": 1,
  "cmd":"/conf/runrest.sh && /confluent-2.0.1/bin/kafka-rest-start /conf_new/kafka-rest.properties",
  "labels": {
   "PRODUCTION_READY":"True", "CONTAINERIZER":"Docker", "ZETAENV":"Prod"
  },
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "${ZETA_DOCKER_REG_URL}/confluent_base",
      "network": "BRIDGE",
      "portMappings": [
        { "containerPort": ${INST_PORT}, "hostPort": 0, "servicePort": ${INST_PORT}, "protocol": "tcp"}
      ]
    },
  "volumes": [
      {
        "containerPath": "/conf",
        "hostPath": "/mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/kafka-rest/${FULL_INST_NAME}/conf",
        "mode": "RO"
      }
    ]
  }
}
EOF1

/home/zetaadm/zetaadmin/marathonprod_submit.sh ${BASE_DIR}/${FULL_INST_NAME}/${FULL_INST_NAME}.marathon
