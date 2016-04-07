#!/bin/bash

CLUSTERNAME=$(ls /mapr)

APP="kafka"

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh
echo ""
echo "Submitting ${APP_ID} to Marathon then pausing 20 seconds to wait for start and API usability"
echo ""
${MARATHON_SUBMIT} ${APP_HOME}/${APP_ID}.marathon
echo ""
echo ""

sleep 20

cd ${APP_HOME}

APP_CHECK=$(./kafka-mesos.sh broker list)

if [ "${APP_CHECK}" == "no brokers" ]; then
    echo "We are good to proceed in adding brokers"
else
    echo "There may be brokers or some other issue. Exiting now."
    echo "Run ./kafka-mesos.sh broker list to learn more"
    echo ""
    echo "Result of previous run: ${APP_CHECK}"
    echo ""
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
    echo "Exiting"
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
echo "$APP, installed to ${APP_HOME}, has been started via Marathon"
echo "In addition, Brokers have been added and started per the settings provided"
echo ""
echo ""

