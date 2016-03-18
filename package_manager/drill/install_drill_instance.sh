#!/bin/bash

MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)


. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

APP_ID="drillprod"
APP_VER="drill-1.6.0"
APP_WEB_PORT="20000"
APP_USER_PORT="20001"
APP_BIT_PORT="20002"
APP_CNT="1"

DRILL_ROOT="/mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/drill"
DRILL_HOME="${DRILL_ROOT}/${APP_ID}"

if [ -f "/mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/drill_${APP_ID}.sh" ]; then
    echo "drill instance ${APP_ID} for ${MESOS_ROLE} already exists based on env script /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/drill_${APP_ID}.sh"
    echo "Install not proceeding"
    exit 1
fi

if [ -d "${DRILL_HOME}" ]; then
    echo "While the env script for this instance doesn't exist, the directory does."
    echo "Not proceeding until you fix that up"
    exit 1
fi

PKGS=$(ls ${DRILL_ROOT}/drill_packages/)

if [ "$PKGS" == "" ]; then
    echo "There are no Drill packages, please get some first by running get_drill_release.sh"
    exit 1
fi
if [ ! -f "${DRILL_ROOT}/drill_packages/${APP_VER}.tgz" ]; then
    echo "The version of drill you want: $APP_VER does not exist in ${DRILL_ROOT}/drill_packages" 
    echo "Please set this up properly per get_drill_release.sh"
    exit 1
fi



mkdir -p ${DRILL_HOME}
mkdir -p ${DRILL_HOME}/log
mkdir -p ${DRILL_HOME}/profiles
mkdir -p ${DRILL_HOME}/conf.std


cat > /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/drill_${APP_ID}.sh << EOL1
#!/bin/bash
export ZETA_DRILL_${APP_ID}_ENV="${APP_ID}"
export ZETA_DRILL_${APP_ID}_WEB_HOST="${APP_ID}.\${ZETA_MARATHON_ENV}.\${ZETA_MESOS_DOMAIN}"
export ZETA_DRILL_${APP_ID}_WEB_PORT="${APP_WEB_PORT}"
export ZETA_DRILL_${APP_ID}_USER_PORT="${APP_USER_PORT}"
export ZETA_DRILL_${APP_ID}_BIT_PORT="${APP_BIT_PORT}"
EOL1


cd ${DRILL_ROOT}

tar zxf ./drill_packages/drill-1.6.0.tgz -C ./${APP_ID}/
cd ${APP_ID}
ln -s ${DRILL_HOME}/conf.std ${DRILL_HOME}/${DRILL_VER}/conf
cp ./${APP_VER}/conf_orig/logback.xml ./conf.std/
cp ./${APP_VER}/conf_orig/mapr.login.conf ./conf.std/
cp ./${APP_VER}/conf_orig/core-site.xml ./conf.std/

APP_HEAP_MEM="4G"
APP_DIRECT_MEM="8G"
APP_MEM="12500"
APP_CPU="4.0"
APP_TOPO_ROOT="/data/default-rack"
cat > ${DRILL_HOME}/conf.std/drill-env.sh << EOF
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

CALL_SCRIPT="\$0"
MESOS_ROLE="prod"
CLUSTERNAME=\$(ls /mapr)
# We are running Drill prod, so source the file
. /mapr/\${CLUSTERNAME}/mesos/kstore/env/zeta_\${CLUSTERNAME}_\${MESOS_ROLE}.sh


echo "Webhost: \${ZETA_DRILL_${APP_ID}_WEB_HOST}:\${ZETA_DRILL_${APP_ID}_WEB_PORT}"


DRILL_MAX_DIRECT_MEMORY="${APP_DIRECT_MEM}"
DRILL_HEAP="${APP_HEAP_MEM}"

export SERVER_GC_OPTS="-XX:+CMSClassUnloadingEnabled -XX:+UseG1GC "

export DRILL_JAVA_OPTS="-Xms\$DRILL_HEAP -Xmx\$DRILL_HEAP -XX:MaxDirectMemorySize=\$DRILL_MAX_DIRECT_MEMORY -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=1G -Ddrill.exec.enable-epoll=true -Djava.library.path=./${APP_VER}/libjpam -Djava.security.auth.login.config=/opt/mapr/conf/mapr.login.conf -Dzookeeper.sasl.client=false"

# Class unloading is disabled by default in Java 7
# http://hg.openjdk.java.net/jdk7u/jdk7u60/hotspot/file/tip/src/share/vm/runtime/globals.hpp#l1622

HOSTNAME=\$(hostname -f)

export DRILL_LOG_DIR="/mapr/\${CLUSTERNAME}/mesos/\${MESOS_ROLE}/drill/\${APP_ID}/log"

export DRILL_LOG_PREFIX="drillbit_\${HOSTNAME}"
export DRILL_LOGFILE=\$DRILL_LOG_PREFIX.log
export DRILL_OUTFILE=\$DRILL_LOG_PREFIX.out
export DRILL_QUERYFILE=\${DRILL_LOG_PREFIX}_queries.json

export DRILLBIT_LOG_PATH="\${DRILL_LOG_DIR}/logs/\${DRILL_LOGFILE}"
export DRILLBIT_QUERY_LOG_PATH="\${DRILL_LOG_DIR}/queries/\${DRILL_QUERYFILE}"

# MAPR Specifc Setting up a location for spill (this is a quick hacky version of what is donoe in the createTTVolume.sh)

TOPOROOT="$APP_TOPO_ROOT"
TOPO="\${TOPOROOT}/\${HOSTNAME}"

NFSROOT="/mapr/\${CLUSTERNAME}"
SPILLLOC="/var/mapr/local/\${HOSTNAME}/drillspill"

o=\$(echo \$CALL_SCRIPT|grep sqlline)
if [ "\$o" != "" ]; then
    echo "SQL Line: no SPILL Loc"
else
    export DRILL_SPILLLOC="\$SPILLLOC"

    VOLNAME="mapr.\${HOSTNAME}.local.drillspill"

    if [ -d "\${NFSROOT}\${SPILLLOC}" ]; then
        echo "Spill Location exists: \${SPILLLOC}"
    else
        echo "Need to create SPILL LOCATION: \${SPILLLOC}"
        RUNCMD="maprcli volume create -name \${VOLNAME} -path \${SPILLLOC} -rootdirperms 775 -user mapr:fc,a,dump,restore,m,d -minreplication 1 -replication 1 -topology \${TOPO} -mount 1"
        echo "\$RUNCMD"
        \$RUNCMD
    fi
fi

export MAPR_IMPERSONATION_ENABLED=true
export MAPR_TICKETFILE_LOCATION=/opt/mapr/conf/mapruserticket
EOF

cat > ${DRILL_HOME}/conf.std/drill-override.conf << EOF2
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#  This file tells Drill to consider this module when class path scanning.
#  This file can also include any supplementary configuration information.
#  This file is in HOCON format, see https://github.com/typesafehub/config/blob/master/HOCON.md for more information.

# See 'drill-override-example.conf' for example configurations

drill.exec: {
  cluster-id: \${ZETA_DRILL_${APP_ID}_ENV},
  http.ssl_enabled: true,
  http.port: \${ZETA_DRILL_${APP_ID}_WEB_PORT},
  rpc.user.server.port: \${ZETA_DRILL_${APP_ID}_USER_PORT},
  rpc.bit.server.port: \${ZETA_DRILL_${APP_ID}_BIT_PORT},
  sys.store.provider.zk.blobroot: "maprfs:///mesos/${MESOS_ROLE}/drill/${APP_ID}/log/profiles",
  sort.external.spill.directories: [ \${?DRILL_SPILLLOC} ],
  sort.external.spill.fs: "maprfs:///",
  zk.connect: \${ZETA_ZK},
  impersonation: {
    enabled: true,
    max_chained_user_hops: 3
  },
  security.user.auth {
         enabled: true,
         packages += "org.apache.drill.exec.rpc.user.security",
         impl: "pam",
         pam_profiles: [ "sudo", "login" ]
   }
}
EOF2


cat > ${DRILL_HOME}/zetadrill << EOF3
#!/bin/bash

# Setup Drill Locations Versions
DRILL_LOC="${DRILL_HOME}"
DRILL_VER="${APP_VER}"
DRILL_BIN="/bin/sqlline"

#This is your Drill url
URL="jdbc:drill:zk:${ZETA_ZK}"

#Location for the prop file. (Should be user's home directoy)
DPROP=~/prop\$\$

# Secure the File
touch "\$DPROP"
chmod 600 "\$DPROP"

# Get username from user
printf "Please enter Drill Username: "
read USER

# Turn of Terminal Echo
stty -echo
# Get Password from User
printf "Please enter Drill Password: "
read PASS
# Turn Echo back on 
stty echo
printf "\n"

# Write properties file for Drill
cat >> "\$DPROP" << EOL
user=\$USER
password=\$PASS
url=\$URL
EOL

# Exectue Drill connect with properties file. After 10 seconds, the command will delete the prop file. Note this may result in race condition. 
# 10 seconds SHOULD be enough. 
(sleep 10; rm "\$DPROP") & \${DRILL_LOC}/\${DRILL_VER}\${DRILL_BIN} \${DPROP}

EOF3

cat > ${DRILL_HOME}/${APP_ID}.marathon << EOF4
{
"cmd": "./${APP_VER}/bin/runbit --config /mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/drill/${APP_ID}/conf.std",
"cpus": ${APP_CPU},
"mem": ${APP_MEM},
"labels": {
    "PRODUCTION_READY":"True",
    "ZETAENV":"Prod",
    "CONTAINERIZER":"Mesos"
},
"env": {
"DRILL_VER": "${APP_VER}",
"MESOS_ROLE": "prod",
"APP_ID": "${APP_ID}"
},
"ports":[],
"id": "${APP_ID}",
"user": "mapr",
"instances": ${APP_CNT},
"uris": ["file:///mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/drill/drill_packages/${APP_VER}.tgz"],
"constraints": [["hostname", "UNIQUE"]]
}
EOF4
