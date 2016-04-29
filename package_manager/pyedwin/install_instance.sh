#!/bin/bash
CLUSTERNAME=$(ls /mapr)

APP="pyedwin"

APP_ID="na"
. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh


##########
# Note: Template uses Docker Registery as example, you will want to change this
# Get instance Specifc variables from user.
echo ""
echo ""
echo "This install does not install an instance of pyedwin, but installs pyedwin into an already installed instance of Zeppelin"
echo "It also incorporates edwin_org.json specific to Zeta for helping users navigate Zeta"
echo ""
echo ""

echo "Here is a list of potential instances in the zeppelin install path:"
echo ""
ls -1 /mapr/$CLUSTERNAME/mesos/${MESOS_ROLE}/zeppelin
echo ""
read -e -p "Please enter the name of the Zeppelin instance we should install pyedwin to: " -i "zeppelinprod" APP_ZEP_INSTANCE

#env
### Consider getting some variables to help the user
TUSER="ZETA_ZEPPELIN_${APP_ZEP_INSTANCE}_USER"
echo $TUSER
eval RUSER=\$$TUSER

echo "$RUSER"

ZEP_INSTANCE=/mapr/$CLUSTERNAME/user/$RUSER/zeppelin/${APP_ZEP_INSTANCE}/zeppelin-*

cp ${APP_ROOT}/${APP}_packages/pyedwin.tgz ${ZEP_INSTANCE}/interpreter/
cd ${ZEP_INSTANCE}/interpreter
tar zxf ./pyedwin.tgz
rm pyedwin.tgz
rm -rf ${APP_HOME}

##########
# Provide instructions for next steps
echo ""
echo ""
echo "$APP instance ${APP_ID} installed into $ZEP_INSTANCE"
echo ""
echo ""
