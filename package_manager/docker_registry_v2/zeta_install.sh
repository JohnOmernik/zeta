#!/bin/bash

MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

INST_DIR="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/dockerregv2"

if [ -d "$INST_DIR" ]; then
    echo "The Installation Directory already exists at $INST_DIR"
    echo "Installation will not continue over that, please rename or delete the existing directory to install fresh"
    exit 1
fi
echo "Making Directories for Docker"
mkdir -p $INST_DIR
mkdir -p $INST_DIR/dockerdata

# We use the already built Docker Registry
sudo docker pull registry:2
sudo docker tag zeta/dockerregv2 registry:2
H=$(hostname -f)

echo "To ensure that the image exists for Docker Register V2, we use constraints to pin it to this host, this can be changed at a later time, however you must ensure the image zeta/dockerregv2 exists on the hosts in the constraints"


cat > $INST_DIR/dockerregv2.marathon << EOF
{
  "id": "dockerregv2",
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
      "image": "zeta/dockerregv2",
      "network": "BRIDGE",
      "portMappings": [
        { "containerPort": 5000, "hostPort": 0, "servicePort": 5002, "protocol": "tcp" }
      ]
    },
    "volumes": [
      { "containerPath": "/var/lib/registry", "hostPath": "/mapr/$CLUSTERNAME/mesos/prod/dockerregv2/dockerdata", "mode": "RW" }
    ]
  }
}
EOF
