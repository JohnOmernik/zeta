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



./kafka-mesos.sh broker add 0,1,2,3

./kafka-mesos.sh broker update 0 --options log.dirs=/mapr/brewpot/data/kafka/kafkaprod/broker0/,delete.topic.enable=true
./kafka-mesos.sh broker update 1 --options log.dirs=/mapr/brewpot/data/kafka/kafkaprod/broker1/,delete.topic.enable=true
./kafka-mesos.sh broker update 2 --options log.dirs=/mapr/brewpot/data/kafka/kafkaprod/broker2/,delete.topic.enable=true
./kafka-mesos.sh broker update 3 --options log.dirs=/mapr/brewpot/data/kafka/kafkaprod/broker3/,delete.topic.enable=true

./kafka-mesos.sh broker update 0,1,2,3 --options delete.topic.enable=true

./kafka-mesos.sh broker update 0,1,2,3 --cpus 1 --heap 512 --mem 2048
