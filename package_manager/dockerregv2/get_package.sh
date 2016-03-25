#!/bin/bash

APP="dockerregv2"
CLUSTERNAME=$(ls /mapr)

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh

# We use the already built Docker Registry This could change in the future
sudo docker pull registry:2
sudo docker tag registry:2 zeta/registry:2


echo ""
echo ""
echo "Docker Registry V2 Image pulled and staged on this host for use in Zeta" 
echo "Please install instance now"
echo ""
echo ""

