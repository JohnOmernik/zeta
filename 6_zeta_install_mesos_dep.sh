#!/bin/bash

CLUSTERNAME=$(ls /mapr)

INST_FILE="/mapr/$CLUSTERNAME/user/zetaadm/6_install_mesos_dep.sh"

cat > $INST_FILE << EOL
# Install a few utility tools
sudo yum install -y tar wget git

# Fetch the Apache Maven repo file.
sudo wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo

# Install the EPEL repo so that we can pull in 'libserf-1' as part of our
# subversion install below.
sudo yum install -y epel-release

# 'Mesos > 0.21.0' requires 'subversion > 1.8' devel package,
# which is not available in the default repositories.
# Create a WANdisco SVN repo file to install the correct version:
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

EOL

chmod +x $INST_FILE

/home/zetaadm/zetaadmin/run_cmd.sh "$INST_FILE"



