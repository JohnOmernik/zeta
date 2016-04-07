#!/bin/bash
CLUSTERNAME=$(ls /mapr)

APP="kafka"

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh


##########
# Note: Template uses Docker Registery as example, you will want to change this
# Get instance Specifc variables from user.

echo "Here is the list of available ${APP} packages: please select one to install this instance with"
ls -ls ${APP_ROOT}/${APP}_packages/

read -e -p "Please enter the $APP Version you wish to install this instance with: " -i "kafka-mesos-0.9.5.0.tgz" APP_TGZ
read -e -p "Please enter the port for ${APP} API to run on for ${APP_ID}: " -i "21000" APP_PORT

APP_MEM="768" # This could be read in if you want the user to have control for your app
APP_CPU="1" # This could be read in you want the user to have control for your app

##########
# Do instance specific things: Create Dirs, copy start files, make executable etc
cd ${APP_HOME}
cp ${APP_ROOT}/${APP}_packages/${APP_TGZ} ${APP_HOME}/
tar zxf ./${APP_TGZ}
cp ${APP_ROOT}/start_instance.sh ${APP_HOME}
chmod +x ${APP_HOME}/start_instance.sh


##########
# Highly recommended to create instance specific information to an env file for your Mesos Role
# Exampe ENV File for Docker Register V2 into sourced scripts

cat > /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh << EOL1
#!/bin/bash
export ZETA_${APP_UP}_${APP_ID}_ENV="${APP_ID}"
export ZETA_${APP_UP}_${APP_ID}_ZK="\${ZETA_ZK}/${APP_ID}"
export ZETA_${APP_UP}_${APP_ID}_API_PORT="${APP_PORT}"
EOL1

##########
# After it's written we source it!
. /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh 


##########
# Get specific instance related things, 

cat > ${APP_HOME}/kafka-mesos.properties << EOF
# Scheduler options defaults. See ./kafka-mesos.sh help scheduler for more details
debug=false

framework-name=${APP_ID}

master=zk://${ZETA_MESOS_ZK}

storage=zk:/kafka-mesos

# Need the /kafkaprod as the chroot for zk
zk=${ZETA_ZK}/${APP_ID}

# Need different port for each framework
api=http://${APP_ID}.${ZETA_MARATHON_ENV}.${ZETA_MESOS_DOMAIN}:${APP_PORT}

principal=${ROLE_PRIN}

secret=${ROLE_PASS}

EOF

##########
# Create a marathon file if appropriate in teh ${APP_HOME} directory

cat > ${APP_HOME}/${APP_ID}.marathon << EOF2
{
"id": "${APP_ID}",
"instances": 1,
"cpus": ${APP_CPU},
"mem": ${APP_MEM},
"cmd": "./kafka-mesos.sh scheduler ${APP_HOME}/kafka-mesos.properties",
"ports":[],
"labels": {
    "PRODUCTION_READY":"True",
    "ZETAENV":"${MESOS_ROLE}",
    "CONTAINERIZER":"Mesos"
},
"uris": ["file://${APP_HOME}/${APP_TGZ}"]
}

EOF2

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
