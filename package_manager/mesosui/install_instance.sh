#!/bin/bash
CLUSTERNAME=$(ls /mapr)

APP="mesosui"
MESOS_ROLE="prod"
APP_ID="mesosuiprod"

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh


##########
# Note: Template uses Docker Registery as example, you will want to change this
# Get instance Specifc variables from user.

read -e -p "Please enter the service port for ${APP_ID} instance of ${APP}: " -i "45001" APP_PORT
APP_MEM="512" # This could be read in if you want the user to have control for your app
APP_CPU="0.5" # This could be read in you want the user to have control for your app

##########
# Do instance specific things: Create Dirs, copy start files, make executable etc
cp ${APP_ROOT}/start_instance.sh ${APP_HOME}/
chmod +x ${APP_HOME}/start_instance.sh


##########
# Highly recommended to create instance specific information to an env file for your Mesos Role
# Exampe ENV File for Docker Register V2 into sourced scripts

cat > /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh << EOL1
#!/bin/bash
export ZETA_${APP_UP}_ENV="${APP_ID}"
export ZETA_${APP_UP}_HOST="${APP_ID}.\${ZETA_MARATHON_ENV}.\${ZETA_MESOS_DOMAIN}"
export ZETA_${APP_UP}_PORT="${APP_PORT}"
EOL1

##########
# After it's written we source itSource the script!
. /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh 



##########
# Create a marathon file if appropriate in teh ${APP_HOME} directory

cat > ${APP_HOME}/${APP_ID}.marathon << EOF
{
  "id": "${APP_ID}",
  "cmd": "gulp serve",
  "instances": 1,
  "cpus": ${APP_CPU},
  "mem": ${APP_MEM},
  "env": {
    "MESOS_ENDPOINT": "http://${ZETA_MESOS_LEADER}:${ZETA_MESOS_LEADER_PORT}"
  },
 "labels": {
   "PRODUCTION_READY":"True", "CONTAINERIZER":"Docker", "ZETAENV":"${MESOS_ROLE}"
  },
  "healthChecks": [
    {
      "gracePeriodSeconds": 120,
      "intervalSeconds": 15,
      "maxConsecutiveFailures": 10,
      "path": "/",
      "portIndex": 0,
      "protocol": "HTTP",
      "timeoutSeconds": 5
    }
  ],
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "${ZETA_DOCKER_REG_URL}/mesosui",
      "network": "BRIDGE",
      "portMappings": [
        {
          "containerPort": 5000,
          "hostPort": 0,
          "servicePort": ${APP_PORT},
          "protocol": "tcp"
        }
      ]
    }
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
