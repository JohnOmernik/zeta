#!/bin/bash


CLUSTERNAME=$(ls /mapr)

MESOS_ROLE="prod"

. /mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

. /mapr/$CLUSTERNAME/user/zetaadm/cluster.conf

INST_FILE="/mapr/$CLUSTERNAME/user/zetaadm/cluster_inst/zeta_install_mesos.sh"

cat > $INST_FILE << EOL
#!/bin/bash

echo "Downloading: ${MESOS_RPM_ROOT}${MESOS_RPM}"
wget ${MESOS_RPM_ROOT}${MESOS_RPM}

sudo rpm -i ${MESOS_RPM}

rm ${MESOS_RPM}

EOL

chmod +x $INST_FILE



/home/zetaadm/zetaadmin/run_cmd_no_return.sh "$INST_FILE"


NUM_NODES=$(echo "$ZETA_NODES"|tr " " "\n"|wc -l)

NUM_INST=$(/home/zetaadm/zetaadmin/run_cmd.sh "mesos 2>&1"|grep "Available commands"|wc -l)

while [ $NUM_INST -ne $NUM_NODES ]
do
echo "Waiting for the number of nodes installed $NUM_INST to equal the number of total nodes $NUM_NODES in a 5 second loop. (Could Take a while)"
NUM_INST=$(/home/zetaadm/zetaadmin/run_cmd.sh "mesos 2>&1"|grep "Available commands"|wc -l)
sleep 5
done

echo ""
echo ""
echo "Mesos Installed Successfully"
echo "Now Start Mesos"
