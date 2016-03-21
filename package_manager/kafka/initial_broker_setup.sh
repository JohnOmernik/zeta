#!/bin/bash

CLUSTERNAME=$(ls /mapr)

ROLE_GUESS=$(pwd|cut -d"/" -f5)

APP_ID_GUESS=$(basename `pwd`)

APP="kafka"

APP_UP=$(echo $APP | tr '[:lower:]' '[:upper:]')

read -e -p "We autodetected the Mesos Role as ${ROLE_GUESS}. Please enter the Mesos role to use for this instance install: " -i $ROLE_GUESS MESOS_ROLE
APP_ROOT="/mapr/$CLUSTERNAME/mesos/${MESOS_ROLE}/${APP}"

read -e -p "We autodetected the instance for broker setup to be ${APP_ID_GUESS}. Please enter the instance name for broker setup: " -i ${APP_ID_GUESS} APP_ID
APP_HOME="${APP_ROOT}/${APP_ID}"


. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

if [ ! -d "${APP_HOME}" ]; then
    echo "${APP_HOME} does not exist. Are you sure your ${APP} instance ${APP_ID} is installed properly?"
    exit 1
fi

cd ${APP_HOME}



CHECK=$(./kafka-mesos.sh broker list)

if [ "$CHECK" == "no brokers" ]; then
    echo "We are good to proceed"
else
    echo "There may be brokers or some other issue. Exiting now."
    echo "Run ./kafka-mesos.sh broker list to learn more"
    echo "Result of previous run: ${CHECK}"
    exit 1
fi


NUM_NODES=$(echo "${ZETA_NODES}"|tr " " "\n"|wc -l)


echo "What setting should we use for heap space for each broker (in MB)?"
read -e -p "Heap Space: " -i "1024" BROKER_HEAP
echo ""
echo "How much memory per broker (separate from heap) should we use (in MB)?"
read -e -p "Broker Memory: " -i "2048" BROKER_MEM
echo ""
echo "How many CPU vCores should we use per broker?"
read -e -p "Broker CPU(s): " -i "1" BROKER_CPU
echo "" 
echo "There are ${NUM_NODES} nodes in this cluster: How many kafka brokers do you want running?"
read -e -p "Number of Brokers: " -i "${NUM_NODES}" BROKER_COUNT

echo "You want ${BROKER_COUNT} broker(s) running, each using ${BROKER_HEAP} mb of heap, ${BROKER_MEM} mb of memory, and ${BROKER_CPU} cpu(s)"
echo ""
read -e -p "Is this summary correct? (Y/N): " -i "Y" ANS

if [ "${ANS}" != "Y" ]; then
    echo "You did not answer Y so something is not right"
    exit 1
fi

mkdir -p ./brokerdata


for X in $(seq 1 $BROKER_COUNT)
do
    BROKER="broker${X}"
    echo "Adding ${BROKER}..."
    VOL="${APP_ID}.${BROKER}"
    MNT="/mesos/${MESOS_ROLE}/${APP}/${APP_ID}/brokerdata/${BROKER}"
    NFSLOC="${APP_HOME}/brokerdata/${BROKER}/"
    sudo maprcli volume create -name $VOL -path $MNT -rootdirperms 775 -user zetaadm:fc,a,dump,restore,m,d
    ./kafka-mesos.sh broker add $X
    ./kafka-mesos.sh broker update $X --cpus ${BROKER_CPU} --heap ${BROKER_HEAP} --mem ${BROKER_MEM} --options log.dirs=${NFSLOC},delete.topic.enable=true
done

sudo chown  zetaadm:zetaadm ./brokerdata/*
echo "Starting Brokers 1..${BROKER_COUNT}"
./kafka-mesos.sh broker start 1..${BROKER_COUNT}

echo ""
echo ""
echo "Brokers should be started and ready to use"
echo ""
echo ""
