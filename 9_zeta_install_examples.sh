#!/bin/bash

MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)

. /mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

INSTALLER="/home/zetaadm/zetaadmin/install_zeta_pkg.sh"


echo "Available Packages"
$INSTALLER
echo ""
echo "Install prod Native Marathon"
echo "$INSTALLER zeta_inst_marathon_native.tgz"
echo ""
echo "Start Marathon"
echo "/home/zetaadm/zetaadmin/startmarathon.sh"
echo ""
echo "Install Mesos DNS"
echo "$INSTALLER zeta_inst_mesos-dns.tgz"
echo ""
echo "Install a docker register"
echo $INSTALLER zeta_inst_dockerregv2.tgz"
echo ""

