#!/bin/bash

MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

INST_DIR="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/${ZETA_DOCKER_REG_ID}"

if [ -d "$INST_DIR" ]; then
    echo "The Installation Directory already exists at $INST_DIR"
    echo "Installation will not continue over that, please rename or delete the existing directory to install fresh"
    exit 1
fi
echo "Making Directories for Docker"
mkdir -p $INST_DIR
mkdir -p $INST_DIR/dockerdata

# We use the already built Docker Registry This could change in the future
sudo docker pull registry:2
sudo docker tag registry:2 zeta/${ZETA_DOCKER_REG_ID}
H=$(hostname -f)

echo "To ensure that the image exists for Docker Register V2, we use constraints to pin it to this host, this can be changed at a later time, however you must ensure the image zeta/dockerregv2 exists on the hosts in the constraints"


cat > $INST_DIR/${ZETA_DOCKER_REG_ID}.marathon << EOF
{
  "id": "${ZETA_DOCKER_REG_ID}",
  "cpus": 1,
  "mem": 1024,
  "instances": 1,
  "constraints": [["hostname", "LIKE", "$H"]],
 "labels": {
   "PRODUCTION_READY":"True", "CONTAINERIZER":"Docker", "ZETAENV":"Prod"
  },
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "zeta/${ZETA_DOCKER_REG_ID}",
      "network": "HOST"
    },
    "volumes": [
      { "containerPath": "/var/lib/registry", "hostPath": "/mapr/$CLUSTERNAME/mesos/prod/${ZETA_DOCKER_REG_ID}/dockerdata", "mode": "RW" }
    ]
  }
}
EOF
echo "Note: dockerregv2 uses host networking and the exposed port of 5000 due to the need to have the registry reachable before marathon-lb is up"
echo ""
echo ""
/home/zetaadm/zetaadmin/marathon${MESOS_ROLE}_submit.sh $INST_DIR/${ZETA_DOCKER_REG_ID}.marathon


echo ""
echo ""

echo "Docker Reg Installed"
