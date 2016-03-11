#!/bin/bash

CLUSTERNAME=$(ls /mapr)

MESOS_ROLE="prod"

. /mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

INST_FILE="/mapr/$CLUSTERNAME/user/zetaadm/5_install_docker.sh"

cat > $INST_FILE << EOL
#!/bin/bash
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

sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/docker.conf <<- 'EOF1'
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon -H fd:// --insecure-registry=$ZETA_DOCKER_REG_URL
EOF1
sudo systemctl daemon-reload
sudo service docker restart

EOL

chmod +x $INST_FILE

/home/zetaadm/zetaadmin/run_cmd.sh "$INST_FILE"

