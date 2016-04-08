#!/bin/bash
CLUSTERNAME=$(ls /mapr)

APP="schemaregistry"

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh


##########
# Note: Template uses Docker Registery as example, you will want to change this
# Get instance Specifc variables from user.
read -e -p "What instance name of Kafka will this instance of ${APP} be running against: " -i "kafka${MESOS_ROLE}" APP_KAFKA_ID
read -e -p "Please enter the service port for ${APP_ID} instance of ${APP}: " -i "48081" APP_PORT


APP_MEM="512" # This could be read in if you want the user to have control for your app
APP_CPU="1" # This could be read in you want the user to have control for your app

##########
# Do instance specific things: Create Dirs, copy start files, make executable etc
cp -R ${APP_ROOT}/${APP}_packages/conf ${APP_HOME}/
cp ${APP_ROOT}/start_instance.sh ${APP_HOME}/
chmod +x ${APP_HOME}/start_instance.sh


TZK="ZETA_KAFKA_${APP_KAFKA_ID}_ZK"
eval RZK=\$$TZK

echo ""
echo "Adding env files"

##########
# Highly recommended to create instance specific information to an env file for your Mesos Role
# Exampe ENV File for Docker Register V2 into sourced scripts

cat > /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh << EOL1
#!/bin/bash
export ZETA_SCHEMAREGISTRY_${APP_ID}_ENV="${APP_ID}"
export ZETA_SCHEMAREGISTRY_${APP_ID}_HOST="${APP_ID}.\${ZETA_MARATHON_ENV}.\${ZETA_MESOS_DOMAIN}"
export ZETA_SCHEMAREGISTRY_${APP_ID}_PORT="${APP_PORT}"
EOL1

##########
# After it's written we source itSource the script!
. /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh 


echo ""
echo "Creating Config"


cat > ${APP_HOME}/conf/schemaregistry.properties << EOF4
port=8081

kafkastore.connection.url=${RZK}

host.name=${APP_ID}.${ZETA_MARATHON_ENV}.${ZETA_MESOS_DOMAIN}

schema.registry.zk.namespace=${APP_ID}

kafkastore.topic=_schemas

debug=false

EOF4


echo ""
##########
# Create a marathon file if appropriate in teh ${APP_HOME} directory

cat > ${APP_HOME}/${APP_ID}.marathon << EOF1
{
  "id": "${APP_ID}",
  "cpus": ${APP_CPU},
  "mem": ${APP_MEM},
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


##########
# Provide instructions for next steps
echo ""
echo ""
echo "$APP instance ${APP_ID} installed at ${APP_HOME} and ready to go"
echo "To start please run: "
echo ""
echo "> ${APP_HOME}/start_instance.sh"
echo ""
echo ""
