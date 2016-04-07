#!/bin/bash

CLUSTERNAME=$(ls /mapr)

ROLE_GUESS=$(echo "$(realpath "$0")"|cut -d"/" -f5)

APP="schemaregistry"
re="^[a-z0-9]+$"
if [[ ! "${APP}" =~ $re ]]; then
    echo "App name can only be lowercase letters and numbers"
    exit 1
fi

read -e -p "We autodetected the Mesos Role as ${ROLE_GUESS}. Please enter the Mesos role to use for this instance install: " -i $ROLE_GUESS MESOS_ROLE

read -e -p "Please enter the instance name to install under Mesos Role: ${MESOS_ROLE}: " -i "${APP}${MESOS_ROLE}" APP_ID

if [[ ! "${APP_ID}" =~ $re ]]; then
    echo "Instance name can only be lowercase letters and numbers"
    exit 1
fi

read -e -p "What instance name of Kafka will this instance of ${APP} be running against: " -i "kafka${MESOS_ROLE}" APP_KAFKA_ID

if [[ ! "${APP_KAFKA_ID}" =~ $re ]]; then
    echo "Kafka instance name can only be lowercase letters and numbers"
    exit 1
fi


read -e -p "Please enter the service port for ${APP_ID} instance of ${APP}: " -i "48081" APP_PORT


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
export ZETA_SCHEMAREGISTRY_${APP_ID_ENV}_ENV="${APP_ID}"
export ZETA_SCHEMAREGISTRY_${APP_ID_ENV}_HOST="${APP_ID}.\${ZETA_MARATHON_ENV}.\${ZETA_MESOS_DOMAIN}"
export ZETA_SCHEMAREGISTRY_${APP_ID_ENV}_PORT="${APP_PORT}"
EOL1

echo ""
echo "Creating Config"


cat > ${APP_HOME}/conf/schemaregistry.properties << EOF
port=8081

kafkastore.connection.url=${RZK}

host.name=${APP_ID}.${ZETA_MARATHON_ENV}.${ZETA_MESOS_DOMAIN}

schema.registry.zk.namespace=${APP_ID}

kafkastore.topic=_schemas

debug=false

EOF

echo ""
echo "Creating Marathon Script"

cat > ${APP_HOME}/${APP_ID}.marathon << EOF1
{
  "id": "${APP_ID}",
  "cpus": 1,
  "mem": 512,
  "instances": 1,
  "cmd":"/confluent-2.0.1/bin/schema-registry-start /conf/schemaregistry.properties",
  "labels": {
   "PRODUCTION_READY":"True", "CONTAINERIZER":"Docker", "ZETAENV":"${MESOS_ROLE}"
  },
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "${ZETA_DOCKER_REG_URL}/confluentbase",
      "network": "BRIDGE",
      "portMappings": [
        { "containerPort": 8081, "hostPort": 0, "servicePort": ${APP_PORT}, "protocol": "tcp"}
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