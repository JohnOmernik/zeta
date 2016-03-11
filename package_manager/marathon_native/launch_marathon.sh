#!/bin/bash

CLUSTERNAME=$(ls /mapr)
# Instance and Version

MESOS_ROLE="prod"
MARATHON_VER="marathon-0.15.2"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

MESOSSECRET="/mapr/$CLUSTERNAME/mesos/kstore/${MESOS_ROLE}/marathon/mesossecret.txt"

# Include Credential File
. /mapr/$CLUSTERNAME/mesos/kstore/prod/marathon/marathon${MESOS_ROLE}.sh



# Some Settings
# The root of the marathons
MARATHON_ROOT="/mapr/$CLUSTERNAME/mesos/${MESOS_ROLE}/marathon/"

# What port this is running on
export MARATHON_HTTP_PORT="$ZETA_MARATHON_PORT"

# The Zookeepers to use
ZKSTR="zk://$ZETA_ZK"

# Get the hostname this instance is running on
HOST=$(hostname -f)

export MARATHON_LOCAL_PORT_MIN="10000" # The Default
export MARATHON_LOCAL_PORT_MAX="19999" # The default is 20000, but we move it down one so 20k can be something different. 

export MARATHON_MASTER="${ZKSTR}/mesosha"
export MARATHON_FRAMEWORK_NAME="marathon${MESOS_ROLE}"
export MARATHON_ZK="${ZKSTR}/${MARATHON_FRAMEWORK_NAME}"
export MESOSPHERE_HTTP_CREDENTIALS="$MARATHONPROD_USER:$MARATHONPROD_PASS"

export MARATHON_MESOS_AUTHENTICATION_PRINCIPAL="zeta${MESOS_ROLE}control"
export MARATHON_MESOS_AUTHENTICATION_SECRET_FILE="$MESOSSECRET"
export MARATHON_MESOS_ROLE="$MESOS_ROLE"

MARATHON_LOCATION="${MARATHON_ROOT}${MARATHON_VER}/"
MARATHON_LOGS="${MARATHON_ROOT}logs/"
MARATHON_LOGOUT="${MARATHON_LOGS}mar_${MESOS_ROLE}_${HOST}.out"
MARATHON_LOGERR="${MARATHON_LOGS}mar_${MESOS_ROLE}_${HOST}.err"


${MARATHON_LOCATION}bin/start > $MARATHON_LOGOUT 2> $MARATHON_LOGERR < /dev/null &

