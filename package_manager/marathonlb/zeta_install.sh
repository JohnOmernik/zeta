#!/bin/bash

MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

INST_DIR="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/marathonlb"

if [ -d "$INST_DIR" ]; then
    echo "The Installation Directory already exists at $INST_DIR"
    echo "Installation will not continue over that, please rename or delete the existing directory to install fresh"
    exit 1
fi
echo "Making Directories for marathonlb"

mkdir -p $INST_DIR
mkdir -p $INST_DIR/templates

cd $INST_DIR

git clone https://github.com/mesosphere/marathon-lb.git

cd marathon-lb

sudo docker build -t ${ZETA_DOCKER_REG_URL}/marathonlb .
if [ "$?" != 0 ]; then
    echo "Docker Build Failed - Exiting"
    exit 1
fi
sudo docker push ${ZETA_DOCKER_REG_URL}/marathonlb
cd ..

NUM_NODES=$(echo $ZETA_MESOS_AGENTS|tr " " "\n"|wc -l)

cat > $INST_DIR/marathonlb.marathon << EOL
{
  "id": "marathonlb",
  "cpus": 1,
  "mem": 768,
  "instances": ${NUM_NODES},
  "args":["sse", "--marathon", "http://${ZETA_MARATHON_HOST}:${ZETA_MARATHON_PORT}", "--marathon-auth-credential-file", "/marathonlb/creds/marathon.txt", "--group", "*"],
  "constraints": [["hostname", "UNIQUE"]],
  "labels": {
    "PRODUCTION_READY":"True",
    "CONTAINERIZER":"Docker",
    "ZETAENV":"Prod"
  },
"ports": [
    80,
    443,
    9090,
    9091
],
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "${ZETA_DOCKER_REG_URL}/marathonlb",
      "network": "HOST"
    },
   "volumes": [
      { "containerPath": "/marathonlb/templates", "hostPath": "/mapr/$CLUSTERNAME/mesos/${MESOS_ROLE}/marathonlb/templates", "mode": "RO" },
      { "containerPath": "/marathonlb/creds", "hostPath": "/mapr/$CLUSTERNAME/mesos/kstore/${MESOS_ROLE}/marathon", "mode": "RO" }

    ]
  }
}


EOL

echo ""
echo ""
/home/zetaadm/zetaadmin/marathon${MESOS_ROLE}_submit.sh $INST_DIR/marathonlb.marathon
echo ""
echo ""

echo "Package maraton-lb installed"
