#!/bin/bash

###########
# Basic Variables

CLUSTERNAME=$(ls /mapr) # Get your cluster name

APP="mesosui" # You do want to set this here so change this variable

MESOS_ROLE="prod" # Force installation into Prod

APP_DIR="mesos"  # Most things fall into mesos. This is a suggestion, it will still prompt the user 


###########
# Put in checks here for other packages you need to have installed. 
#
#

###########
# Load the install include file
. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_zeta_install.sh

if [ ! -d "/mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/dockerimages" ]; then
    echo "The Package docker images must be installed prior to installing ${APP}"
    echo "Exiting"
    rm -rf ${APP_ROOT}
    exit 1
fi


###########
# CD to the temp location where this script is run from 
cd "$(dirname "$0")"
mkdir -p ${APP_ROOT}/${APP}_packages
###########
# Copy files to their proper locations:. ${APP_ROOT} is set in the includes

cp ./install_instance.sh ${APP_ROOT}/
cp ./get_package.sh ${APP_ROOT}/
cp ./start_instance.sh ${APP_ROOT}/

###########
# Only make executable the next steps. 
chmod +x ${APP_ROOT}/install_instance.sh
chmod +x ${APP_ROOT}/get_package.sh

###########
# Provide instructions you can/change this per install. 
echo ""
echo ""
echo "${APP} installed to role ${MESOS_ROLE} at ${APP_ROOT}"
echo "Next steps, get/build/compile what will be run by executing:"
echo ""
echo "${APP_ROOT}/get_package.sh"
echo ""
echo "Then you can install individual instances by running:"
echo ""
echo "> ${APP_ROOT}/install_instance.sh"
echo ""
echo ""





