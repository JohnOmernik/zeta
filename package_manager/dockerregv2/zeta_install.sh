#!/bin/bash

MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh
APP_ID="dockerregv2"
APP_PORT="5000"

INST_DIR="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/${APP_ID}"

if [ -d "$INST_DIR" ]; then
    echo "The Installation Directory already exists at $INST_DIR"
    echo "Installation will not continue over that, please rename or delete the existing directory to install fresh"
    exit 1
fi
echo "Making Directories for Docker"
mkdir -p $INST_DIR
mkdir -p $INST_DIR/dockerdata


# WRITE Env File for Docker Register V2 into sourced scripts
cat > /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP_ID}.sh << EOL1
#!/bin/bash
export ZETA_DOCKER_REG_ID="${APP_ID}"
export ZETA_DOCKER_REG_PORT="${APP_PORT}"
export ZETA_DOCKER_REG_URL="\${ZETA_DOCKER_REG_ID}.\${ZETA_MARATHON_ENV}.\${ZETA_MESOS_DOMAIN}:\${ZETA_DOCKER_REG_PORT}"
EOL1
# Source the script!
. /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP_ID}.sh 




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



# Update Docker on all nodes to use insecure registry
cat > /mapr/$CLUSTERNAME/user/zetaadm/5_update_docker.sh << EOF2
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/docker.conf <<- 'EOF1'
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon -H fd:// --insecure-registry=$ZETA_DOCKER_REG_URL
EOF1
sudo systemctl daemon-reload
sudo service docker restart
EOF2
chmod +x /mapr/$CLUSTERNAME/user/zetaadm/5_update_docker.sh

echo "Updating Docker Daemon to handle insecure registry"
/home/zetaadm/zetaadmin/run_cmd.sh "/mapr/$CLUSTERNAME/user/zetaadm/5_update_docker.sh"

echo "Docker Reg Installed"
