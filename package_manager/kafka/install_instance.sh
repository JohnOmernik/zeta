#!/bin/bash

CLUSTERNAME=$(ls /mapr)

ROLE_GUESS=$(echo "$(realpath "$0")"|cut -d"/" -f5)

APP="kafka"

APP_UP=$(echo $APP | tr '[:lower:]' '[:upper:]')

read -e -p "We autodetected the Mesos Role as ${ROLE_GUESS}. Please enter the Mesos role to use for this instance install: " -i $ROLE_GUESS MESOS_ROLE

read -e -p "Please enter the instance name to install under Mesos Role: ${MESOS_ROLE}: " -i "${APP}${MESOS_ROLE}" APP_ID

read -e -p "Please enter the $APP Version you wish to install this instance with: " -i "kafka-mesos-0.9.5.0" APP_VER

MARATHON_SUBMIT="/home/zetaadm/zetaadmin/marathon${MESOS_ROLE}_submit.sh"

cd "$(dirname "$0")"

APP_ROOT="/mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/${APP}"
APP_HOME="${APP_ROOT}/${APP_ID}"

# Source role files for info and secrets
. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh
. /mapr/$CLUSTERNAME/mesos/kstore/$MESOS_ROLE/secret/credential.sh

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

PKGS=$(ls ${APP_ROOT}/${APP}_packages/)

if [ "$PKGS" == "" ]; then
    echo "There are no ${APP} packages, please get some first by running get_${APP}_release.sh"
    exit 1
fi
if [ ! -f "${APP_ROOT}/${APP}_packages/${APP_VER}.tgz" ]; then
    echo "The version of ${APP} you want: $APP_VER does not exist in ${APP_ROOT}/${APP}_packages" 
    echo "Please set this up properly per get_${APP}_release.sh"
    exit 1
fi

###############
# $APP Specific
read -e -p "Please enter the port for the kafka-mesos api to run on for ${APP_ID}: " -i 21000 APP_PORT


echo "Making ${APP} instance directories for ${APP_ID}"
mkdir -p ${APP_HOME}
cd ${APP_HOME}

cp ${APP_ROOT}/${APP}_packages/${APP_VER}.tgz ${APP_HOME}/
tar zxf ./${APP_VER}.tgz


cp ${APP_ROOT}/initial_broker_setup.sh ${APP_HOME}/
chmod +x ${APP_HOME}/initial_broker_setup.sh


cat > /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh << EOL1
#!/bin/bash
export ZETA_${APP_UP}_${APP_ID}_ENV="${APP_ID}"
export ZETA_${APP_UP}_${APP_ID}_ZK="\${ZETA_ZK}/${APP_ID}"
export ZETA_${APP_UP}_${APP_ID}_API_PORT="${APP_PORT}"
EOL1

. /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh

# Create config file

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

# Create Marathon File
cat > ${APP_HOME}/${APP_ID}.marathon << EOF2
{
"id": "${APP_ID}",
"instances": 1,
"cmd": "./kafka-mesos.sh scheduler /mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/${APP}/${APP_ID}/kafka-mesos.properties",
"cpus": 1,
"mem": 768,
"ports":[],
"labels": {
    "PRODUCTION_READY":"True",
    "ZETAENV":"${MESOS_ROLE}",
    "CONTAINERIZER":"Mesos"
},
"uris": ["file:///mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/${APP}/${APP_ID}/${APP_VER}.tgz"]
}

EOF2


echo ""
echo "Submitting to Marathon:"
echo ""
$MARATHON_SUBMIT ${APP_HOME}/${APP_ID}.marathon
echo ""
echo ""



echo "${APP} instance ${APP_ID} installed to ${APP_HOME}"
echo " Please go to ${APP_HOME} and run initial_broker_setup.sh  to configure actual Kafka Brokers"
echo ""
echo "> cd ${APP_HOME}"
echo "> ./initial_broker_setup.sh"


