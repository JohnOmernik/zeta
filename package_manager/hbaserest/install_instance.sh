#!/bin/bash
CLUSTERNAME=$(ls /mapr)

APP="hbaserest"

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh


##########
# Note: Template uses Docker Registery as example, you will want to change this
# Get instance Specifc variables from user.

read -e -p "Please enter the port for ${APP} info service: " -i "48005" APP_INFO_PORT
read -e -p "Please enter the port for ${APP} REST API: " -i "48000" APP_PORT
read -e -p "Please enter the amount of memory to use for the $APP_ID instance of $APP: " -i "1024" APP_MEM
read -e -p "Please enter the amount of cpu to use for the $APP_ID instance of $APP: " -i "1.0" APP_CPU
read -e -p "What is the Application version built into the docker container you are using?: " -i "hbase-1.1.1" APP_VER
read -e -p "What username will this instance of hbaserest run as. Note: it must have access to the tables you wish provide via REST API: " -i "zetaadm" APP_USER
echo ""
echo "The next prompt will ask you for the root location for hbase table namespace mapping"
echo "Due to how maprdb and hbase interace, you need to provide a MapR-FS directory, where, within, are the tables this hbase rest API will serve"
echo ""
echo "For example, if in the path: /data/prod/myhbasetables,  you have two tables, tab1 and tab2, you want served by this HBASE rest instance"
echo "Then at the prompt for directory root, pot in /data/prod/myhbasetables"
echo ""
echo "This can be changed in the conf directory (the hbase-site.xml) for this instance"
read -e -p "What root directory should we use to identify hbase tables? :" -i "/data/prod/myhbasetables" APP_TABLE_ROOT



##########
# Do instance specific things: Create Dirs, copy start files, make executable etc
cp ${APP_ROOT}/start_instance.sh ${APP_HOME}/
chmod +x ${APP_HOME}/start_instance.sh

tar zxf ${APP_ROOT}/${APP}_packages/${APP}_conf.tgz -C ${APP_HOME}/
mkdir -p ${APP_HOME}/logs


cat > ${APP_HOME}/conf/docker_start.sh << EOF4
#!/bin/bash
export HBASE_LOGFILE="hbaserest-\$HOST-\$HOSTNAME.log"
env
/${APP_VER}/bin/hbase rest start -p 8000 --infoport 8005
EOF4
chmod +x ${APP_HOME}/conf/docker_start.sh

##########
# Highly recommended to create instance specific information to an env file for your Mesos Role

cat > /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh << EOL1
#!/bin/bash
export ZETA_${APP_UP}_${APP_ID}_ENV="${APP_ID}"
export ZETA_${APP_UP}_${APP_ID}_INFO_PORT="${APP_INFO_PORT}"
export ZETA_${APP_UP}_${APP_ID}_PORT="${APP_PORT}"
export ZETA_${APP_IP}_${APP_ID}_HOST="${APP_ID}.\${ZETA_MARATHON_ENV}.\${ZETA_MESOS_DOMAIN}"
EOL1

##########
# After it's written we source itSource the script!
. /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh


##########
# Create a marathon file if appropriate in teh ${APP_HOME} directory

cat > ${APP_HOME}/conf/hbase-site.xml << EOFCONF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
/**
 * Copyright 2010 The Apache Software Foundation
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
-->
<configuration>

  <property>
    <name>hbase.rootdir</name>
    <value>maprfs:///hbase</value>
  </property>

  <property>
<name>hbase.cluster.distributed</name>
<value>true</value>
  </property>

  <property>
<name>hbase.zookeeper.quorum</name>
<value>hadoopmapr4,hadoopmapr5,hadoopmapr6</value>
  </property>

  <property>
<name>hbase.zookeeper.property.clientPort</name>
<value>5181</value>
  </property>

  <property>
    <name>dfs.support.append</name>
    <value>true</value>
  </property>

  <property>
    <name>hbase.fsutil.maprfs.impl</name>
    <value>org.apache.hadoop.hbase.util.FSMapRUtils</value>
  </property>
  <property>
    <name>hbase.regionserver.handler.count</name>
    <value>30</value>
    <!-- default is 25 -->
  </property>

  <!-- uncomment this to enable fileclient logging
  <property>
    <name>fs.mapr.trace</name>
    <value>debug</value>
  </property>
  -->

  <!-- Allows file/db client to use 64 threads -->
  <property>
    <name>fs.mapr.threads</name>
    <value>64</value>
  </property>


  <property>
    <name>mapr.hbase.default.db</name>
    <value>maprdb</value>
  </property>

  <property>
    <name>hbase.table.namespace.mappings</name>
        <value>*:${APP_TABLE_ROOT}/</value> 
  </property>

</configuration>
EOFCONF

cat > ${APP_HOME}/${APP_ID}.marathon << EOF
{
  "id": "${APP_ID}",
  "cpus": ${APP_CPU},
  "mem": ${APP_MEM},
  "instances": 1,
  "cmd":"/zeta_sync/dockersync.sh $APP_USER && su -c /$APP_VER/conf/docker_start.sh ${APP_USER}",
  "labels": {
   "PRODUCTION_READY":"True", "CONTAINERIZER":"Docker", "ZETAENV":"${MESOS_ROLE}"
  },
  "env": {
    "HBASE_HOME": "/${APP_VER}",
    "HADOOP_HOME": "/opt/mapr/hadoop/hadoop-2.7.0",
    "HBASE_LOG_DIR": "/${APP_VER}/logs",
    "HBASE_ROOT_LOGGER": "INFO,RFA"
  },
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "${ZETA_DOCKER_REG_URL}/hbasebase",
      "network": "BRIDGE",
      "portMappings": [
        { "containerPort": 8000, "hostPort": 0, "servicePort": ${APP_PORT}, "protocol": "tcp"},
        { "containerPort": 8005, "hostPort": 0, "servicePort": ${APP_INFO_PORT}, "protocol": "tcp"}
      ]
    },
  "volumes": [
      {
        "containerPath": "/${APP_VER}/logs",
        "hostPath": "${APP_HOME}/logs",
        "mode": "RW"
      },
      {
        "containerPath": "/opt/mapr",
        "hostPath": "/opt/mapr",
        "mode": "RO"
      },
      {
        "containerPath": "/zeta_sync",
        "hostPath": "/mapr/$CLUSTERNAME/mesos/kstore/zetasync",
        "mode": "RO"
      },
      {
        "containerPath": "/${APP_VER}/conf",
        "hostPath": "${APP_HOME}/conf",
        "mode": "RO"
      }
    ]
  }
}
EOF


##########
# Provide instructions for next steps
echo ""
echo ""
echo "$APP instance ${APP_ID} installed at ${APP_HOME} and ready to go"
echo "To start please run: "
echo ""
echo "> ${APP_HOME}/start_instance.sh"
echo ""
echo ""
