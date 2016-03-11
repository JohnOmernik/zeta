#!/bin/bash

# Change to the root dir
cd "$(dirname "$0")"
# Make sure you edit cluster.conf prior to running this. 
. ./cluster.conf

##########################
# Run the Package Manager for a clean copy of packages
# Get a node list from the connecting node, save it to nodes.list
# Upload the private key to the node
# Upload the runcmd.sh, nodes.list, and cluster.conf files to the cluster
# Upload the numbered scripts to the cluster
# Upload zeta_packages.tgz to the cluster
# Provide instructions on the next step


##########################
# Build Packages
echo "Running the Packager to ensure we have the latest packages"
cd package_manager
./package_tgzs.sh
cd ..

##########################
SSHHOST="${IUSER}@${IHOST}"

# Since we use these a lot I short cut them into variables
SCPCMD="scp -i ${PRVKEY}"
SSHCMD="ssh -i ${PRVKEY} -t ${SSHHOST}"

#########################
# Get a list of IP addresses of local nodes
NODES=$($SSHCMD -o StrictHostKeyChecking=no "sudo maprcli node list -columns ip")
rm -f nodes.list
touch nodes.list
for n in $NODES
do
    g=$(echo $n|grep -E "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}")
    if [ "$g" != "" ]; then
        echo $g >> nodes.list
    fi
done
cat nodes.list
#####################
# Copy private key
$SCPCMD ${PRVKEY} ${SSHHOST}:/home/${IUSER}/.ssh/id_rsa
# Copy next step scripts and helpers
$SCPCMD runcmd.sh ${SSHHOST}:/home/${IUSER}/
$SCPCMD nodes.list ${SSHHOST}:/home/${IUSER}/
$SCPCMD cluster.conf ${SSHHOST}:/home/${IUSER}/
$SCPCMD zeta_packages.tgz ${SSHHOST}:/home/${IUSER}/
$SCPCMD 2_zeta_base.sh ${SSHHOST}:/home/${IUSER}/
# Copy other defined scripts
$SCPCMD $ZETA_LAYOUT ${SSHHOST}:/home/${IUSER}/
$SCPCMD $ZETA_PACKAGER ${SSHHOST}:/home/${IUSER}/
$SCPCMD $ZETA_DOCKER ${SSHHOST}:/home/${IUSER}/
$SCPCMD $ZETA_PREP_MESOS ${SSHHOST}:/home/${IUSER}/
$SCPCMD $ZETA_INSTALL_MESOS ${SSHHOST}:/home/${IUSER}/

$SSHCMD "chmod +x runcmd.sh"
$SSHCMD "chmod +x 2_zeta_base.sh"

echo "Cluster Scripts have been prepped."
echo "Log into cluster node and execute initial script"
echo ""
echo "Login to initial node:"
echo "> ssh -i ${PRVKEY} $SSHHOST"
echo ""
echo "Initiate next step:"
echo "> ./2_zeta_base.sh"

