#!/bin/bash

MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

INST_DIR="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/drill"

if [ -d "$INST_DIR" ]; then
    echo "The Installation Directory already exists at $INST_DIR"
    echo "Installation will not continue over that, please rename or delete the existing directory to install fresh"
    exit 1
fi
echo "Making Directories for Drill"
mkdir -p $INST_DIR

APP_ID="drillprod"

cat > /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP_ID}.sh << EOL1
#!/bin/bash
export ZETA_DRILL_ENV="${APP_IP}"
export ZETA_DRILL_WEB_HOST="\${ZETA_DRILL_ENV}.\${ZETA_MARATHON_ENV}.\${ZETA_MESOS_DOMAIN}"
export ZETA_DRILL_WEB_PORT="20000"
export ZETA_DRILL_USER_PORT="20001"
export ZETA_DRILL_BIT_PORT="20002"
EOL1



