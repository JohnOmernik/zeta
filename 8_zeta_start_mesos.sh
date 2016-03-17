#!/bin/bash


MESOS_ROLE="prod"
. ./cluster.conf
CLUSTERNAME=$(ls /mapr)
. /mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh
cd /home/zetaadm/zetaadmin
./startmesos.sh 1

echo ""
echo ""
echo "Mesos should be started now." 
echo "To access the Mesos UI, you will need to either open ports in your firewall (or Cloud Provider Security Template) or connect to edge proxy using SSH Socks Forwarding. "
echo "To use the Socks forwarding, open another ssh connection from your client machine (outside the cluster) as such:"
echo ""
echo "> ssh -i ${PRVKEY} -D8091 ${IUSER}@${IHOST}"
echo ""
echo "Note -D8091, in this case we are using port 8091 as the localhost proxy to the cluster."
echo "Then in your webbrowser (say Firefox) go to proxy settings and set a Socks V5 Proxy to be localhost:8091.  In Firefox there is an option to use local DNS. Check that"
echo "This will now allow you to connect"
echo ""
echo "However, since you just started Mesos, you don't have Marathon or DNS available, you will need to connect to nodes via IP"
echo "To use sane names for your cluster, run the #9 Script, install Marathon-native, start it, then install mesos-dns." 
echo "If you already established your ssh proxy session, you'll need to exit and then restablish it"
echo "Then you will be able to access the Mesos UI via: http://${ZETA_MESOS_LEADER}:${MESOS_LEADER_PORT}"
echo ""
echo ""
