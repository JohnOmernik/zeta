#!/bin/bash

CLUSTERNAME=$(ls /mapr)

MESOS_ROLE="prod"

. /mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

INST_FILE="/mapr/$CLUSTERNAME/user/zetaadm/cluster_inst/zeta_install_docker.sh"

cat > $INST_FILE << EOL
#!/bin/bash

DIST_CHK=\$(lsb_release -a)
UB_CHK=\$(echo \$DIST_CHK|grep Ubuntu)
RH_CHK=\$(echo \$DIST_CHK|grep RedHat)
CO_CHK=\$(echo \$DIST_CHK|grep CentOS)

if [ "\$UB_CHK" != "" ]; then
    INST_TYPE="ubuntu"
elif [ "\$RH_CHK" != "" ] || [ "\$CO_CHK" != "" ]; then
    INST_TYPE="rh_centos"
else
    echo "Unknown lsb_release -a version at this time only ubuntu, centos, and redhat is supported"
    echo \$DIST_CHK
    exit 1
fi



if [ "\$INST_TYPE" == "ubuntu" ]; then
# update apt-get
sudo apt-get -y update
sudo apt-get install -y apt-transport-https ca-certificates
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" > ~/docker.list
sudo mv /home/zetaadm/docker.list /etc/apt/sources.list.d/
sudo apt-get -y update
sudo apt-get install -y docker-engine

# Start Docker
sudo service docker start

elif [ "\$INST_TYPE" == "rh_centos" ]; then
# update yum
sudo yum -y update

# Add Docker repo to Yum
sudo tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/\$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

# Install Docker
sudo yum -y install docker-engine

# Start Docker
sudo service docker start
else
    echo "Error"
    exit 1
fi
EOL


chmod +x $INST_FILE
/home/zetaadm/zetaadmin/run_cmd_no_return.sh "$INST_FILE"


NUM_NODES=$(echo "$ZETA_NODES"|tr " " "\n"|wc -l)

NUM_INST=$(/home/zetaadm/zetaadmin/run_cmd.sh "sudo docker ps 2>&1"|grep "CONTAINER ID"|wc -l)

while [ $NUM_INST -ne $NUM_NODES ]
do
echo "Waiting for the number of nodes installed $NUM_INST to equal the number of total nodes $NUM_NODES in a 5 second loop. (Could take a while)"
NUM_INST=$(/home/zetaadm/zetaadmin/run_cmd.sh "sudo docker ps 2>&1"|grep "CONTAINER ID"|wc -l)
sleep 5
done



echo ""
echo ""
echo "Docker Installed on all nodes"
echo "Now install Mesos Prereqs"




