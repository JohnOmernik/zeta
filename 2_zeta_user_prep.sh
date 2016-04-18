#!/bin/bash

###################
# Purpose of this script
# 1. Change and sync all mapr user passwords on all nodes
# 2. Create zetaadm user on all nodes with synced password
# 3. Ensure zetaadm is in the sudoers group on all nodes
# 4. Create zetaadm home volume in MapR-FS
# 5. Create ssh keypair for zetaadm - private in home volume, ensure public is in authorized_keys on all nodes
# 6. Copy remaining install scripts to /home/zetaadm 

CLUSTERNAME=$(ls /mapr)

SUDO_TEST=$(sudo whoami)
if [ "$SUDO_TEST" != "root" ]; then
    echo "This script must be run with a user with sudo privs"
    exit 1
fi

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

####################
###### ADD zetadm user and sync passwords on mapr User
echo "Prior to installing Zeta, there are two steps that must be taken to ensure two users exist and are in sync across the nodes"
echo "The two users are:"
echo ""
echo "mapr - This user is installed by the mapr installer and used for mapr services, however, we need to change the password and sync the password across the nodes"
echo "zetaadm - This is the user you can use to administrate your cluster and install packages etc."
echo ""
echo "Please keep track of these users passwords"
echo ""
echo ""
echo "Syncing mapr password on all nodes"
stty -echo
printf "Please enter new password for mapr user on all nodes: "
read mapr_PASS1
echo ""
printf "Please renter password for mapr: "
read mapr_PASS2
echo ""
stty echo

while [ "$mapr_PASS1" != "$mapr_PASS2" ]
do
    echo "Passwords entered for mapr user do not match, please try again"
    stty -echo
    printf "Please enter new password for mapr user on all nodes: "
    read mapr_PASS1
    echo ""
    printf "Please renter password for mapr: "
    read mapr_PASS2
    echo ""
    stty echo
done

echo ""
echo "Adding user zetaadm to all nodes"
stty -echo
printf "Please enter the zetaadm Password: "
read zetaadm_PASS1
echo ""

printf "Please Renter the zetaadm Password: "
read zetaadm_PASS2
echo ""
stty echo


while [ "$zetaadm_PASS1" != "$zetaadm_PASS2" ]
do
    echo "Passwords for zetaadm do not match, please try again"
    echo ""
    stty -echo
    printf "Please enter the zetaadm Password: "
    read zetaadm_PASS1
    echo ""

    printf "Please Renter the zetaadm Password: "
    read zetaadm_PASS2
    echo ""
    stty echo
done


if [ "$INST_TYPE" == "ubuntu" ]; then
   ADD="adduser --disabled-login --gecos '' --uid=2500 zetaadm"
   ZETA="echo \"zetaadm:$zetaadm_PASS1\"|chpasswd"
   MAPR="echo \"mapr:$mapr_PASS1\"|chpasswd"
elif [ "$INST_TYPE" == "rh_centos" ]; then
   ADD="adduser --uid 2500 zetaadm"
   ZETA="echo \"$zetaadm_PASS1\"|passwd --stdin zetaadm"
   MAPR="echo \"$mapr_PASS1\"|passwd --stdin mapr"
else
    echo "Relase not found, not sure why we are here, exiting"
    exit 1
fi

SCRIPT="/mapr/${CLUSTERNAME}/tmp/userupdate.sh"

cat > $SCRIPT << EOF
#!/bin/bash
$ADD
echo "zetaadm ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
$ZETA
$MAPR
EOF

chmod 770 $SCRIPT
./runcmd.sh "sudo $SCRIPT"
rm $SCRIPT

####################
echo "Users Created - Creating Mapr-FS Home Volume for zetaadm"
sudo maprcli volume create -name zetaadm_home -path /user/zetaadm -rootdirperms 775 -user zetaadm:fc,a,dump,restore,m,d
sudo chown zetaadm /mapr/$CLUSTERNAME/user/zetaadm
sudo chmod 755 /mapr/$CLUSTERNAME/user/zetaadm
sleep 2
sudo mkdir /mapr/$CLUSTERNAME/user/zetaadm/cluster_inst
sudo chown zetaadm /mapr/$CLUSTERNAME/user/zetaadm/cluster_inst
sudo chmod 750 /mapr/$CLUSTERNAME/user/zetaadm/cluster_inst
sudo mkdir /mapr/$CLUSTERNAME/user/zetaadm/sshkey
sudo chown zetaadm:zetaadm /mapr/$CLUSTERNAME/user/zetaadm/sshkey
sudo chmod 770 /mapr/$CLUSTERNAME/user/zetaadm/sshkey

####################
echo "Creating Keys"
sudo su -c "ssh-keygen -f /mapr/$CLUSTERNAME/user/zetaadm/sshkey/id_rsa -N \"\"" zetaadm
sudo mkdir -p /home/zetaadm/.ssh && sudo cp /mapr/$CLUSTERNAME/user/zetaadm/sshkey/id_rsa /home/zetaadm/.ssh/
./runcmd.sh "sudo mkdir -p /home/zetaadm/.ssh && sudo cp /mapr/$CLUSTERNAME/user/zetaadm/sshkey/id_rsa.pub /home/zetaadm/.ssh/authorized_keys && sudo chown -R zetaadm:zetaadm /home/zetaadm/.ssh && sudo chmod 700 /home/zetaadm/.ssh && sudo chmod 600 /home/zetaadm/.ssh/authorized_keys"

####################
echo "Moving Scripts to /home/zetaadm"

# Install Scripts
SCRIPTS=`cat ./install_scripts.list`
for S in $SCRIPTS ; do
    sudo cp ./$S /home/zetaadm/
    sudo chown zetaadm:zetaadm /home/zetaadm/$S
    sudo chmod +x /home/zetaadm/$S
done


# Settings, scripts list, node list, packages, and helper
sudo cp ./cluster.conf /home/zetaadm/
sudo cp ./cluster.conf /mapr/$CLUSTERNAME/user/zetaadm/
sudo cp ./install_scripts.list /home/zetaadm/
sudo cp ./nodes.list /home/zetaadm/
sudo cp ./nodes.list /mapr/$CLUSTERNAME/user/zetaadm/
sudo cp ./zeta_packages.tgz /home/zetaadm/
sudo cp ./runcmd.sh /home/zetaadm/
#Fix Ownership
sudo chown zetaadm:zetaadm /home/zetaadm/cluster.conf
sudo chown zetaadm:zetaadm /mapr/$CLUSTERNAME/user/zetaadm/cluster.conf
sudo chown zetaadm:zetaadm /home/zetaadm/nodes.list
sudo chown zetaadm:zetaadm /home/zetaadm/install_scripts.list
sudo chown zetaadm:zetaadm /home/zetaadm/zeta_packages.tgz
sudo chown zetaadm:zetaadm /home/zetaadm/runcmd.sh


# Zeta runcmd helper permissions
sudo chmod +x /home/zetaadm/runcmd.sh

echo "Users installed and scripts setup for zetaadm barring any errors reported above"
echo "You are done using $IUSER. At this point Please su to zetaadm, and move the /home/zetaadm directory to start step 3"
echo ""
echo "$ sudo su"
echo "$ su zetaadm"
echo "$ cd ~"
echo "$ ./3_zeta_layout.sh"

