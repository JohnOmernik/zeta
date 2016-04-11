#!/bin/bash

CLUSTERNAME=$(ls /mapr)

INST_FILE="/mapr/$CLUSTERNAME/user/zetaadm/cluster_inst/zeta_install_role.sh"

. /mapr/${CLUSTERNAME}/user/zetaadm/cluster.conf

cat > $INST_FILE << EOALL
#!/bin/bash

MESOS_ROLE=\$1
MESOS_PRIN=\$2
MESOS_PASS=\$3

CLUSTERNAME=\$(ls /mapr)

ZETA_ADM="/mapr/\$CLUSTERNAME/user/zetaadm/zetaadmin"

if [ -d "/mapr/\${CLUSTERNAME}/mesos/kstore/\${MESOS_ROLE}" ]; then
    echo "Role \${MESOS_ROLE} already exists, will not install"
    exit 1
fi

# This is the ENV File for the cluster.
ZETA_ENV_FILE="/mapr/\${CLUSTERNAME}/mesos/kstore/env/zeta_\${CLUSTERNAME}_\${MESOS_ROLE}.sh"

if [ -f "\$ZETA_ENV_FILE" ]; then
    echo "Zeta Role File already exists, will not proceed"
    echo "File: \$ZETA_ENV_FILE"
    exit 1
fi

##### OK Check some Passwords

if [ "\$MESOS_PRIN" == "" ]; then
    echo "Role principle not provided. Please provide them now"
    echo "Please enter a role principal name: "
    read MESOS_PRIN
    echo  "Please enter the role principal password: "
    read MESOS_PASS
fi

USR="zetasvc\${MESOS_ROLE}data"

echo "Adding User \$USR"
\$ZETA_ADM/addzetauser.sh \$USR


echo "Creating Role Base Directories"
ROOT_DIRS="apps data etl mesos"
for R in \$ROOT_DIRS
do
    echo "Creating Role Directory for \${MESOS_ROLE} in \${R}"
    VOL="\${R}\${MESOS_ROLE}"
    MNT="/\${R}/\${MESOS_ROLE}"
    GRP="zeta\${MESOS_ROLE}\${R}"
    \$ZETA_ADM/addzetagroup.sh \$GRP
    \$ZETA_ADM/addtozetagroup.sh \$USR \$GRP

    sudo maprcli volume create -name \$VOL -path \$MNT -rootdirperms 775 -user zetaadm:fc,a,dump,restore,m,d
    sudo chmod 775 /mapr/\${CLUSTERNAME}\${MNT}
    sudo chown zetaadm:\$GRP /mapr/\${CLUSTERNAME}\${MNT}
done

#########
# This is the secrets location for frame works

DIR="/mapr/\$CLUSTERNAME/mesos/kstore/\${MESOS_ROLE}"
sudo mkdir -p \$DIR
sudo chown zetaadm:zeta\${MESOS_ROLE}mesos \$DIR
sudo chmod 2750 \$DIR

DIR="/mapr/\$CLUSTERNAME/mesos/kstore/\${MESOS_ROLE}/secret"
sudo mkdir -p \$DIR
sudo chown zetaadm:zeta\${MESOS_ROLE}mesos \$DIR
sudo chmod 2750 \$DIR

echo "\$MESOS_PRIN \$MESOS_PASS" > \$DIR/credential.txt

cat > \${DIR}/credential.sh << EOF10
#!/bin/bash
export ROLE_PRIN="\$MESOS_PRIN"
export ROLE_PASS="\$MESOS_PASS"
EOF10
echo "Updating Mesos ACLs - If Mesos is running you will have to do a rolling restart of masters after this"
# Add Role credentials to mesos ACLs
INS="\ \ \ \ {\"principal\": \"\${MESOS_PRIN}\",\"secret\": \"\${MESOS_PASS}\"},"
sed -i "/\"credentials\": \[/a \$INS" /mapr/\$CLUSTERNAME/mesos/kstore/mesosconf/secrets/allcredentials.json

if [ "\$MESOS_ROLE" != "prod" ]; then
    # Now we need to add to the ACLs WE don't for Prod because it's special
    INS="\ \ \ \ { \"principals\": { \"values\": [\"zeta\${MESOS_ROLE}control\"] }, \"roles\": { \"values\": [\"\${MESOS_ROLE}\"] } },"
    sed -i "/\"register_frameworks\": \[/a \$INS" /mapr/\$CLUSTERNAME/mesos/kstore/mesosconf/mesos_acls.json


    INS="\ \ \ \ { \"principals\": { \"values\": [\"zeta\${MESOS_ROLE}control\"] }, \"users\": { \"values\": [\"zetasvc\${MESOS_ROLE}data\"]} },"
    sed -i "/\"run_tasks\": \[/a \$INS" /mapr/\$CLUSTERNAME/mesos/kstore/mesosconf/mesos_acls.json


    INS="\ \ \ \ { \"principals\": { \"values\": [\"zeta\${MESOS_ROLE}control\"] },\"framework_principals\": { \"values\": \"zeta\${MESOS_ROLE}control\" } },"
    sed -i "/\"shutdown_frameworks\": \[/a \$INS" /mapr/\$CLUSTERNAME/mesos/kstore/mesosconf/mesos_acls.json
fi



echo "Building Zeta ENV File for \$MESOS_ROLE"

if [ "\${MESOS_ROLE}" == "prod" ]; then
    MARPORT="20080"
    CHRPORT="20180"
else
    echo "Not Prod, need ports for marathon and chronos"
    echo "Please enter port for marathon (prod is 20080, do not use that): "
    read MARPORT
    echo ""
    echo "Please enter port for chronos (prod is 20180, do not use that): "
    read CHRPORT
fi


if [ "\${MESOS_ROLE}" == "prod" ]; then
   MARATHON_MASTERS="\\\${ZETA_MESOS_MASTERS}"
else
   MARATHON_MASTERS="MARATHON"
fi


cat > \$ZETA_ENV_FILE << EOL3
#!/bin/bash
CLUSTERNAME=\\\$(ls /mapr)
# Source Master Zeta ENV File
. /mapr/\\\$CLUSTERNAME/mesos/kstore/env/master_env.sh
# START GLOBAL ENV Variables for Zeta Environment

export ZETA_MARATHON_MASTERS="\${MARATHON_MASTERS}"
export ZETA_MARATHON_ENV="marathon\${MESOS_ROLE}"
export ZETA_MARATHON_HOST="\\\${ZETA_MARATHON_ENV}.\\\${ZETA_MESOS_DOMAIN}"
export ZETA_MARATHON_PORT="\$MARPORT"

export ZETA_CHRONOS_ENV="chronos\${MESOS_ROLE}"
export ZETA_CHRONOS_HOST="\\\${ZETA_CHRONOS_ENV}.\\\${ZETA_MARATHON_ENV}.\\\${ZETA_MESOS_DOMAIN}"
export ZETA_CHRONOS_PORT="\$CHRPORT"

# Source env_prod
for SRC in /mapr/\$CLUSTERNAME/mesos/kstore/env/env_\${MESOS_ROLE}/*.sh; do
   . \\\$SRC
done

if [ "\\\$1" == "1" ]; then
    env|grep -P "^ZETA_"
fi

EOL3

chmod +x \$ZETA_ENV_FILE


# ENV Added Sripts
DIR="/mapr/\$CLUSTERNAME/mesos/kstore/env/env_\${MESOS_ROLE}"
sudo mkdir -p \$DIR
sudo chown zetaadm:zetaadm \$DIR
sudo chmod 775 \$DIR

#Create a dummy script in the env_prod directory so that file not found errors don't appear when sourcing main file
cat > /mapr/\$CLUSTERNAME/mesos/kstore/env/env_\${MESOS_ROLE}/env_\${MESOS_ROLE}.sh << EOL5
#!/bin/bash
# Basic script to keep file not found errors from happening 
EOL5

echo "Role \${MESOS_ROLE} Installed"

EOALL


chmod +x $INST_FILE
$INST_FILE prod $MESOS_PROD_PRNCPL $MESOS_PROD_PASS
$INST_FILE dev $MESOS_DEV_PRNCPL $MESOS_DEV_PASS

echo "Role Install Script and roles prod and dev installed. Now run script 5_"

