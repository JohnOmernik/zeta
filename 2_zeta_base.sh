#!/bin/bash

. ./cluster.conf

####################
# Steps Needed Broken up into Steps vs. Push button Zeta steps
# 1. Install nano ... don't judge
# 2. Remove All non FS/Admin Roles in MapR (No Yarn, no Drill, no Hive etc)
# 3. Refresh Roles using configure.sh
# 4. Update the warden.conf on each node to reflect sane resource usage to play nice with Mesos
# 5. Restart warden on all nodes
# 6. Get password for zetaadm user
# 7. Create zetaadm user on all nodes
# 8. Create keyless ssh key for zetaadm and distribute the public key
# 9. Check ZETA variable for next script. If Defined, move it to /home/zetaadm, clean up permissions and run. 




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
echo "Making MapR Home Volume"
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
echo "Checking to see if ZETA Script is defined, if so run it as zetaaadm"
if [ "$ZETA" != "" ]; then
    sudo cp ./$ZETA /home/zetaadm/
    sudo cp ./runcmd.sh /home/zetaadm/
    sudo cp ./nodes.list /home/zetaadm/
    sudo cp ./cluster.conf /home/zetaadm
    sudo chown zetaadm:zetaadm /home/zetaadm/runcmd.sh
    sudo chown zetaadm:zetaadm /home/zetaadm/nodes.list
    sudo chown zetaadm:zetaadm /home/zetaadm/$ZETA
    sudo su -c /home/zetaadm/$ZETA zetaadm
fi
