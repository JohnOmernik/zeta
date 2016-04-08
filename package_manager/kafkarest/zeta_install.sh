#!/bin/bash

###########
# Basic Variables

CLUSTERNAME=$(ls /mapr) # Get your cluster name

APP="kafkarest" # You do want to set this here so change this variable

APP_DIR="mesos"  # Most things fall into mesos. This is a suggestion, it will still prompt the user 


###########
# Put in checks here for other packages you need to have installed. 
#
#

###########
# Load the install include file
. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_zeta_install.sh

###########
# CD to the temp location where this script is run from
cd "$(dirname "$0")"


if [ ! -d "/mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/confluentbase" ]; then
    echo "confluentbase is required for ${APP}"
    echo "exiting"
    rm -rf ${APP_ROOT}
    exit 1
fi

if [ ! -d "/mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/kafka" ]; then
    echo "kafka is required for ${APP}"
    echo "exiting"
    rm -rf ${APP_ROOT}
    exit 1
fi

if [ ! -d "/mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/schemaregistry" ]; then
    echo "schemaregistry is required for ${APP}"
    echo "exiting"
    rm -rf ${APP_ROOT}
    exit 1
fi



###########
# Copy files to their proper locations:. ${APP_ROOT} is set in the includes
mkdir -p ${APP_ROOT}/${APP}_packages

cp -R ./conf ${APP_ROOT}/${APP}_packages/

cp ./install_instance.sh ${APP_ROOT}/
cp ./start_instance.sh ${APP_ROOT}/

###########
# Only make executable the next steps. 
chmod +x ${APP_ROOT}/install_instance.sh

###########
# Provide instructions you can/change this per install. 
echo ""
echo ""
echo "${APP} installed to role ${MESOS_ROLE} at ${APP_ROOT}"
echo ""
echo "Now you can install individual instances by running:"
echo ""
echo "> ${APP_ROOT}/install_instance.sh"
echo ""
echo ""





