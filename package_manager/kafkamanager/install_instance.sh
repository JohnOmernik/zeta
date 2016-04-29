#!/bin/bash
CLUSTERNAME=$(ls /mapr)

APP="kafkamanager"

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh


##########
# Note: Template uses Docker Registery as example, you will want to change this
# Get instance Specifc variables from user.
echo "Available Versions:"
ls ${APP_ROOT}/${APP}_packages
echo ""

read -e -p "Please enter the $APP Version you wish to install this instance with: " -i "kafkamanager-1.3.0.7.tgz" APP_TGZ
APP_VER=$(echo -n ${APP_TGZ}|sed "s/\.tgz//")
if [ ! -f "${APP_ROOT}/${APP}_packages/${APP_TGZ}" ]; then
    echo "The version of ${APP} you want: $APP_TGZ does not exist in ${APP_ROOT}/${APP}_packages" 
    echo "Please set this up properly per get_package.sh"
    rm -rf ${APP_HOME}
    exit 1
fi


read -e -p "Please enter the port for ${APP_ID} instance of ${APP} should run on: " -i "49000" APP_PORT

APP_MEM="512" # This could be read in if you want the user to have control for your app
APP_CPU="0.5" # This could be read in you want the user to have control for your app

##########
# Do instance specific things: Create Dirs, copy start files, make executable etc

echo "Moving Install packages. Please wait..."
tar zxf ${APP_ROOT}/${APP}_packages/${APP_TGZ} -C ${APP_HOME}/

cp ${APP_ROOT}/start_instance.sh ${APP_HOME}/

chmod +x ${APP_HOME}/start_instance.sh


##########
# Highly recommended to create instance specific information to an env file for your Mesos Role
cat > /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh << EOL1
#!/bin/bash
export ZETA_KAFKAMANAGER_${APP_ID}_ENV="${APP_ID}"
export ZETA_KAFKAMANAGER_${APP_ID}_HOST="${APP_ID}.\${ZETA_MARATHON_ENV}.\${ZETA_MESOS_DOMAIN}"
export ZETA_KAFKAMANAGER_${APP_ID}_PORT="${APP_PORT}"
EOL1

##########
# After it's written we source itSource the script!
. /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh 



##########
# Create a marathon file if appropriate in teh ${APP_HOME} directory

cat > ${APP_HOME}/${APP_ID}.marathon << EOF
{
  "id": "${APP_ID}",
  "cpus": ${APP_CPU},
  "mem": ${APP_MEM},
  "instances": 1,
  "cmd":"cd /app && bin/kafka-manager",
  "labels": {
   "PRODUCTION_READY":"True", "CONTAINERIZER":"Docker", "ZETAENV":"Prod"
  },
 "env": {
    "ZK_HOSTS": "${ZETA_ZK}"
  },
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "${ZETA_DOCKER_REG_URL}/ubuntu1404openjdk8",
      "network": "BRIDGE",
      "portMappings": [
        { "containerPort": 9000, "hostPort": 0, "servicePort": ${APP_PORT}, "protocol": "tcp"}
      ]
    },
    "volumes": [
      { "containerPath": "/app", "hostPath": "${APP_HOME}/${APP_VER}", "mode": "RW" }
    ]
  }
}
EOF

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
