#!/bin/bash


CLUSTERNAME=$(ls /mapr)

MESOS_ROLE="prod"

. /mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

. /mapr/$CLUSTERNAME/user/zetaadm/cluster_inst/cluster.conf


INST_FILE="/mapr/$CLUSTERNAME/user/zetaadm/cluster_inst/zeta_install_mesos.sh"





cat > $INST_FILE << EOL
#!/bin/bash
CLUSTERNAME=\$(ls /mapr)
. /mapr/\$CLUSTERNAME/user/zetaadm/cluster_inst/cluster.conf

DIST_CHK=\$(lsb_release -a)
UB_CHK=\$(echo \$DIST_CHK|grep Ubuntu)
RH_CHK=\$(echo \$DIST_CHK|grep RedHat)
CO_CHK=\$(echo \$DIST_CHK|grep CentOS)

if [ "\$UB_CHK" != "" ]; then
    INST_TYPE="ubuntu"
    DISTRO=\$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    CODENAME=\$(lsb_release -cs)
elif [ "\$RH_CHK" != "" ] || [ "\$CO_CHK" != "" ]; then
    INST_TYPE="rh_centos"
else
    echo "Unknown lsb_release -a version at this time only ubuntu, centos, and redhat is supported"
    echo \$DIST_CHK
    exit 1
fi

if [ "\$INST_TYPE" == "ubuntu" ]; then
    if [ "\$CODENAME" == "trusty" ]; then
        UVER="1404"
    elif [ "\$CODENAME" == "vivid" ]; then
        UVER="1504"
    else
        echo "Ubuntu Detected but version not matched"
        exit 1
    fi
    MESOS_DEB="${MESOS_DEB_pre}\${UVER}${MESOS_DEB_post}"
    MESOS_DEB_ROOT="${MESOS_DEB_ROOT}"
    wget \${MESOS_DEB_ROOT}\${MESOS_DEB}
    sudo dpkg -i \${MESOS_DEB}
    rm \${MESOS_DEB}
elif [ "\$INST_TYPE" == "rh_centos" ]; then
    MESOS_RPM_ROOT="${MESOS_RPM_ROOT}"
    MESOS_RPM="${MESOS_RPM}"
    wget \${MESOS_RPM_ROOT}\${MESOS_RPM}
    sudo rpm -i \${MESOS_RPM}
    rm \${MESOS_RPM}
else
    echo "Error"
    exit 1
fi

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
