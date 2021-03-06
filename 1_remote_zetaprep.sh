#!/bin/bash

# Change to the root dir
cd "$(dirname "$0")"
# Make sure you edit cluster.conf prior to running this. 
. ./cluster.conf

##########################
# Get a node list from the connecting node, save it to nodes.list
# Run the Package Manager for a clean copy of packages
# Upload the private key to the node
# Upload the runcmd.sh, nodes.list, and cluster.conf, install_scripts.list files to the cluster
# Upload zeta_packages.tgz to the cluster
# Upload the numbered scripts to the cluster
# Provide instructions on the next step



##########################
SSHHOST="${IUSER}@${IHOST}"

# Since we use these a lot I short cut them into variables
SCPCMD="scp -i ${PRVKEY}"
SSHCMD="ssh -i ${PRVKEY} -t ${SSHHOST}"

#########################
# Get a list of IP addresses of local nodes
NODES=$($SSHCMD -o StrictHostKeyChecking=no "sudo maprcli node list -columns ip")

if [ "$NODES" == "" ]; then
    echo "Did not get list of nodes from remote cluster"
    echo "Result of NODES: $NODES"
    echo "Cannot proceed without NODES"
    exit 1
fi
rm -f nodes.list
touch nodes.list
for n in $NODES
do
    g=$(echo $n|grep -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
    if [ "$g" != "" ]; then
        echo $g|cut -d"," -f1  >> ./nodes.list
    fi
done
cat nodes.list

NODE_CNT=$(cat ./nodes.list|wc -l)
if [ ! "$NODE_CNT" -gt 2 ]; then
   echo "Node Count is not greater than 3"
   echo "Node Count: $NODE_CNT"
    exit 1
fi


##########################
# Build Packages
echo "Running the Packager to ensure we have the latest packages"
cd package_manager
./package_tgzs.sh
cd ..

#####################
# Copy private key
$SCPCMD ${PRVKEY} ${SSHHOST}:/home/${IUSER}/.ssh/id_rsa
# Copy next step scripts and helpers
$SCPCMD runcmd.sh ${SSHHOST}:/home/${IUSER}/
$SCPCMD nodes.list ${SSHHOST}:/home/${IUSER}/
$SCPCMD install_scripts.list ${SSHHOST}:/home/${IUSER}/
$SCPCMD cluster.conf ${SSHHOST}:/home/${IUSER}/
$SCPCMD zeta_packages.tgz ${SSHHOST}:/home/${IUSER}/
$SCPCMD 2_zeta_user_prep.sh ${SSHHOST}:/home/${IUSER}/

SCRIPTS=`cat ./install_scripts.list`
for SCRIPT in $SCRIPTS ; do
    $SCPCMD $SCRIPT ${SSHHOST}:/home/${IUSER}/
done

$SSHCMD "chmod +x runcmd.sh"
$SSHCMD "chmod +x 2_zeta_user_prep.sh"

echo "Cluster Scripts have been prepped."
echo "Log into cluster node and execute user prep script"
echo ""
echo "Login to initial node:"
echo "> ssh -i ${PRVKEY} $SSHHOST"
echo ""
echo "Initiate next step:"
echo "> ./2_zeta_user_prep.sh"

