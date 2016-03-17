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

####################
# 1. Check to run the script as 2500
# 2. cd to the location the script is (should be /home/zetaadm)
# 3. Clean up default volumes from MapR Marketplace setup
# 4. Add groups for Zeta to all nodes
# 5. Add mapr and zetaadm to all those groups on all nodes
# 6. Setup major directories (apps, data, etl, mesos) in MapR FS Set permissions etc.
# 7. Setup kstore directories and basic configuration for Mesos


# Get the Zookeepers from the warden.conf file
ZK_SPEC=$(cat /opt/mapr/conf/warden.conf|grep zookeeper\.servers|sed "s/zookeeper\.servers=//g")

# This is the ENV File for the cluster. 
ZETA_ENV_FILE="/mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_prod.sh"


####################
####### Work to Clean up Default Volumes:
echo "Removing Default Volumes: Errors here about No such file or Directory are ok"
sudo maprcli volume remove -name tables_vol
sudo maprcli volume remove -name mapr.hbase
sudo maprcli volume remove -name shared_data_vol
sudo maprcli volume remove -name mapr.apps
sudo rm -rf /mapr/$CLUSTERNAME/apps


##############################################################################
echo "Adding Zeta Groups to all nodes"
# Specific Zeta Setup
./runcmd.sh "sudo groupadd --gid 2501 zetausers"
./runcmd.sh "sudo groupadd --gid 2502 zetaproddata"
./runcmd.sh "sudo groupadd --gid 2503 zetadevdata"
./runcmd.sh "sudo groupadd --gid 2504 zetaprodmesos"
./runcmd.sh "sudo groupadd --gid 2505 zetadevmesos"
./runcmd.sh "sudo groupadd --gid 2506 zetaprodapps"
./runcmd.sh "sudo groupadd --gid 2507 zetadevapps"
./runcmd.sh "sudo groupadd --gid 2508 zetaprodetl"
./runcmd.sh "sudo groupadd --gid 2509 zetadevetl"

echo "Adding mapr and zetaadm to all zeta groups on all nodes"
./runcmd.sh "sudo usermod -a -G zetausers mapr"
./runcmd.sh "sudo usermod -a -G zetausers zetaadm"
./runcmd.sh "sudo usermod -a -G zetaproddata mapr"
./runcmd.sh "sudo usermod -a -G zetaproddata zetaadm"
./runcmd.sh "sudo usermod -a -G zetadevdata mapr"
./runcmd.sh "sudo usermod -a -G zetadevdata zetaadm"
./runcmd.sh "sudo usermod -a -G zetaprodmesos mapr"
./runcmd.sh "sudo usermod -a -G zetaprodmesos zetaadm"
./runcmd.sh "sudo usermod -a -G zetadevmesos mapr"
./runcmd.sh "sudo usermod -a -G zetadevmesos zetaadm"
./runcmd.sh "sudo usermod -a -G zetaprodapps mapr"
./runcmd.sh "sudo usermod -a -G zetaprodapps zetaadm"
./runcmd.sh "sudo usermod -a -G zetadevapps mapr"
./runcmd.sh "sudo usermod -a -G zetadevapps zetaadm"
./runcmd.sh "sudo usermod -a -G zetaprodetl mapr"
./runcmd.sh "sudo usermod -a -G zetaprodetl zetaadm"
./runcmd.sh "sudo usermod -a -G zetadevetl mapr"
./runcmd.sh "sudo usermod -a -G zetadevetl zetaadm"


#Directory Setup
################################
# Create apps Directory
# The apps directory contains non-cluster services. Think specific apps for your org. A webserver, a dashboard. These may be developed outside, but are serving a business purpose, not a cluster based (admin, frameworks etc) purpose. 
# Webservrs, scrapers, etc

echo "Creating apps directory, and prod/dev roles within"
sudo mkdir -p /mapr/$CLUSTERNAME/apps
sudo chown zetaadm:zetausers /mapr/$CLUSTERNAME/apps
sudo chmod 750 /mapr/$CLUSTERNAME/apps

VOL="appsdev"
MNT="/apps/dev"
GRP="zetadevapps"

sudo maprcli volume create -name $VOL -path $MNT -rootdirperms 775 -user zetaadm:fc,a,dump,restore,m,d 
sudo chmod 775 /mapr/${CLUSTERNAME}$MNT
sudo chown zetaadm:$GRP /mapr/${CLUSTERNAME}$MNT

VOL="appsprod"
MNT="/apps/prod"
GRP="zetaprodapps"

sudo maprcli volume create -name $VOL -path $MNT -rootdirperms 775 -user zetaadm:fc,a,dump,restore,m,d 
sudo chmod 775 /mapr/${CLUSTERNAME}$MNT
sudo chown zetaadm:$GRP /mapr/${CLUSTERNAME}$MNT



################################
# Create Mesos Directory
# The Mesos directory in Zeta is used to house cluster services. These are services that may serve many purposes in your cluster, and also serve many users and applications.
# Examples include, Apache Drill, Docker Registery, Apache Kafka, Apache Spark, UIs for these services, etc. 

echo "Creating mesos directory and prod/dev roles within"
sudo mkdir -p /mapr/$CLUSTERNAME/mesos
sudo chown zetaadm:zetausers /mapr/$CLUSTERNAME/mesos
sudo chmod 750 /mapr/$CLUSTERNAME/mesos

VOL="mesosdev"
MNT="/mesos/dev"
GRP="zetadevmesos"

sudo maprcli volume create -name $VOL -path $MNT -rootdirperms 775 -user zetaadm:fc,a,dump,restore,m,d 
sudo chmod 775 /mapr/${CLUSTERNAME}$MNT
sudo chown zetaadm:$GRP /mapr/${CLUSTERNAME}$MNT

VOL="mesosprod"
MNT="/mesos/prod"
GRP="zetaprodmesos"

sudo maprcli volume create -name $VOL -path $MNT -rootdirperms 775 -user zetaadm:fc,a,dump,restore,m,d 
sudo chmod 775 /mapr/${CLUSTERNAME}$MNT
sudo chown zetaadm:$GRP /mapr/${CLUSTERNAME}$MNT

################################
# Create etl Directory
# The etl directory is used for data jobs running on your cluster. These are like little applications, but serve a purpose specific to loading of data.  
# 
echo "Creating etl directory and prod/dev roles within"
sudo mkdir -p /mapr/$CLUSTERNAME/etl
sudo chown zetaadm:zetausers /mapr/$CLUSTERNAME/etl
sudo chmod 750 /mapr/$CLUSTERNAME/etl

VOL="etldev"
MNT="/etl/dev"
GRP="zetadevetl"

sudo maprcli volume create -name $VOL -path $MNT -rootdirperms 775 -user zetaadm:fc,a,dump,restore,m,d 
sudo chmod 775 /mapr/${CLUSTERNAME}$MNT
sudo chown zetaadm:$GRP /mapr/${CLUSTERNAME}$MNT

VOL="etlprod"
MNT="/etl/prod"
GRP="zetaprodetl"

sudo maprcli volume create -name $VOL -path $MNT -rootdirperms 775 -user zetaadm:fc,a,dump,restore,m,d 
sudo chmod 775 /mapr/${CLUSTERNAME}$MNT
sudo chown zetaadm:$GRP /mapr/${CLUSTERNAME}$MNT


################################
# Create data Directory
# This is where multipurpose/multiuser queryable data resides. Of course there may be application, framework, and user specific data located in other locations on the cluster. 
# However, the data directory is reserved for data that is in a multi purpose storage format (parquet, orc, text, etc) and can be used my by multiple data frameworks.
# an example of data that does not belong here would be the data folder for a docker registery. Only the Docker Registery application will access that data, thus it should be stored under the applicaiton itself. 
# This is also a good place to mount public MapR Tables.  Creating subvolumes here is also encouraged when appropriate. 

echo "Creating data directory and prod/dev roles within"
sudo mkdir -p /mapr/$CLUSTERNAME/data
sudo chown zetaadm:zetausers /mapr/$CLUSTERNAME/data
sudo chmod 750 /mapr/$CLUSTERNAME/data

VOL="datadev"
MNT="/data/dev"
GRP="zetadevdata"

sudo maprcli volume create -name $VOL -path $MNT -rootdirperms 775 -user zetaadm:fc,a,dump,restore,m,d 
sudo chmod 775 /mapr/${CLUSTERNAME}$MNT
sudo chown zetaadm:$GRP /mapr/${CLUSTERNAME}$MNT

VOL="dataprod"
MNT="/data/prod"
GRP="zetaproddata"

sudo maprcli volume create -name $VOL -path $MNT -rootdirperms 775 -user zetaadm:fc,a,dump,restore,m,d 
sudo chmod 775 /mapr/${CLUSTERNAME}$MNT
sudo chown zetaadm:$GRP /mapr/${CLUSTERNAME}$MNT


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
# The prod location is for prod frameworks. Secrets in the secret directory, other information in subdirectories per framework 

DIR="/mapr/$CLUSTERNAME/mesos/kstore/prod"
sudo mkdir -p $DIR
sudo chown zetaadm:zetaprodmesos $DIR
sudo chmod 2750 $DIR

DIR="/mapr/$CLUSTERNAME/mesos/kstore/prod/secret"
sudo mkdir -p $DIR
sudo chown zetaadm:zetaprodmesos $DIR
sudo chmod 2750 $DIR
echo "$MESOS_PROD_PRNCPL $MESOS_PROD_PASS" > $DIR/credential.txt

cat > $DIR/credential.sh << EOF10
#!/bin/bash
export ROLE_PRIN="$MESOS_PROD_PRNCPL"
export ROLE_PASS="$MESOS_PROD_PASS"
EOF10



#########
# The dev location is for dev frameworks. Secrets in the secret directory, other information in subdirectories per framework 
DIR="/mapr/$CLUSTERNAME/mesos/kstore/dev"
sudo mkdir -p $DIR
sudo chown zetaadm:zetadevmesos $DIR
sudo chmod 2750 $DIR

DIR="/mapr/$CLUSTERNAME/mesos/kstore/dev/secret"
sudo mkdir -p $DIR
sudo chown zetaadm:zetaprodmesos $DIR
sudo chmod 2750 $DIR
echo "$MESOS_DEV_PRNCPL $MESOS_DEV_PASS" > $DIR/credential.txt

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
    {
      "principal": "${MESOS_AGENT_USER}","secret": "${MESOS_AGENT_PASS}"
    },
    {
      "principal": "${MESOS_PROD_PRNCPL}","secret": "${MESOS_PROD_PASS}"
    },
    {
      "principal": "${MESOS_DEV_PRNCPL}","secret": "${MESOS_DEV_PASS}"
    }
  ]
}
EOL0
sudo chmod 750 /mapr/$CLUSTERNAME/mesos/kstore/mesosconf/secrets/allcredentials.json

cat > /mapr/$CLUSTERNAME/mesos/kstore/mesosconf/mesos_acls.json << EOL1
{
  "permissive": false,
  "register_frameworks": [
    { "principals": { "values": ["zetaprodcontrol"] }, "roles": { "type": "ANY" }},
    { "principals": { "values": ["zetadevcontrol"] }, "roles": { "values": ["dev"] }}
  ],
  "run_tasks": [
    { "principals": { "values": ["zetaprodcontrol"] }, "users": { "type": "ANY"}},
    { "principals": { "values": ["zetadevcontrol"] }, "users": { "values": ["svcdevdata"]}}
  ],
  "shutdown_frameworks": [
    { "principals": { "values": ["zetaprodcontrol"] },"framework_principals": { "type": "ANY" }},
    { "principals": { "values": ["zetadevcontrol"] },"framework_principals": { "values": "zetadevcontrol" }}
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

# ENV Main
DIR="/mapr/$CLUSTERNAME/mesos/kstore/env"
sudo mkdir -p $DIR
sudo chown zetaadm:zetaadm $DIR
sudo chmod 775 $DIR


# ENV Added Sripts
DIR="/mapr/$CLUSTERNAME/mesos/kstore/env/env_prod"
sudo mkdir -p $DIR
sudo chown zetaadm:zetaadm $DIR
sudo chmod 775 $DIR

echo "Building Zeta ENV File"
cat > $ZETA_ENV_FILE << EOL3
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

export ZETA_MARATHON_MASTERS="${MASTER_NODES}"
export ZETA_MARATHON_ENV="marathonprod"
export ZETA_MARATHON_HOST="\${ZETA_MARATHON_ENV}.\${ZETA_MESOS_DOMAIN}"
export ZETA_MARATHON_PORT="20080"

export ZETA_CHRONOS_ENV="chronosprod"
export ZETA_CHRONOS_HOST="\${ZETA_CHRONOS_ENV}.\${ZETA_MARATHON_ENV}.\${ZETA_MESOS_DOMAIN}"
export ZETA_CHRONOS_PORT="20180"
# END GLOBAL ENV VARIABLES

# Source env_prod
for SRC in /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/*.sh; do
   . \$SRC
done

if [ "\$1" == "1" ]; then
    env|grep -P "^ZETA_"
fi

EOL3

chmod +x $ZETA_ENV_FILE

#Create a dummy script in the env_prod directory so that file not found errors don't appear when sourcing main file
cat > /mapr/$CLUSTERNAME/mesos/kstore/env/env_prod/env_prod.sh << EOL5
#!/bin/bash
# Basic script to keep file not found errors from happening 
EOL5

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


echo "Now follow the scripts in this directory in order, 4_, 5_ etc to finish installation"

