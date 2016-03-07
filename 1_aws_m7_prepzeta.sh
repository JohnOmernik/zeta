#!/bin/bash

# Make sure you edit cluster.conf prior to running this. 
. ./cluster.conf

##########################
SSHHOST="${IUSER}@${IHOST}"

# Since we use these a lot I short cut them into variables
SCPCMD="scp -i ${PRVKEY}"
SSHCMD="ssh -i ${PRVKEY} -t ${SSHHOST}"
#########################
# Get a list of IP addresses of local nodes
NODES=$($SSHCMD -o StrictHostKeyChecking=no "maprcli node list -columns ip")
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

$SCPCMD ${PRVKEY} ${SSHHOST}:/home/${IUSER}/.ssh/id_rsa

$SCPCMD runcmd.sh ${SSHHOST}:/home/${IUSER}/
$SCPCMD nodes.list ${SSHHOST}:/home/${IUSER}/
$SCPCMD 2_zeta_base.sh ${SSHHOST}:/home/${IUSER}/
$SCPCMD 3_zeta_layout.sh ${SSHHOST}:/home/${IUSER}/
$SCPCMD cluster.conf ${SSHHOST}:/home/${IUSER}/

$SSHCMD "chmod +x runcmd.sh"
$SSHCMD "chmod +x 2_zeta_base.sh"
$SSHCMD "chmod +x 3_zeta_layout.sh"

echo "Cluster Scripts have been prepped."
echo "Log into cluster node and execute initial script"
echo ""
echo "Login to initial node:"
echo "> ssh -i ${PRVKEY} $SSHHOST"
echo ""
echo "Initiate next step:"
echo "> ./2_zeta_base.sh"
