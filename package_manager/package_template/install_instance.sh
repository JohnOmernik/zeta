#!/bin/bash
CLUSTERNAME=$(ls /mapr)

APP="%YOURAPPNAME%"

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh


##########
# Note: Template uses Docker Registery as example, you will want to change this
# Get instance Specifc variables from user.
read -e -p "Please enter the port Docker Registry should run on: " -i "5000" APP_PORT
APP_MEM="1024" # This could be read in if you want the user to have control for your app
APP_CPU="1" # This could be read in you want the user to have control for your app

##########
# Do instance specific things: Create Dirs, copy start files, make executable etc
mkdir -p ${APP_HOME}/dockerdata # Change this to a volume create.
cp ${APP_ROOT}/start_instance.sh ${APP_HOME}/
chmod +x ${APP_HOME}/start_instance.sh


##########
# Highly recommended to create instance specific information to an env file for your Mesos Role
# Exampe ENV File for Docker Register V2 into sourced scripts

cat > /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh << EOL1
#!/bin/bash
export ZETA_DOCKER_REG_ID="${APP_ID}"
export ZETA_DOCKER_REG_PORT="${APP_PORT}"
export ZETA_DOCKER_REG_URL="\${ZETA_DOCKER_REG_ID}.\${ZETA_MARATHON_ENV}.\${ZETA_MESOS_DOMAIN}:\${ZETA_DOCKER_REG_PORT}"
EOL1

##########
# After it's written we source itSource the script!
. /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh 


##########
# Get specific instance related things, 
H=$(hostname -f)
echo "To ensure that the image exists for Docker Register V2, we use constraints to pin it to this host, this can be changed at a later time, however you must ensure the image zeta/dockerregv2 exists on the hosts in the constraints"

##########
# Create a marathon file if appropriate in teh ${APP_HOME} directory

cat > ${APP_HOME}/${APP_ID}.marathon << EOF
{
  "id": "${APP_ID}",
  "cpus": ${APP_CPU},
  "mem": ${APP_MEM},
  "instances": 1,
  "constraints": [["hostname", "LIKE", "$H"]],
 "labels": {
   "PRODUCTION_READY":"True", "CONTAINERIZER":"Docker", "ZETAENV":"${MESOS_ROLE}"
  },
  "ports": [],
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "zeta/registry:2",
      "network": "HOST"
    },
    "volumes": [
      { "containerPath": "/var/lib/registry", "hostPath": "${APP_HOME}/dockerdata", "mode": "RW" }
    ]
  }
}
EOF

##########
# Also do customer actions, create config files, setup proper links, etc for each instane here:
#


##########
# Custom Actions like updating all nodes to use this as an insecure registry
# Update Docker on all nodes to use insecure registry - Update for multiple registries
cat > /mapr/$CLUSTERNAME/user/zetaadm/5_update_docker.sh << EOF2
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/docker.conf <<- 'EOF1'
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon -H fd:// --insecure-registry=${ZETA_DOCKER_REG_URL}
EOF1
sudo systemctl daemon-reload
sudo service docker restart
EOF2

chmod +x /mapr/$CLUSTERNAME/user/zetaadm/5_update_docker.sh

echo "Updating Docker Daemon to handle insecure registry"
/home/zetaadm/zetaadmin/run_cmd.sh "/mapr/$CLUSTERNAME/user/zetaadm/5_update_docker.sh"


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
