#!/bin/bash

CLUSTERNAME=$(ls /mapr)

MESOS_ROLE="prod"

APP="mesos-ui"

APP_ID="mesos-ui-prod"

echo "Mesos UI can only be installed to the prod role as mesos-ui-prod"

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

mkdir -p ${APP_HOME}
cp ${APP_ROOT}/start_instance.sh ${APP_HOME}/
chmod +x ${APP_HOME}/start_instance.sh


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
      "image": "${ZETA_DOCKER_REG_URL}/mesos-ui",
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

