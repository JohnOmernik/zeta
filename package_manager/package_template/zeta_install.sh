#!/bin/bash

APP="%YOURAPPNAME%"  # App names must be all lowercase and only contain letters or numbers

re="^[a-z0-9]+$"
if [[ ! "${APP}" =~ $re ]]; then
    echo "App name can only be lowercase letters and numbers"
    exit 1
fi

read -e -p "Please enter the Mesos Role you wish to install ${APP} to: " -i "prod" MESOS_ROLE

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

APP_ROOT="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/${APP}"
##########
# Check if install has already occured
if [ -d "${APP_ROOT}" ]; then
    echo "The Installation Directory already exists at ${APP_ROOT}"
    echo "Installation will not continue over that, please rename or delete the existing directory to install fresh"
    exit 1
fi

##########
# Check here for any other packages that need to be installed. Exit and notifiy if the pre-reqs aren't met

##########
# Make directories
echo "Making Directories for ${APP}"
mkdir -p ${APP_ROOT}
# Create any more directories your package needs

##########
# Move scripts to the install location (${APP_ROOT})
cp install_instance.sh  ${APP_ROOT}/
# Copy any more scripts your package needs

##########
# Make only those scripts executable that are needed for the next step. (i.e. install_instance should exe, but start instance should only be made exe by install instance etc)
chmod +x ${APP_ROOT}/install_instance.sh

##########
# Provide instructions for the next step including where things were installed

echo ""
echo ""
echo "${APP} Package installed to ${MESOS_ROLE}. Next steps:"
echo ""
echo "1. Make some ${APP} tgzs to run in Zeta with ${APP_ROOT}/get_${APP}_release.sh"
echo "2. Install a specific ${APP} instance with ${APP_ROOT}/install_instance.sh"
echo ""
echo ""

