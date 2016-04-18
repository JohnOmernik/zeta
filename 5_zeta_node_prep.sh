#!/bin/bash

# RUN THIS SCRIPT AS zetaadm
if [[ $EUID -ne 2500 ]]; then
   echo "This script must be run as zetaadm" 1>&2
   exit 1
fi


################
# This script creates a "node prep" script called zeta_node_prep.sh in /mapr/$CLUSTERNAME/user/zetaadm/cluster_inst/
# This script takes a node that has the following criteria met:
# - Has MapR installed and is part of the cluster $CLUSTERNAME
# - Has MapR-FS NFS moutned at /mapr/$CLUSTERNAME 
# - Has the zetaadm user installed
#
# And preps the node for Zeta install. 

CLUSTERNAME=$(ls /mapr)
MESOS_ROLE="prod"
. /mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

DIST_CHK=$(lsb_release -a)
UB_CHK=$(echo $DIST_CHK|grep Ubuntu)
RH_CHK=$(echo $DIST_CHK|grep RedHat)
CO_CHK=$(echo $DIST_CHK|grep CentOS)

if [ "$UB_CHK" != "" ]; then
    INST_TYPE="ubuntu"
    echo "Ubuntu"
elif [ "$RH_CHK" != "" ] || [ "$CO_CHK" != ""]; then
    INST_TYPE="rh_centos"
    echo "Redhat"
else
    echo "Unknown lsb_release -a version at this time only ubuntu, centos, and redhat is supported"
    echo $DIST_CHK
    exit 1
fi

if [ "$INST_TYPE" == "ubuntu" ]; then
NANO="sudo apt-get install -y nano"
MAPR_RM="sudo apt-get remove -y mapr-drill;sudo apt-get remove -y mapr-historyserver;sudo apt-get remove -y mapr-hivemetastore;sudo apt-get remove -y mapr-hiveserver2;sudo apt-get remove -y mapr-nodemanger;sudo apt-get remove -y mapr-resourcemanager"
elif [ "$INST_TYPE" == "rh_centos" ]; then
NANO="sudo yum install -y nano"
MAPR_RM="sudo yum -y remove mapr-drill;sudo yum -y remove mapr-historyserver;sudo yum -y remove mapr-hivemetastore;sudo yum -y remove mapr-hiveserver2;sudo yum -y remove mapr-nodemanager;sudo yum -y remove mapr-resourcemanager"
else
    echo "Error"
    exit 1
fi

INST_FILE="/mapr/$CLUSTERNAME/user/zetaadm/cluster_inst/zeta_node_prep.sh"

cat > ${INST_FILE} << EOF
#!/bin/bash
CLUSTERNAME=\$(ls /mapr)
#################
echo "Installing nano... don't fight it"
$NANO
sudo sed -i -r 's/\# set tabsize 8/set tabsize 4/' /etc/nanorc
sudo sed -i -r 's/\# set tabstospaces/set tabstospaces/' /etc/nanorc
sudo sed -i -r 's/\# include /include /' /etc/nanorc


#################
# Removing non-zeta mapr roles (Drill, Yarn etc) 
# This could be optimized to check for roles.
####################
#Remove Roles for Prep to Zeta
echo "Removing all non-FS based roles in MapR"
$MAPR_RM

# Refresh Roles
echo "Refreshing Roles After Removal"
sudo /opt/mapr/server/configure.sh -R

# Update Warden values to play nice with Mesos:
echo "Updating Warden settings to handle Mesos "
# Back up Warden file
sudo cp /opt/mapr/conf/warden.conf /opt/mapr/conf/warden.conf.bak

#Set Max Pervent for MFS to 35 % 
sudo sed -i -r 's/service\.command\.mfs\.heapsize\.maxpercent=.*/service\.command\.mfs\.heapsize\.maxpercent=35/' /opt/mapr/conf/warden.conf.bak

#Set no reservations for Map Reduce V1
sudo sed -i -r 's/mr1\.memory\.percent=.*/mr1\.memory\.percent=0/' /opt/mapr/conf/warden.conf.bak
sudo sed -i -r 's/mr1\.cpu\.percent=.*/mr1\.cpu\.percent=0/' /opt/mapr/conf/warden.conf.bak
sudo sed -i -r 's/mr1\.disk\.percent=.*/mr1\.disk\.percent=0/' /opt/mapr/conf/warden.conf.bak

#copy the warden back to real warden.
sudo cp /opt/mapr/conf/warden.conf.bak /opt/mapr/conf/warden.conf


###################
# Set the MAPR_SUBNETS VARIABLE
# This will need to be made more robust. Right now it uses the node list , gets the first 3 octets and assumes a /24
# It doesn't account for mutiple subnets that could be using MapR Interfaces.
# It only works with since interfaced nodess

echo "Updaing env.sh to use correct subnets"
O1=\$(head -1 /mapr/\$CLUSTERNAME/user/zetaadm/nodes.list|cut -d"." -f1)
O2=\$(head -1 /mapr/\$CLUSTERNAME/user/zetaadm/nodes.list|cut -d"." -f2)
O3=\$(head -1 /mapr/\$CLUSTERNAME/user/zetaadm/nodes.list|cut -d"." -f3)

NET="\$O1.\$O2.\$O3.0\/24"

# Back up env.sh
sudo cp /opt/mapr/conf/env.sh /opt/mapr/conf/env.sh.bak

# Replace the line in the env.sh
sudo sed -i "s/#export MAPR_SUBNETS=/export MAPR_SUBNETS=\$NET/" /opt/mapr/conf/env.sh.bak

#copy the env.sh.bak to the env.sh
sudo cp /opt/mapr/conf/env.sh.bak /opt/mapr/conf/env.sh


####################
# This could cause all wardens to be "offline" at once during initial install. May have to stagger the SSH Prep during initial install
echo "Restarting Warden on all nodes"
sudo service mapr-warden restart

touch /tmp/node_prep

EOF
chmod +x ${INST_FILE}


/mapr/$CLUSTERNAME/user/zetaadm/zetaadmin/run_cmd_no_return.sh "${INST_FILE}"


NUM_NODES=$(echo "$ZETA_NODES"|tr " " "\n"|wc -l)

NUM_INST=$(/home/zetaadm/zetaadmin/run_cmd.sh "ls /tmp|grep \"node_prep\""|wc -l)

while [ $NUM_INST -ne $NUM_NODES ]
do
echo "Waiting for the number of nodes installed $NUM_INST to equal the number of total nodes $NUM_NODES in a 5 second loop. (Could take a while)"
NUM_INST=$(/home/zetaadm/zetaadmin/run_cmd.sh "ls /tmp|grep \"node_prep\""|wc -l)
sleep 5
done

echo ""
echo ""

echo "Node Prep work complete - Install Docker Next"

