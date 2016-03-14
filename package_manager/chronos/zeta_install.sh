#!/bin/bash

MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

INST_DIR="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/chronos"

if [ -d "$INST_DIR" ]; then
    echo "The Installation Directory already exists at $INST_DIR"
    echo "Installation will not continue over that, please rename or delete the existing directory to install fresh"
    exit 1
fi
echo "Making Directories for Chronos"
mkdir -p $INST_DIR
mkdir -p ${INST_DIR}/chronosprod
mkdir -p ${INST_DIR}/dockerbuild


printf "Please enter the Chronos framework http username: "
read USER
echo ""
stty -echo
printf "Please enter the Chronos framework http password: "
read PASS
echo ""
stty echo
stty -echo
printf "Please enter the Mesos ${MESOS_ROLE} role principal password: "
read PASS1
echo ""
stty echo


mkdir -p /mapr/$CLUSTERNAME/mesos/kstore/${MESOS_ROLE}/chronos

cat > /mapr/$CLUSTERNAME/mesos/kstore/${MESOS_ROLE}/chronos/chronos.sh << EOL
#!/bin/bash
CHRONOS_USER="$USER"
CHRONOS_PASS="$PASS"
EOL

echo -n $PASS1 > /mapr/$CLUSTERNAME/mesos/kstore/${MESOS_ROLE}/chronos/mesossecret.txt




cp ./Dockerfile ${INST_DIR}/dockerbuild/
cp ./run_chronos.sh ${INST_DIR}/dockerbuild/

cd ${INST_DIR}/dockerbuild
sudo docker build -t ${ZETA_DOCKER_REG_URL}/chronos .

sudo docker push ${ZETA_DOCKER_REG_URL}/chronos

cat > ${INST_DIR}/chronosprod/chronosprod.marathon << EOF
{
  "id": "${ZETA_CHRONOS_ENV}",
  "cpus": 1,
  "mem": 768,
  "instances": 1,
  "cmd":"/chronos/bin/run_chronos.sh",
  "env": {
    "CHRONOS_HOME": "/chronos",
    "CHRONOS_HEAP": "512m",
    "CHRONOS_DEBUG": "0",
    "CHRONOS_MASTER": "zk://${ZETA_MESOS_ZK}",
    "CHRONOS_ZK_HOSTS": "${ZETA_ZK}",
    "CHRONOS_ZK_PATH": "/${ZETA_CHRONOS_ENV}/state",
    "CHRONOS_HTTP_PORT": "${ZETA_CHRONOS_PORT}",
    "CHRONOS_MESOS_ROLE": "*",
    "CHRONOS_MESOS_FRAMEWORK_NAME": "${ZETA_CHRONOS_ENV}",
    "CHRONOS_CLUSTER_NAME": "${CLUSTERNAME}",
    "CHRONOS_MESOS_AUTHENTICATION_PRINCIPAL": "zeta${MESOS_ROLE}control",
    "CHRONOS_MESOS_AUTHENTICATION_SECRET_FILE": "/auth/mesossecret.txt",
    "MESOSPHERE_HTTP_CREDENTIALS": "${USER}:${PASS}"
  },
  "labels": {
    "PRODUCTION_READY":"True",
    "CONTAINERIZER":"Docker",
    "ZETAENV":"prod"
  },
  "ports":[],
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "${ZETA_DOCKER_REG_URL}/chronos",
      "network": "HOST"
    },
  "volumes": [
      { "containerPath": "/auth", "hostPath": "/mapr/$CLUSTERNAME/mesos/kstore/${MESOS_ROLE}/chronos", "mode": "RO" }
    ]
  }
}

EOF
echo ""
echo ""
/home/zetaadm/zetaadmin/marathon${MESOS_ROLE}_submit.sh $INST_DIR/chronosprod/chronosprod.marathon
echo ""
echo ""

echo "Package chronos installed"

