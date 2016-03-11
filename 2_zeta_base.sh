#!/bin/bash

. ./cluster.conf

####################
# Steps Needed Broken up into Steps vs. Push button Zeta steps
# 1. Install nano ... don't judge
# 2. Remove All non FS/Admin Roles in MapR (No Yarn, no Drill, no Hive etc)
# 3. Refresh Roles using configure.sh
# 4. Update the warden.conf on each node to reflect sane resource usage to play nice with Mesos
# 5. Update the env.sh to handle docker SUBNETS
# 6. Restart warden on all nodes
# 7. Get password for zetaadm user
# 8. Create zetaadm user on all nodes
# 9. Create keyless ssh key for zetaadm and distribute the public key
#10. Check ZETA variable for next script. If Defined, move it to /home/zetaadm, clean up permissions and run. 




####################
echo "Installing nano... don't fight it"
sudo yum install -y nano


####################
#Remove Roles for Prep to Zeta
echo "Removing all non-FS based roles in MapR"
./runcmd.sh "sudo yum -y remove mapr-drill"
./runcmd.sh "sudo yum -y remove mapr-historyserver"
./runcmd.sh "sudo yum -y remove mapr-hivemetastore"
./runcmd.sh "sudo yum -y remove mapr-hiveserver2"
./runcmd.sh "sudo yum -y remove mapr-nodemanager"
./runcmd.sh "sudo yum -y remove mapr-resourcemanager"

# Refresh Roles
echo "Refreshing Roles"
./runcmd.sh "sudo /opt/mapr/server/configure.sh -R"

# Update Warden values to play nice with Mesos:
echo "Updating Warden settings to handle Mesos "
# Back up Warden file
./runcmd.sh "sudo cp /opt/mapr/conf/warden.conf /opt/mapr/conf/warden.conf.bak"

#Set Max Pervent for MFS to 35 % 
./runcmd.sh "sudo sed -i -r 's/service\.command\.mfs\.heapsize\.maxpercent=.*/service\.command\.mfs\.heapsize\.maxpercent=35/' /opt/mapr/conf/warden.conf.bak"

#Set no reservations for Map Reduce V1
./runcmd.sh "sudo sed -i -r 's/mr1\.memory\.percent=.*/mr1\.memory\.percent=0/' /opt/mapr/conf/warden.conf.bak"
./runcmd.sh "sudo sed -i -r 's/mr1\.cpu\.percent=.*/mr1\.cpu\.percent=0/' /opt/mapr/conf/warden.conf.bak"
./runcmd.sh "sudo sed -i -r 's/mr1\.disk\.percent=.*/mr1\.disk\.percent=0/' /opt/mapr/conf/warden.conf.bak"

#copy the warden back to real warden.
./runcmd.sh "sudo cp /opt/mapr/conf/warden.conf.bak /opt/mapr/conf/warden.conf"


###################
# Set the MAPR_SUBNETS VARIABLE
echo "Updaing env.sh to use correct subnets"
O1=$(head -1 nodes.list|cut -d"." -f1)
O2=$(head -1 nodes.list|cut -d"." -f2)
O3=$(head -1 nodes.list|cut -d"." -f3)

NET="$O1.$O2.$O3.0\/24"

# Back up env.sh
./runcmd.sh "sudo cp /opt/mapr/conf/env.sh /opt/mapr/conf/env.sh.bak"

# Replace the line in the env.sh
./runcmd.sh "sudo sed -i 's/#export MAPR_SUBNETS=/export MAPR_SUBNETS=$NET/' /opt/mapr/conf/env.sh.bak"

#copy the env.sh.bak to the env.sh
./runcmd.sh "sudo cp /opt/mapr/conf/env.sh.bak /opt/mapr/conf/env.sh"






####################
echo "Checking and Creating ec2-user MapR Home Volume if needed"
if [ ! -d "/mapr/$CLUSTERNAME/user/ec2-user" ]; then
    sudo maprcli volume create -name ec2-user_home -path /user/ec2-user -rootdirperms 775 -user ec2-user:fc,a,dump,restore,m,d
    sudo chown ec2-user /mapr/$CLUSTERNAME/user/ec2-user
    sudo chmod 755 /mapr/$CLUSTERNAME/user/ec2-user
    sleep 2
fi
####################
#Run through Nodes slowly to restart warden
echo "Restarting Warden on all nodes"
while read -r node
do
    echo "Restarting Warden on $node"
    ssh -t $node "sudo service mapr-warden restart"
    sleep 15
done < "./nodes.list"


####################
###### ADD zetaadm user 

# This will be merged into m7_zeta after testing
echo "Adding zetaadm user"
stty -echo
printf "Please enter the zetaadm Password: "
read PASS1
echo ""

printf "Please Renter the zetaadm Password: "
read PASS2
echo ""
stty echo

if [ "$PASS1" != "$PASS2" ]; then
    echo "Passwords do not match exiting"
    exit 1
fi

####################
SCRIPT="/mapr/$CLUSTERNAME/user/$USER/add_zeta_adm.sh"
cat > $SCRIPT << EOL
#!/bin/bash
adduser --uid 2500 zetaadm
usermod -g zetaadm zetaadm
echo "zetaadm ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
echo "$PASS1"|passwd --stdin zetaadm
EOL

chmod +x $SCRIPT

./runcmd.sh "sudo $SCRIPT"
rm $SCRIPT
####################
echo "Making Zetaadm Home Volume"
sudo maprcli volume create -name zetaadm_home -path /user/zetaadm -rootdirperms 775 -user zetaadm:fc,a,dump,restore,m,d
sudo chown zetaadm /mapr/$CLUSTERNAME/user/zetaadm
sudo chmod 755 /mapr/$CLUSTERNAME/user/zetaadm
sleep 2

####################
echo "Creating Keys"
sudo su -c "ssh-keygen -f /mapr/$CLUSTERNAME/user/zetaadm/id_rsa -N \"\"" zetaadm
sudo mkdir -p /home/zetaadm/.ssh && sudo cp /mapr/$CLUSTERNAME/user/zetaadm/id_rsa /home/zetaadm/.ssh/
./runcmd.sh "sudo mkdir -p /home/zetaadm/.ssh && sudo cp /mapr/$CLUSTERNAME/user/zetaadm/id_rsa.pub /home/zetaadm/.ssh/authorized_keys && sudo chown -R zetaadm:zetaadm /home/zetaadm/.ssh && sudo chmod 700 /home/zetaadm/.ssh && sudo chmod 600 /home/zetaadm/.ssh/authorized_keys"


####################
echo "Moving Scripts to /home/zetaadm"

# Install Scripts
sudo cp ./$ZETA_LAYOUT /home/zetaadm/
sudo chown zetaadm:zetaadm /home/zetaadm/$ZETA_LAYOUT
sudo chmod +x /home/zetaadm/$ZETA_LAYOUT
sudo cp ./$ZETA_PACKAGER /home/zetaadm/
sudo chown zetaadm:zetaadm /home/zetaadm/$ZETA_PACKAGER
sudo chmod +x /home/zetaadm/$ZETA_PACKAGER
sudo cp ./$ZETA_DOCKER /home/zetaadm/
sudo chown zetaadm:zetaadm /home/zetaadm/$ZETA_DOCKER
sudo chmod +x /home/zetaadm/$ZETA_DOCKER
sudo cp ./$ZETA_PREP_MESOS /home/zetaadm/
sudo chown zetaadm:zetaadm /home/zetaadm/$ZETA_PREP_MESOS
sudo chmod +x /home/zetaadm/$ZETA_PREP_MESOS
sudo cp ./$ZETA_INSTALL_MESOS /home/zetaadm/
sudo chown zetaadm:zetaadm /home/zetaadm/$ZETA_INSTALL_MESOS
sudo chmod +x /home/zetaadm/$ZETA_INSTALL_MESOS

# Settings and Node List
sudo cp ./cluster.conf /home/zetaadm
sudo cp ./cluster.conf /mapr/$CLUSTERNAME/user/zetaadm/
sudo chown zetaadm:zetaadm /home/zetaadm/cluster.conf
sudo chown zetaadm:zetaadm /mapr/$CLUSTERNAME/user/zetaadm/cluster.conf
sudo cp ./nodes.list /home/zetaadm/
sudo chown zetaadm:zetaadm /home/zetaadm/nodes.list

# Zeta Packages
sudo cp ./zeta_packages.tgz /home/zetaadm/
sudo chown zetaadm:zetaadm /home/zetaadm/zeta_packages.tgz

# Zeta runcmd helper
sudo cp ./runcmd.sh /home/zetaadm/
sudo chown zetaadm:zetaadm /home/zetaadm/runcmd.sh
sudo chmod +x /home/zetaadm/runcmd.sh

echo "Base Install Complete barring any errors reported above"
echo "You are done using $IUSER. At this point Please su to zetaadm, and move the /home/zetaadm directory to start step 3"
echo ""
echo "$ sudo su"
echo "$ su zetaadm"
echo "$ cd ~"
echo "$ ./$ZETA_LAYOUT"


