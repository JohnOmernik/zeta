#!/bin/bash
CLUSTERNAME=$(ls /mapr)

APP="zeppelin"

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh


##########
# Note: Template uses Docker Registery as example, you will want to change this
# Get instance Specifc variables from user.
read -e -p "Please enter the port for this instance of Zeppelin: " -i "43080" APP_PORT
read -e -p "Please enter the total memory usage for this instance of ${APP}: " -i "2048" APP_TOTAL_MEM
read -e -p "Please enter the memory usage for just $APP. This should be less then $APP_TOTAL_MEM: " -i "1024m" APP_MEM
read -e -p "Please enter the CPU usage for this instance of ${APP}: " -i "2.0" APP_CPU
read -e -p "Please enter the Username of the primary user of this instance of ${APP}: " -i "zetaadm" APP_USER
read -e -p "Please enter the $APP Version you wish to install this instance with: " -i "zeppelin-0.6.0-incubating-SNAPSHOT.tgz" APP_TGZ
APP_VER=$(echo -n ${APP_TGZ}|sed "s/\.tgz//")
echo "${APP_VER}"


echo "Creating User Specific Directories"
APP_USER_DIR="/mapr/${CLUSTERNAME}/user/${APP_USER}"
APP_USER_ID_DIR="/mapr/${CLUSTERNAME}/user/${APP_USER}/${APP}/${APP_ID}"
APP_UID=$(id -u ${APP_USER})

if [ ! -d "${APP_USER_DIR}" ]; then
    echo "The user provided, ${APP_USER}, does not appear to have a home directory:"
    echo "${APP_USER_DIR}"
    echo "Thus you can't install an instance here"
    rm -rf ${APP_HOME}
    exit 0
fi
if [ -d "${APP_USER_ID_DIR}" ]; then
    echo "An instance directory for that user already exists"
    echo "Will not overwrite, please choose a different name or remove the directory"
    echo "${APP_USER_ID_DIR}"
    rm -rf ${APP_HOME}
    exit 0
fi


cp ${APP_ROOT}/start_instance.sh ${APP_HOME}/
chmod +x ${APP_HOME}/start_instance.sh


sudo mkdir -p ${APP_USER_ID_DIR}
sudo mkdir -p ${APP_USER_ID_DIR}/notebooks
sudo mkdir -p ${APP_USER_ID_DIR}/logs
sudo mkdir -p ${APP_USER_ID_DIR}/conf
sudo tar zxf ${APP_ROOT}/${APP}_packages/${APP_TGZ} -C ${APP_USER_ID_DIR}
sudo cp ${APP_USER_ID_DIR}/${APP_VER}/conf/* ${APP_USER_ID_DIR}/conf/
sudo cp ${APP_USER_ID_DIR}/conf/zeppelin-site.xml.template ${APP_USER_ID_DIR}/conf/zeppelin-site.xml

sudo sed -i -r "s/<value>8080<\/value>/<value>${APP_PORT}<\/value>/" ${APP_USER_ID_DIR}/conf/zeppelin-site.xml

sudo cp ${APP_USER_ID_DIR}/conf/zeppelin-env.sh.template ${APP_USER_ID_DIR}/conf/zeppelin-env.sh

sudo chown -R ${APP_USER}:${APP_USER} ${APP_USER_DIR}/zeppelin


cat > ${APP_USER_ID_DIR}/user_config.sh << EOU
#!/bin/bash

CLUSTERNAME=$(ls /mapr)
MESOS_ROLE="${MESOS_ROLE}"
APP_UP="${APP_UP}"
APP_ID="${APP_ID}"

. /mapr/\$CLUSTERNAME/mesos/kstore/env/zeta_zetaaws_\${MESOS_ROLE}.sh


RUSER=\$(whoami)


echo "This script provides you the information to setup your interpreters in Zeppelin"
echo ""
echo "First Drill"
echo "Based on roles, here are the options for Drill instances to connect to:"
echo ""
ls -ls /mapr/\$CLUSTERNAME/mesos/\${MESOS_ROLE}/drill/
echo ""
echo ""
read -e -p "Please enter the name of the Drill Role to choose}: " -i "drill\${MESOS_ROLE}" DRILL_ID
echo ""
echo ""
echo "on the Interpreters page, scroll to jdbc"
echo ""
echo "Here, set the following options and press save:"
echo ""
echo "default.user: \${RUSER}"
echo "default.password: %ENTERYOURPASSWORD%"
echo "default.url: jdbc:drill:zk=\${ZETA_ZK}/\${DRILL_ID}/\${DRILL_ID}"
echo "default.driver: org.apache.drill.jdbc.Driver"
echo "common.max_count: 10000"
echo ""
echo ""
echo "While passwords show up in plain text in the web there is some security around them in the back ground"
echo ""
echo ""

EOU

chmod +x ${APP_USER_ID_DIR}/user_config.sh



##########
# Highly recommended to create instance specific information to an env file for your Mesos Role
# Exampe ENV File for Docker Register V2 into sourced scripts

cat > /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh << EOL1
#!/bin/bash
export ZETA_ZEPPELIN_${APP_ID}_ID="${APP_ID}"
export ZETA_ZEPPELIN_${APP_ID}_PORT="${APP_PORT}"
export ZETA_ZEPPELIN_${APP_ID}_USER="${APP_USER}"
export ZETA_ZEPPELIN_${APP_ID}_URL="${APP_ID}.\${ZETA_MARATHON_ENV}.\${ZETA_MESOS_DOMAIN}:${APP_PORT}"
EOL1

##########
# After it's written we source itSource the script!
. /mapr/$CLUSTERNAME/mesos/kstore/env/env_${MESOS_ROLE}/${APP}_${APP_ID}.sh


##########
# Create a marathon file if appropriate in teh ${APP_HOME} directory
# This actually updates the interpreter json so root or the owner can change
cat > ${APP_HOME}/${APP_ID}.marathon << EOF
{
  "id": "${APP_ID}",
  "cpus": ${APP_CPU},
  "mem": ${APP_TOTAL_MEM},
  "instances": 1,
  "cmd":"/zeta_sync/dockersync.sh ${APP_USER} && su -c /zeppelin/bin/zeppelin.sh ${APP_USER}",
  "labels": {
   "PRODUCTION_READY":"True", "CONTAINERIZER":"Docker", "ZETAENV":"${MESOS_ROLE}"
  },
"env": {
"ZEPPELIN_CONF_DIR":"/conf",
"ZEPPELIN_NOTEBOOK_DIR":"/notebooks", 
"ZEPPELIN_HOME":"/zeppelin",
"ZEPPELIN_LOG_DIR":"/logs",
"ZEPPELIN_MEM":"-Xms${APP_MEM} -Xmx${APP_MEM} -XX:MaxPermSize=512m",
"ZEPPELIN_PID_DIR":"/logs",
"MASTER":"mesos://leader.mesos:5050",
"SPARK_HOME":"NotSet",
"HADOOP_CONF_DIR":"NotSet",
"ZEPPELIN_SPARK_CONCURRENTSQL":"true",
"SPARK_APP_NAME":"zeppelinspark-$APPID",
"DEBUG":"0"
},
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "${ZETA_DOCKER_REG_URL}/zep_run",
      "network": "HOST"
    },
  "volumes": [
      {
        "containerPath": "/zeppelin",
        "hostPath": "${APP_USER_ID_DIR}/${APP_VER}",
        "mode": "RO"
      },
      {
        "containerPath": "/mapr/${CLUSTERNAME}",
        "hostPath": "/mapr/${CLUSTERNAME}",
        "mode": "RW"
      },
      {
        "containerPath": "/logs",
        "hostPath": "${APP_USER_ID_DIR}/logs",
        "mode": "RW"
      },
      {
        "containerPath": "/zeta_sync",
        "hostPath": "/mapr/$CLUSTERNAME/mesos/kstore/zetasync",
        "mode": "RO"
      },
      {
        "containerPath": "/notebooks",
        "hostPath": "${APP_USER_ID_DIR}/notebooks",
        "mode": "RW"
      },
      {
        "containerPath": "/conf",
        "hostPath": "${APP_USER_ID_DIR}/conf",
        "mode": "RW"
      }
    ]
  }
}

EOF

# THis will be added back in when we have spark to work with
#      {
#       "containerPath": "/mapr/brewpot/mesos/prod/spark/spark-1.6.1-bin-without-hadoop",
#       "hostPath": "/mapr/brewpot/mesos/prod/spark/spark-1.6.1-bin-without-hadoop",
#       "mode": "RO"
#      },
#      {
#       "containerPath": "/mapr/brewpot/mesos/prod/myriad/hadoop-2.7.0",
#       "hostPath": "/mapr/brewpot/mesos/prod/myriad/hadoop-2.7.0",
#       "mode": "RO"
#      },
#     {
#       "containerPath": "/opt/mapr",
#       "hostPath": "/opt/mapr",
#       "mode": "RO"
#     },
#     {
#       "containerPath": "/usr/local/lib",
#       "hostPath": "/usr/local/lib",
#       "mode": "RO"
#     } 






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
