#!/bin/bash

CLUSTERNAME=$(ls /mapr)

MESOS_ROLE="prod"

APP="mesosui"

re="^[a-z0-9]+$"
if [[ ! "${APP}" =~ $re ]]; then
    echo "App name can only be lowercase letters and numbers"
    exit 1
fi

APP_ID="mesosuiprod"

if [[ ! "${APP_ID}" =~ $re ]]; then
    echo "App name can only be lowercase letters and numbers"
    exit 1
fi


APP_UP=$(echo $APP | tr '[:lower:]' '[:upper:]')

echo "Mesos UI can only be installed to the prod role as mesosuiprod"

read -e -p "Please enter the service port for ${APP_ID} instance of ${APP}: " -i "45001" APP_PORT

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

mkdir -p ${APP_HOME}
cp ${APP_ROOT}/start_instance.sh ${APP_HOME}/
chmod +x ${APP_HOME}/start_instance.sh

APP_ID_ENV=$(echo ${APP_UP}|tr "-" "_")

cat > /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh << EOL1
#!/bin/bash
export ZETA_${APP_UP}_ENV="${APP_ID}"
export ZETA_${APP_UP}_HOST="${APP_ID}.\${ZETA_MARATHON_ENV}.\${ZETA_MESOS_DOMAIN}"
export ZETA_${APP_UP}_PORT="${APP_PORT}"
EOL1

. /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh 

cat > ${APP_HOME}/${APP_ID}.marathon << EOF
{
  "id": "${APP_ID}",
  "cmd": "gulp serve",
  "instances": 1,
  "cpus": 1,
  "mem": 512,
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


echo ""
echo ""
echo "${APP} instance ${APP_ID} installed to ${MESOS_ROLE}"
echo "To start your instance run: "
echo "> ${APP_HOME}/start_instance.sh"
echo ""
echo ""

