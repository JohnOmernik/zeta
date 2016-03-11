#!/bin/bash

MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"


. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

INST_DIR="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/marathon"

if [ -d "$INST_DIR" ]; then
    echo "The Installation Directory already exists at $INST_DIR"
    echo "Installation will not continue over that, please rename or delete the existing directory to install fresh"
    exit 1
fi


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

cat > /mapr/$CLUSTERNAME/mesos/kstore/${MESOS_ROLE}/marathon/marathon.sh << EOL
#!/bin/bash
MARATHON_USER="$USER"
MARATHON_PASS="$PASS"
EOL

cat > /mapr/$CLUSTERNAME/mesos/kstore/${MESOS_ROLE}/marathon/marathon.txt << EOL1
$USER:$PASS
EOL1

echo -n $PASS1 > /mapr/$CLUSTERNAME/mesos/kstore/${MESOS_ROLE}/marathon/mesossecret.txt


echo "Marathon_native installed. Start via ~/zetaadmin/startmarathon.sh"
