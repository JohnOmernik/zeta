#!/bin/bash

CLUSTERNAME=$(ls /mapr)

MESOS_ROLE="prod"

. /mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

INST_FILE="/mapr/$CLUSTERNAME/user/zetaadm/cluster_inst/zeta_install_mesos_prereq.sh"



#--------------------------------------------------SOL
cat > $INST_FILE << EOL
#!/bin/bash
rm -rf /tmp/node_prep
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
    sudo apt-get -y update
    sudo apt-get install -y tar wget git curl
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF
    sudo apt-get -y install build-essential python-dev python-boto libcurl4-nss-dev libsasl2-dev libsasl2-modules maven libapr1-dev libsvn-dev

elif [ "\$INST_TYPE" == "rh_centos" ]; then
    sudo yum install -y tar wget git curl
    sudo wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo

    # Install the EPEL repo so that we can pull in 'libserf-1' as part of our
    # subversion install below.
    sudo yum install -y epel-release

sudo cat > /etc/yum.repos.d/wandisco-svn.repo <<EOF
[WANdiscoSVN]
name=WANdisco SVN Repo 1.9
enabled=1
baseurl=http://opensource.wandisco.com/centos/7/svn-1.9/RPMS/\$basearch/
gpgcheck=1
gpgkey=http://opensource.wandisco.com/RPM-GPG-KEY-WANdisco
EOF

# Install essential development tools.
    sudo yum groupinstall -y "Development Tools"

# Install other Mesos dependencies.
    sudo yum install -y apache-maven python-devel java-1.8.0-openjdk-devel zlib-devel libcurl-devel openssl-devel cyrus-sasl-devel cyrus-sasl-md5 apr-devel subversion-devel apr-util-devel

else
    echo "Error"
    exit 1
fi
touch /tmp/node_prep

EOL
#------------------------------------EOL
chmod +x $INST_FILE

/home/zetaadm/zetaadmin/run_cmd_no_return.sh "$INST_FILE"

NUM_NODES=$(echo "$ZETA_NODES"|tr " " "\n"|wc -l)

NUM_INST=$(/home/zetaadm/zetaadmin/run_cmd.sh "mvn -version 2>&1"|grep "Maven home"|wc -l)

while [ $NUM_INST -ne $NUM_NODES ]
do
echo "Waiting for the number of nodes installed $NUM_INST to equal the number of total nodes $NUM_NODES in a 5 second loop. (Could take a while)"
NUM_INST=$(/home/zetaadm/zetaadmin/run_cmd.sh "ls /tmp|grep \"node_prep\""|wc -l)
sleep 5
done

echo ""
echo ""
echo "Mesos Prereqs installed"
echo "Now install Mesos"


