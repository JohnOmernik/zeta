#!/bin/bash

MESOS_ROLE="prod"
UPPER_MESOS_ROLE=$(echo ${MESOS_ROLE}|tr '[a-z]' '[A-Z]')

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"


. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

INST_DIR="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/marathon"

INST_VER="0.15.2"

mkdir -p $INST_DIR
mkdir -p ${INST_DIR}/logs
cp ./launch_marathon.sh $INST_DIR
chmod +x $INST_DIR/launch_marathon.sh

wget http://downloads.mesosphere.com/marathon/v${INST_VER}/marathon-${INST_VER}.tgz
cp marathon-${INST_VER}.tgz $INST_DIR
cd $INST_DIR
tar zxf marathon-${INST_VER}.tgz



printf "Please enter the Marathon framework http username: "
read USER
echo ""
stty -echo
printf "Please enter the Marathon framework http password: "
read PASS
echo ""
stty echo

stty -echo
printf "Please enter the Mesos ${MESOS_ROLE} role principal password: "
read PASS1
echo ""
stty echo


mkdir -p /mapr/$CLUSTERNAME/mesos/kstore/${MESOS_ROLE}/marathon

cat > /mapr/$CLUSTERNAME/mesos/kstore/${MESOS_ROLE}/marathon/marathon${MESOS_ROLE}.sh << EOL
#!/bin/bash
MARATHON${UPPER_MESOS_ROLE}_USER="$USER"
MARATHON${UPPER_MESOS_ROLE}_PASS="$PASS"
EOL

cat > /mapr/$CLUSTERNAME/mesos/kstore/${MESOS_ROLE}/marathon/marathon${MESOS_ROLE}.txt << EOL1
$USER:$PASS
EOL1

echo -n $PASS1 > /mapr/$CLUSTERNAME/mesos/kstore/${MESOS_ROLE}/marathon/mesossecret.txt

