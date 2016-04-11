#!/bin/bash

CLUSTERNAME=$(ls /mapr)
MESOS_ROLE="prod"

# RUN THIS SCRIPT AS zetaadm
if [[ $EUID -ne 2500 ]]; then
   echo "This script must be run as zetaadm" 1>&2
   exit 1
fi


# Change to the root dir
cd "$(dirname "$0")"

. ./cluster.conf

# Get the Zookeepers from the warden.conf file
ZK_SPEC=$(cat /opt/mapr/conf/warden.conf|grep zookeeper\.servers|sed "s/zookeeper\.servers=//g")

####################
# 1. Check to run the script as 2500
# 2. cd to the location the script is (should be /home/zetaadm)
# 3. Clean up default volumes from MapR Marketplace setup
# 4. Add groups for Zeta to all nodes
# 5. Add mapr and zetaadm to all those groups on all nodes
# 6. Setup major directories (apps, data, etl, mesos) in MapR FS Set permissions etc.
# 7. Setup kstore directories and basic configuration for Mesos


# This script needs work to separate out the role creation from the layout to support roles
# Right now it assumes a prod rule is needed, creates that
# and also makes some basic example directories for dev roles but doesn't complete the role creation

####### Work to Clean up Default Volumes:
echo "Removing Default Volumes: Errors here about No such file or Directory are ok"
sudo maprcli volume remove -name tables_vol
sudo maprcli volume remove -name mapr.hbase
sudo maprcli volume remove -name shared_data_vol
sudo maprcli volume remove -name mapr.apps
sudo rm -rf /mapr/$CLUSTERNAME/apps


##############################################################################
echo "Adding Zeta Groups to all nodes"
# This assumes no groups/roles have been installed because this is an initial setup
# It creates the dev groups, but doesn't finish the role
# In reality role creation (thus role group creation)
# Should occur in a N role creation script
# However, more thought needs to be put into it. For now, it's a skeleton

# Specific Zeta Setup
./runcmd.sh "sudo groupadd --gid 2501 zetausers"


echo "Adding mapr and zetaadm to all zeta groups on all nodes"
./runcmd.sh "sudo usermod -a -G zetausers mapr"
./runcmd.sh "sudo usermod -a -G zetausers zetaadm"


#Directory Setup
################################
# Create apps Directory
# The apps directory contains non-cluster services. Think specific apps for your org. A webserver, a dashboard. These may be developed outside, but are serving a business purpose, not a cluster based (admin, frameworks etc) purpose. 
# Webservrs, scrapers, etc

echo "Creating apps directory"
sudo mkdir -p /mapr/$CLUSTERNAME/apps
sudo chown zetaadm:zetausers /mapr/$CLUSTERNAME/apps
sudo chmod 750 /mapr/$CLUSTERNAME/apps

################################
# Create Mesos Directory
# The Mesos directory in Zeta is used to house cluster services. These are services that may serve many purposes in your cluster, and also serve many users and applications.
# Examples include, Apache Drill, Docker Registery, Apache Kafka, Apache Spark, UIs for these services, etc. 

echo "Creating mesos directory"
sudo mkdir -p /mapr/$CLUSTERNAME/mesos
sudo chown zetaadm:zetausers /mapr/$CLUSTERNAME/mesos
sudo chmod 750 /mapr/$CLUSTERNAME/mesos

################################
# Create etl Directory
# The etl directory is used for data jobs running on your cluster. These are like little applications, but serve a purpose specific to loading of data.  
# 
echo "Creating etl directory"
sudo mkdir -p /mapr/$CLUSTERNAME/etl
sudo chown zetaadm:zetausers /mapr/$CLUSTERNAME/etl
sudo chmod 750 /mapr/$CLUSTERNAME/etl


################################
# Create data Directory
# This is where multipurpose/multiuser queryable data resides. Of course there may be application, framework, and user specific data located in other locations on the cluster. 
# However, the data directory is reserved for data that is in a multi purpose storage format (parquet, orc, text, etc) and can be used my by multiple data frameworks.
# an example of data that does not belong here would be the data folder for a docker registery. Only the Docker Registery application will access that data, thus it should be stored under the applicaiton itself. 
# This is also a good place to mount public MapR Tables.  Creating subvolumes here is also encouraged when appropriate. 

echo "Creating data directory"
sudo mkdir -p /mapr/$CLUSTERNAME/data
sudo chown zetaadm:zetausers /mapr/$CLUSTERNAME/data
sudo chmod 750 /mapr/$CLUSTERNAME/data


#####################################################
# Create base Mesos Key Store locations
# the kstore directory under Mesos is used to house Mesos specific configuration data, as well as zeta specific clusterwide information
# Descriptions of the locations are below
echo "Setting up Mesos kstore information"
DIR="/mapr/$CLUSTERNAME/mesos/kstore"
sudo mkdir -p $DIR
sudo chown zetaadm:zetausers $DIR
sudo chmod 755 $DIR

#########
# mesosconf is used for Mesos startup scripts. This includes acls, ratelimits and other scripts. Secrets is the master of secrets for mesos masters
DIR="/mapr/$CLUSTERNAME/mesos/kstore/mesosconf"
sudo mkdir -p $DIR
sudo chown zetaadm:zetaadm $DIR
sudo chmod 2750 $DIR

DIR="/mapr/$CLUSTERNAME/mesos/kstore/mesosconf/secrets"
sudo mkdir -p $DIR
sudo chown zetaadm:zetaadm $DIR
sudo chmod 2750 $DIR


cat > /mapr/$CLUSTERNAME/mesos/kstore/mesosconf/secrets/allcredentials.json << EOL0
{
  "credentials": [
    {"principal": "${MESOS_AGENT_USER}","secret": "${MESOS_AGENT_PASS}"}
  ]
}
EOL0

sudo chmod 750 /mapr/$CLUSTERNAME/mesos/kstore/mesosconf/secrets/allcredentials.json

#Prod permissions added due to super user status
cat > /mapr/$CLUSTERNAME/mesos/kstore/mesosconf/mesos_acls.json << EOL1
{
  "permissive": false,
  "register_frameworks": [
    { "principals": { "values": ["zetaprodcontrol"] }, "roles": { "type": "ANY" } }
  ],
  "run_tasks": [
    { "principals": { "values": ["zetaprodcontrol"] }, "users": { "type": "ANY"} }
  ],
  "shutdown_frameworks": [
    { "principals": { "values": ["zetaprodcontrol"] },"framework_principals": { "type": "ANY" } }
  ]
}
EOL1

cat > /mapr/$CLUSTERNAME/mesos/kstore/mesosconf/mesos_rate_limits.json << EOL2
#Testing
EOL2

#########
# kstore/env is used for the clusterwide env sciprt. This script does not contain "secret" info, and thus is zetausers readable.  It contains locations of cluster information where
# if your users develop to the existence of this script, and thus source it in their work, if cluster information changes (say zookeeper information) their applications authmatically adjust
# This is the stub version of this, more information can be added as needed

# GET ALL NODES
ALL_NODES=$(sudo maprcli node list -columns ip|cut -d" " -f1|grep -v "hostname"|tr "\n" " "|sed 's/\s*$//g')

# Get 3 Master Nodes for Mesos Master and Marathon Master  
MASTER_NODES=$(echo ${ALL_NODES}|cut -d" " -f1,2,3)

# Group Sync
DIR="/mapr/$CLUSTERNAME/mesos/kstore/zetasync"
sudo mkdir -p $DIR
sudo chown zetaadm:zetaadm $DIR
sudo chmod 775 $DIR

cat > ${DIR}/zetagroups.list << GRPEOF
zetausers:2501:mapr,zetaadm
GRPEOF

cat > ${DIR}/zetausers.list << USROF
mapr:$(id -u mapr)
zetaadm:$(id -u zetaadm)
USROF


# ENV Main
DIR="/mapr/$CLUSTERNAME/mesos/kstore/env"
sudo mkdir -p $DIR
sudo chown zetaadm:zetaadm $DIR
sudo chmod 775 $DIR


echo "Building Zeta Master ENV File"
cat > /mapr/$CLUSTERNAME/mesos/kstore/env/master_env.sh << EOL3
#!/bin/bash

# START GLOBAL ENV Variables for Zeta Environment
export ZETA_ZK="${ZK_SPEC}"
export ZETA_MESOS_ZK="\$ZETA_ZK/mesosha"

export ZETA_CLUSTER_NAME="${CLUSTERNAME}"
export ZETA_NFS_ROOT="/mapr/\$ZETA_CLUSTER_NAME"

export ZETA_MESOS_DOMAIN="${MESOS_DOMAIN}"
export ZETA_MESOS_LEADER="leader.\${ZETA_MESOS_DOMAIN}"
export ZETA_MESOS_LEADER_PORT="5050"

export ZETA_NODES="${ALL_NODES}"
export ZETA_MESOS_AGENTS="${ALL_NODES}"
export ZETA_MESOS_MASTERS="${MASTER_NODES}"
# END GLOBAL ENV VARIABLES
EOL3

#########
# By creating a world reable directory in MapRFS for tickets, and then setting permission on each ticket to be only user readble, we have a one stop shop to store tickets
# The only caveat is the mapr and zetaadm tickets need TLC, if especially the mapr ticket expires on a secure cluster, the result is NFS mount that don't work breaking all the things
DIR="/mapr/$CLUSTERNAME/mesos/kstore/maprtickets"
sudo mkdir -p $DIR
sudo chown mapr:zetaadm $DIR
sudo chmod 775 $DIR


#########
# A Location to store cluster builds of Mesos
DIR="/mapr/$CLUSTERNAME/mesos/builds"
sudo mkdir -p $DIR
sudo chown zetaadm:zetaadm $DIR
sudo chmod 775 $DIR

#########
# The agents directory has the credentials for agents to authenticate to mesos. 
DIR="/mapr/$CLUSTERNAME/mesos/kstore/agents"
sudo mkdir -p $DIR
sudo chown -R zetaadm:zetaadm $DIR
sudo chmod -R 2750 $DIR

cat > /mapr/$CLUSTERNAME/mesos/kstore/agents/credential.json << EOL4
{
  "principal": "${MESOS_AGENT_USER}",
  "secret": "${MESOS_AGENT_PASS}"
}
EOL4


########################
# untar zeta_packages.tgz
# get the zetaadmin package move it to /home/zetaadm
# untar zetaadmin package
# cp to /mapr/$CLUSTERNAME/user/zetaadm/
# ensure scripts are set to be executable

echo "Untarring Packages"
tar zxf zeta_packages.tgz

echo "Copying zetaadmin.tgz, untarring, and copying to maprfs location"
cp ./zeta_packages/zeta_inst_zetaadmin.tgz ./
tar zxf zeta_inst_zetaadmin.tgz
cp -R zetaadmin /mapr/$CLUSTERNAME/user/zetaadm/

echo "Removing install package and setting scripts to executable"
rm zeta_inst_zetaadmin.tgz
chmod +x ./zetaadmin/*
chmod +x /mapr/$CLUSTERNAME/user/zetaadm/zetaadmin/*
cp /mapr/$CLUSTERNAME/user/zetaadm/zetaadmin/dockersync.sh /mapr/$CLUSTERNAME/mesos/kstore/zeta_sync/


echo "Main Layout for Zeta installed"
