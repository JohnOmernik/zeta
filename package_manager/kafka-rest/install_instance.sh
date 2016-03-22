#!/bin/bash

CLUSTERNAME=$(ls /mapr)

ROLE_GUESS=$(pwd|cut -d"/" -f5)

APP="kafka-rest"

APP_UP=$(echo $APP | tr '[:lower:]' '[:upper:]')

read -e -p "We autodetected the Mesos Role as ${ROLE_GUESS}. Please enter the Mesos role to use for this instance install: " -i $ROLE_GUESS MESOS_ROLE

read -e -p "Please enter the instance name to install under Mesos Role: ${MESOS_ROLE}: " -i "${APP}-${MESOS_ROLE}" APP_ID

read -e -p "What instance name of Kafka will this instance of ${APP} be running against: " -i "kafka${MESOS_ROLE}" APP_KAFKA_ID

read -e -p "What instance name of schema-registry will this instance of ${APP} be running against: " -i "schema-registry-${MESOS_ROLE}" APP_SCHEMA_REG

read -e -p "Please enter the service port for ${APP_ID} instance of ${APP}: " -i "48101" APP_PORT


cd "$(dirname "$0")"

APP_ROOT="/mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/${APP}"
APP_HOME="${APP_ROOT}/${APP_ID}"

# Source role files for info and secrets
. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

if [ -d "$APP_HOME" ]; then
    echo "The Installation Directory already exists at $APP_HOME"
    echo "Installation will not continue over that, please rename or delete the existing directory to install fresh"
    exit 1
fi

if [ -f "/mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh" ]; then
    echo "env script for $APP_ID exists. Will not proceed until you handle that"
    echo "/mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh"
    exit 1
fi

APP_SCHEMA_REG_ENV=$(echo ${APP_SCHEMA_REG}|tr "-" "_")


THOST="ZETA_SCHEMAREGISTRY_${APP_SCHEMA_REG_ENV}_HOST"
TPORT="ZETA_SCHEMAREGISTRY_${APP_SCHEMA_REG_ENV}_PORT"

eval RHOST=\$$THOST
eval RPORT=\$$TPORT


TZK="ZETA_KAFKA_${APP_KAFKA_ID}_ZK"
eval RZK=\$$TZK

echo "Making Instance Directories"
mkdir -p ${APP_HOME}
mkdir -p ${APP_HOME}/conf
cp ${APP_ROOT}/conf/* ${APP_HOME}/conf/
cp ${APP_ROOT}/start_instance.sh ${APP_HOME}
chmod +x ${APP_HOME}/start_instance.sh

echo ""
echo "Adding env files"

APP_ID_ENV=$(echo ${APP_ID}|tr "-" "_")

cat > /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh << EOL1
#!/bin/bash
export ZETA_KAFKAREST_${APP_ID_ENV}_ENV="${APP_ID}"
export ZETA_KAFKAREST_${APP_ID_ENV}_HOST="${APP_ID}.\${ZETA_MARATHON_ENV}.\${ZETA_MESOS_DOMAIN}"
export ZETA_KAFKAREST_${APP_ID_ENV}_PORT="${APP_PORT}"
EOL1

echo ""
echo "Creating Config"

cat > ${APP_HOME}/conf/kafka-rest.properties << EOF
schema.registry.url=http://${RHOST}:${RPORT}
zookeeper.connect=${RZK}
host.name=${APP_ID}.${ZETA_MARATHON_ENV}.${ZETA_MESOS_DOMAIN}
port=${APP_PORT}
EOF

echo ""
echo "Creating Marathon Script"

cat > ${APP_HOME}/${APP_ID}.marathon << EOF1
{
  "id": "${APP_ID}",
  "cpus": 1,
  "mem": 768,
  "instances": 1,
  "cmd":"/conf/runrest.sh && /confluent-2.0.1/bin/kafka-rest-start /conf_new/kafka-rest.properties",
  "labels": {
   "PRODUCTION_READY":"True", "CONTAINERIZER":"Docker", "ZETAENV":"${MESOS_ROLE}"
  },
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "${ZETA_DOCKER_REG_URL}/confluent_base",
      "network": "BRIDGE",
      "portMappings": [
        { "containerPort": ${APP_PORT}, "hostPort": 0, "servicePort": ${APP_PORT}, "protocol": "tcp"}
      ]
    },
  "volumes": [
      {
        "containerPath": "/conf",
        "hostPath": "${APP_HOME}/conf",
        "mode": "RO"
      }
    ]
  }
}
EOF1

echo ""
echo ""
echo "Your ${APP} instance: ${APP_ID} is installed."
echo "Go to ${APP_HOME} and run start_instance.sh to start your instance"
echo ""
echo ""
