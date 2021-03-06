#!/bin/bash

MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)

. /mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

INSTALLER="/home/zetaadm/zetaadmin/install_zeta_pkg.sh"


echo "Available Packages"
$INSTALLER
echo ""
echo "Prior to adhoc package install, we recommend these packages in this order:"
echo ""
echo "Install prod Native Marathon"
echo "$INSTALLER zeta_inst_marathonnative.tgz"
echo ""
echo "Start Marathon"
echo "/home/zetaadm/zetaadmin/startmarathon.sh"
echo ""
echo "Install Mesos DNS"
echo "$INSTALLER zeta_inst_mesosdns.tgz"
echo ""
echo "Install a docker registry"
echo "$INSTALLER zeta_inst_dockerregv2.tgz"
echo ""
echo "Install marathonlb for load balancing/service discovery"
echo "$INSTALLER zeta_inst_marathonlb.tgz"
echo ""
echo "Install chronos for cluster wide cron"
echo "$INSTALLER zeta_inst_chronos.tgz"
echo ""

