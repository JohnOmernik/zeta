#!/bin/bash
CLUSTERNAME=$(ls /mapr)

APP="drill"

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh


##########
# Note: Template uses Docker Registery as example, you will want to change this
# Get instance Specifc variables from user.
echo ""
echo "Available Versions:"
ls ${APP_ROOT}/${APP}_packages
echo ""
read -e -p "Please enter the $APP Version you wish to install this instance with: " -i "drill-1.6.0.tgz" APP_TGZ

APP_VER=$(echo -n ${APP_TGZ}|sed "s/\.tgz//")
PKGS=$(ls ${APP_ROOT}/${APP}_packages/)

if [ "$PKGS" == "" ]; then
    echo "There are no ${APP} packages, please get some first by running get_${APP}_release.sh"
    exit 1
fi
if [ ! -f "${APP_ROOT}/${APP}_packages/${APP_TGZ}" ]; then
    echo "The version of ${APP} you want: $APP_TGZ does not exist in ${APP_ROOT}/${APP}_packages" 
    echo "Please set this up properly per get_package.sh"
    exit 1
fi

###############
# $APP Specific
echo "The next step will walk through instance defaults for ${APP_ID}"
echo ""
echo "Ports: "
read -e -p "Please enter the port for the Drill Web-ui and Rest API to run on for ${APP_ID}: " -i "20000" APP_WEB_PORT
read -e -p "Please enter the port for the Drillbit User Port for ${APP_ID}: " -i "20001" APP_USER_PORT
read -e -p "Please enter the port for the Drillbit Data port for ${APP_ID}: " -i "20002" APP_BIT_PORT
echo ""
echo "Resources"
read -e -p "Please enter the amount of Heap Space per Drillbit: " -i "4G" APP_HEAP_MEM
read -e -p "Please enter the amount of Direct Memory per Drillbit: " -i "8G" APP_DIRECT_MEM
read -e -p "Please enter the amount of memory (total) to provide as a limit to Marathon. (If Heap is 4G and Direct is 8G, 12500 is a good number here for Marathon): " -i "12500" APP_MEM
read -e -p "Please enter the amount of CPU shares to limit bits too in Marathon: " -i "4.0" APP_CPU
echo ""
echo "Misc:"
read -e -p "What is the default MapR topology for your data to use for Spill Location Volume Creation? " -i "/data/default-rack" APP_TOPO_ROOT
read -e -p "How many drillbits should we start by default: " -i "1" APP_CNT
echo ""


mkdir -p ${APP_HOME}
mkdir -p ${APP_HOME}/log
mkdir -p ${APP_HOME}/conf.std

cp ${APP_ROOT}/start_instance.sh ${APP_HOME}/
chmod +x ${APP_HOME}/start_instance.sh


##########
# Highly recommended to create instance specific information to an env file for your Mesos Role

cat > /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh << EOL1
#!/bin/bash
export ZETA_${APP_UP}_${APP_ID}_ENV="${APP_ID}"
export ZETA_${APP_UP}_${APP_ID}_WEB_HOST="${APP_ID}.\${ZETA_MARATHON_ENV}.\${ZETA_MESOS_DOMAIN}"
export ZETA_${APP_UP}_${APP_ID}_WEB_PORT="${APP_WEB_PORT}"
export ZETA_${APP_UP}_${APP_ID}_USER_PORT="${APP_USER_PORT}"
export ZETA_${APP_UP}_${APP_ID}_BIT_PORT="${APP_BIT_PORT}"
EOL1

##########
# After it's written we source itSource the script!
. /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh 

##########
# Unpack the version into the instance dir
cd ${APP_ROOT}
tar zxf ./${APP}_packages/${APP_TGZ} -C ./${APP_ID}/
cd ${APP_ID}


##########
# Get specific instance related things, 
ln -s ${APP_HOME}/conf.std ${APP_HOME}/${APP_VER}/conf
cp ${APP_HOME}/${APP_VER}/conf_orig/logback.xml ${APP_HOME}/conf.std/
cp ${APP_HOME}/${APP_VER}/conf_orig/mapr.login.conf ${APP_HOME}/conf.std/
cp ${APP_HOME}/${APP_VER}/conf_orig/core-site.xml ${APP_HOME}/conf.std/

cat > ${APP_HOME}/conf.std/drill-env.sh << EOF
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
MESOS_ROLE="${MESOS_ROLE}"
CLUSTERNAME=\$(ls /mapr)
APP_ID="${APP_ID}"
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
    export DRILL_SPILLLOC="\$SPILLLOC/\${APP_ID}"

    VOLNAME="mapr.\${HOSTNAME}.local.drillspill"

    if [ -d "\${NFSROOT}\${SPILLLOC}" ]; then
        echo "Spill Location exists: \${SPILLLOC}"
        if [ ! -d "\${NFSROOT}\${SPILLLOC}/\${APP_ID}" ]; then
            echo "Spill Root exists, but not individual \$APP_ID Directory. Adding."
            mkdir -p \${NFSROOT}\${SPILLLOC}/\${APP_ID}
        fi
    else
        echo "Need to create SPILL LOCATION: \${SPILLLOC}"
        RUNCMD="maprcli volume create -name \${VOLNAME} -path \${SPILLLOC} -rootdirperms 775 -user mapr:fc,a,dump,restore,m,d -minreplication 1 -replication 1 -topology \${TOPO} -mount 1"
        echo "\$RUNCMD"
        \$RUNCMD
        mkdir -p \${NFSROOT}\${SPILLLOC}/\${APP_ID}
    fi
fi

export MAPR_IMPERSONATION_ENABLED=true
export MAPR_TICKETFILE_LOCATION=/opt/mapr/conf/mapruserticket
EOF

cat > ${APP_HOME}/conf.std/drill-override.conf << EOF2
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
  sys.store.provider.zk.blobroot: "maprfs:///mesos/${MESOS_ROLE}/${APP}/${APP_ID}/log/profiles",
  sort.external.spill.directories: [ \${?DRILL_SPILLLOC} ],
  sort.external.spill.fs: "maprfs:///",
  zk.connect: \${ZETA_ZK},
  zk.root: "${APP_ID}",
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

cat > ${APP_HOME}/zetadrill << EOF3
#!/bin/bash

# Setup Drill Locations Versions
DRILL_LOC="${APP_HOME}"
DRILL_VER="${APP_VER}"
DRILL_BIN="/bin/sqlline"

#This is your Drill url
URL="jdbc:drill:zk:${ZETA_ZK}/${APP_ID}"

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

chmod +x ${APP_HOME}/zetadrill

cat > ${APP_HOME}/${APP_ID}.marathon << EOF4
{
"cmd": "./${APP_VER}/bin/runbit --config ${APP_HOME}/conf.std",
"cpus": ${APP_CPU},
"mem": ${APP_MEM},
"labels": {
    "PRODUCTION_READY":"True",
    "ZETAENV":"${MESOS_ROLE}",
    "CONTAINERIZER":"Mesos"
},
"env": {
"DRILL_VER": "${APP_VER}",
"MESOS_ROLE": "${MESOS_ROLE}",
"APP_ID": "${APP_ID}"
},
"ports":[],
"id": "${APP_ID}",
"user": "mapr",
"instances": ${APP_CNT},
"uris": ["file://${APP_ROOT}/${APP}_packages/${APP_TGZ}"],
"constraints": [["hostname", "UNIQUE"]]
}
EOF4





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
