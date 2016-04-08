#!/bin/bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "#### Base Location: $BASEDIR"

################## BUILD VARIABLES

HADOOP_VER="hadoop-2.7.0"
HADOOP_BASE="/opt/mapr/hadoop"
HADOOP_HOME="${HADOOP_BASE}/${HADOOP_VER}"
MYRIAD_BUILD="/mapr/zetapoc/mesos/prod/myriad/incubator-myriad"
CONF_LOC="/mapr/zetapoc/mesos/prod/myriad/conf"
URI_LOC="/mapr/zetapoc/mesos/prod/myriad"



#################################
#Clean the working directory
echo "#### Cleaning Build DIR and old tgz"
sudo rm -rf ./${HADOOP_VER}
sudo rm -rf ./${HADOOP_VER}.tgz

#Copy a fresh copy of the hadoopz
echo "#### Copying Clean Build"

# I go here and tar with h and p. h is so all the symlinked items in the MapR get put into the tgz and p to preserver permissions
cd $HADOOP_BASE
sudo tar zcfhp ${BASEDIR}/${HADOOP_VER}.tgz $HADOOP_VER

echo "#### Untaring New Build"
# I untar things in a new location so I can play without affecting the "stock" install
cd $BASEDIR
sudo tar zxfp ${HADOOP_VER}.tgz
echo "#### Now remove source tgz to get ready for build"
sudo rm ${HADOOP_VER}.tgz



# This permission combination seems to work. I go and grab the container-executor from the stock build so that I have the setuid version. 
echo "#### Cleaning Base Build Logs, yarn-site, and permissions"
sudo rm $HADOOP_VER/etc/hadoop/yarn-site.xml
sudo rm -rf $HADOOP_VER/logs/*
sudo chown mapr:mapr ${HADOOP_VER}
sudo chown -R mapr:root ${HADOOP_VER}/*
sudo chown root:root ${HADOOP_VER}/etc/hadoop/container-executor.cfg
sudo cp --preserve ${HADOOP_HOME}/bin/container-executor ${HADOOP_VER}/bin/



#Copy the jars from Myriad into the Hadoop libs folders (You will need to have Myriad build first with the root of your build being $MYRIAD_BUILD
echo "#### Copying Myriad Jars"
sudo cp $MYRIAD_BUILD/myriad-scheduler/build/libs/*.jar $HADOOP_VER/share/hadoop/yarn/lib/
sudo cp $MYRIAD_BUILD/myriad-executor/build/libs/myriad-executor-0.1.0.jar $HADOOP_VER/share/hadoop/yarn/lib/

#Address Configs

# First take the myriad-config-default.yml and put it into the $HADOOP/etc/hadoop so it's in the tarball
echo "#### Updating myriad-config-default.yml"
sudo cp ${CONF_LOC}/myriad-config-default.yml ${HADOOP_VER}/etc/hadoop/


###### Adding logic to yarn-env.sh to not make a secure cluster (for use with Myriad)

echo "Removing Security on Hadoop (login etc) for short term"
sudo chmod 777 ./hadoop-2.7.0/etc/hadoop/core-site.xml


cat > ./hadoop-2.7.0/etc/hadoop/core-site.xml <<DELIM
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
<property>
    <name>hadoop.security.authentication</name>
    <value>simple</value>
</property>

<property>
    <name>yarn.http.policy</name>
    <value>HTTP_ONLY</value>
</property>

<property>
    <name>hadoop.http.authentication.signer.secret.provider</name>
    <value></value>
</property>

<property>
    <name>hadoop.security.authorization</name>
    <value>false</value>
</property>
</configuration>
DELIM
sudo chmod 644 ./hadoop-2.7.0/etc/hadoop/core-site.xml


# Tar all the things with all the privs 
echo "#### Tarring all the things"
sudo tar zcfhp ${HADOOP_VER}.tgz ${HADOOP_VER}/

# Copy to the URI location... note I am using MapR so I cp it directly to the MapFS location via NFS share, it would probably be good to use a hadoop copy command for interoperability 
echo "#### Copying to HDFS Location"

sudo rm ${URI_LOC}/${HADOOP_VER}.tgz
cp ${HADOOP_VER}.tgz ${URI_LOC}/

# I do this because it worked... not sure if I remo
#sudo chown mapr:mapr ${URI_LOC}/${HADOOP_VER}.tgz

#echo "#### Cleaning unpacked location"
sudo rm -rf ./${HADOOP_VER}

