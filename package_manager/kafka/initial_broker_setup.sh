#!/bin/bash

MESOS_ROLE="prod"
CLUSTERNAME=$(ls /mapr)

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

if [ "${ZETA_KAFKA_ENV}" == "" ]; then
    echo "\${ZETA_KAFKA_ENV} is not set for ${MESOS_ROLE} on $CLUSTERNAME.  This script cannot procede"
    exit 1
fi

if [ ! -d "/mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/kafka/${ZETA_KAFKA_ENV}" ]; then
    echo "/mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/kafka/${ZETA_KAFKA_ENV} does not exist. Are you sure Kafka is installed properly?"
    exit 1
fi
cd /mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/kafka/${ZETA_KAFKA_ENV}
mkdir -p ./brokerdata


CHECK=$(./kafka-mesos.sh broker list)

if [ "$CHECK" == "no brokers" ]; then
    echo "We are good to proceed"
else
    echo "There may be brokers or some other issue. Exiting now."
    echo "Run ./kafka-mesos.sh broker list to learn more"
    echo "Result of previous run: $CHECK"
    exit 1
fi

NUM_NODES=$(echo "$ZETA_NODES"|tr " " "\n"|wc -l)


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
read -e -p "Number of Brokers: " -i "${NUM_NODES}" BROKER_CNT

echo "You want ${BROKER_CNT} broker(s) running, each using ${BROKER_HEAP} mb of heap, ${BROKER_MEM} mb of memory, and ${BROKER_CPU} cpu(s)"



for X in $(seq 1 $BROKER_CNT)
do
    BROKER="broker$X"
    echo "Adding ${BROKER}..."
    VOL="${ZETA_KAFKA_ENV}.${BROKER}"
    MNT="/mesos/${MESOS_ROLE}/kafka/${ZETA_KAFKA_ENV}/brokerdata/$BROKER"
    NFSLOC="/mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/kafka/${ZETA_KAFKA_ENV}/brokerdata/${BROKER}/"
    sudo maprcli volume create -name $VOL -path $MNT -rootdirperms 775 -user zetaadm:fc,a,dump,restore,m,d
    ./kafka-mesos.sh broker add $X
    ./kafka-mesos.sh broker update $X --cpus ${BROKER_CPU} --heap ${BROKER_HEAP} --mem ${BROKER_MEM} --options log.dirs=$NFSLOC,delete.topic.enable=true
done

sudo chown zetaadm:zetaadm ./brokerdata/*
echo "Starting Brokers 1..${BROKER_CNT}"
./kafka-mesos.sh broker start 1..${BROKER_CNT}

