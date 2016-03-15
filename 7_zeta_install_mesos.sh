#!/bin/bash

CLUSTERNAME=$(ls /mapr)
. /mapr/$CLUSTERNAME/user/zetaadm/cluster.conf

INST_FILE="/mapr/$CLUSTERNAME/user/zetaadm/7_install_mesos.sh"

cat > $INST_FILE << EOL
#!/bin/bash

echo "Downloading: ${MESOS_RPM_ROOT}${MESOS_RPM}"
wget ${MESOS_RPM_ROOT}${MESOS_RPM}

sudo rpm -i ${MESOS_RPM}

rm ${MESOS_RPM}

EOL

chmod +x $INST_FILE



/home/zetaadm/zetaadmin/run_cmd_no_return.sh "$INST_FILE"

echo "Run: "
echo ""
echo "/home/zetaadm/zetaadmin/run_cmd.sh \"hostname; mesos\""
echo ""
echo "All nodes should return without error before preceeding"
