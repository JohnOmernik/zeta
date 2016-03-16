#!/bin/bash

MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

BASE_DIR="/mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/schema-registry"

cd ${BASE_DIR}




echo "What should this schema-registry instance name be? It will be appeneded to schema-registry- to get the marathon app id"
read -e -p "Schema-Registry name: " -i "$MESOS_ROLE" INST_NAME
echo ""

echo "What service port should we use? (Note, if this service port is in use, the marathon submit will fail)"
read -e -p "Service Port: " -i "48081" INST_PORT
echo ""

FULL_INST_NAME="schema-registry-${INST_NAME}"

if [ -d "${BASE_DIR}/${FULL_INST_NAME}" ]; then
    echo "This instance name has alredy been taken. No Further actions taken"
    exit 1
fi


mkdir -p ${BASE_DIR}/${FULL_INST_NAME}
mkdir -p ${BASE_DIR}/${FULL_INST_NAME}/conf
cp ./conf/* ${BASE_DIR}/${FULL_INST_NAME}/conf/
cat > ${BASE_DIR}/${FULL_INST_NAME}/conf/schema-registry.properties << EOF
port=8081

kafkastore.connection.url=${ZETA_KAFKA_ZK}

host.name=${FULL_INST_NAME}.${ZETA_MARATHON_ENV}.${ZETA_MESOS_DOMAIN}

schema.registry.zk.namespace=${FULL_INST_NAME}

kafkastore.topic=_schemas

debug=false

EOF

cat > ${BASE_DIR}/${FULL_INST_NAME}/${FULL_INST_NAME}.marathon << EOF1
{
  "id": "${FULL_INST_NAME}",
  "cpus": 1,
  "mem": 512,
  "instances": 1,
  "cmd":"/confluent-2.0.1/bin/schema-registry-start /conf/schema-registry.properties",
  "labels": {
   "PRODUCTION_READY":"True", "CONTAINERIZER":"Docker", "ZETAENV":"Prod"
  },
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "${ZETA_DOCKER_REG_URL}/confluent_base",
      "network": "BRIDGE",
      "portMappings": [
        { "containerPort": 8081, "hostPort": 0, "servicePort": ${INST_PORT}, "protocol": "tcp"}
      ]
    },
  "volumes": [
      {
        "containerPath": "/conf",
        "hostPath": "/mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/schema-registry/${FULL_INST_NAME}/conf",
        "mode": "RO"
      }
    ]
  }
}
EOF1



/home/zetaadm/zetaadmin/marathonprod_submit.sh ${BASE_DIR}/${FULL_INST_NAME}/${FULL_INST_NAME}.marathon
