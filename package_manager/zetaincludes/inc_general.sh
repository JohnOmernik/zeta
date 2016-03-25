# General Include

re="^[a-z0-9]+$"
if [[ ! "${APP}" =~ $re ]]; then
    echo "App name can only be lowercase letters and numbers"
    exit 1
fi

#### Create upper case APP for use in ENV variables
APP_UP=$(echo $APP | tr '[:lower:]' '[:upper:]')

###############
# Get APP_DIR
# We guess this... should we assume we'll always guess right? I think it's safe but perhaps we should validate

APP_DIR_GUESS=$(echo "$(realpath "$0")"|cut -d"/" -f4)
APP_DIR="${APP_DIR_GUESS}"
echo ""
echo "Using autodetected APP_DIR: ${APP_DIR}"
echo ""

#read -e -p "We autodetected the APP_DIR as ${APP_DIR_GUESS}. Please enter the Application Directory to use for this instance install: " -i $APP_DIR_GUESS APP_DIR


###############
# Get MESOS_ROLE
# The code to ask for this was removed. The idea is this code should only be called from the right directory, therefore we know the roll.

MESOS_ROLE_GUESS=$(echo "$(realpath "$0")"|cut -d"/" -f5)
MESOS_ROLE="${MESOS_ROLE_GUESS}"
echo ""
echo "Using autodetected MESOS_ROLE: ${MESOS_ROLE}"
echo ""
#read -e -p "We autodetected the Mesos Role as ${ROLE_GUESS}. Please enter the Mesos role to use for this instance install: " -i $ROLE_GUESS MESOS_ROLE


#Old code remove at some point
# If mesos role is set by the install_instance.sh script, we don't need to ask the user (some frameworks/installs will only install to one role
#if ["${MESOS_ROLE}" == ""]; then 
#else
#    echo "${APP} has mesos role ${MESOS_ROLE} specified."
#fi

INSTANCE="0"
##############
# GET APP_ID
# If the APP_ID is set by the calling script, we don't need need to ask. Some frameworks demand a certain role setup and will only install there
#

INST_CHECK=$(basename `realpath "$0"`)
if [ "$INST_CHECK" == "install_instance.sh" ]; then
    #The script is install instance
    INSTANCE="1"
    if [ "${APP_ID}" == "" ]; then
        # Getting APP ID from user to install with
        read -e -p "Please enter the instance name to install under Mesos Role: ${MESOS_ROLE}: " -i "${APP}${MESOS_ROLE}" APP_ID
    else
        # Hard coded APP_ID. Using
        echo "${APP} can only be installed with instance name ${APP_ID}"
    fi
else
    # non Install instance call
    APP_ID_GUESS=$(basename $(dirname `realpath "$0"`))
    if [ "$APP_ID_GUESS" == "${APP}" ]; then
        # This is a script, that is not install instance, but running from $APP_ROOT such as get_package.sh, therefore, we don't care about APP_ID
        APP_ID="none"
    else
        # This is instance specific
        read -e -p "We autodetected the instance to be ${APP_ID_GUESS}. Please enter/confirm the instance name: " -i ${APP_ID_GUESS} APP_ID
    fi
fi

if [[ ! "${APP_ID}" =~ $re ]]; then
    echo "App instance name can only be lowercase letters and numbers"
    exit 1
fi

APP_ROOT="/mapr/${CLUSTERNAME}/${APP_DIR}/${MESOS_ROLE}/${APP}"
APP_HOME="${APP_ROOT}/${APP_ID}"

MARATHON_SUBMIT="/home/zetaadm/zetaadmin/marathon${MESOS_ROLE}_submit.sh"

# Source role files for info and secrets
. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh
. /mapr/$CLUSTERNAME/mesos/kstore/$MESOS_ROLE/secret/credential.sh

if [ "${INSTANCE}" == "1" ]; then
    # This is an instance install not a start, therefore let's check directories and/or create them if needed
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
    mkdir -p ${APP_HOME}
else
    if [ "${APP_ID}" != "none" ]; then
        # This is instance specific include, let's ensure the directory exists
        if [ ! -d "${APP_HOME}" ]; then
            echo "${APP_HOME} does not exist. Are you sure your ${APP} instance ${APP_ID} is installed properly?"
            exit 1
        fi
    fi
fi

