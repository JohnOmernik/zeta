# Include file for zeta_install.sh


re="^[a-z0-9]+$"

### Test for APP
if [[ ! "${APP}" =~ $re ]]; then
    echo "App name can only be lowercase letters and numbers"
    exit 1
fi

### Test for APP_DIR

if [ "${APP_DIR}" == "" ]; then
    # No suggested APP_DIR defaulting to mesos
    APP_DIR="mesos"
fi
read -e -p "Please enter the Appplication path dir to install ${APP} Suggested: " -i "${APP_DIR}" APP_DIR

if [[ ! "${APP_DIR}" =~ $re ]]; then
    echo "App Directory name can only be lowercase letters and numbers"
    exit 1
fi

if [ ! -d "/mapr/${CLUSTERNAME}/${APP_DIR}" ]; then
    echo "The selected Application path does not exist - exiting"
    echo "Directory does not exist: /mapr/${CLUSTERNAME}/${APP_DIR}"
    exit 1
fi

### Test for MESOS_ROLE

# If mesos role is set by the zeta_install.sh script, we don't need to ask the user (some frameworks/installs will only install to one role
if [ "${MESOS_ROLE}" == "" ]; then 
    read -e -p "Please enter the Mesos Role you wish to install ${APP} to: " -i "prod" MESOS_ROLE
else
    echo "${APP} has mesos role ${MESOS_ROLE} specified."
fi

if [ ! -d "/mapr/${CLUSTERNAME}/${APP_DIR}/${MESOS_ROLE}" ]; then 
    echo "The selected MESOS_ROLE (${MESOS_ROLE}) does not exist in ${APP_DIR} - exiting"
    echo "Directory does not exist: /mapr/${CLUSTERNAME}/${APP_DIR}/${MESOS_ROLE}"
    exit 1
fi


. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

APP_ROOT="/mapr/$CLUSTERNAME/${APP_DIR}/${MESOS_ROLE}/${APP}"

if [ -d "${APP_ROOT}" ]; then
    echo "The Installation Directory already exists at ${APP_ROOT}"
    echo "Installation will not continue over that, please rename or delete the existing directory to install fresh"
    exit 1
fi

echo "Making Directories for ${APP}"

mkdir -p ${APP_ROOT}

