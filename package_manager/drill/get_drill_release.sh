#!/bin/bash


MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

DRILL_ROOT="/mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/drill"

#Multiple sources can be used, but we prefer the packaged RPMs from MapR so it works with all features. Sometimes that's a dev release, sometimes its from the main repo"

SRC="http://mapr-9166720.s3.amazonaws.com/"
#SRC="http://package.mapr.com/releases/ecosystem-5.x/redhat/"

SRCFILE="mapr-drill-1.6.0.201603141532-1.noarch.rpm"
#SRCFILE="mapr-drill-1.4.0.201601071151-1.noarch.rpm"



cd /tmp
rm -rf ./drillget
mkdir drillget
cd drillget
wget ${SRC}${SRCFILE}


echo "if rpm2cpio and cpio are not installed, this will fail. If so, just install them and run again"

rpm2cpio $SRCFILE | cpio -idmv

DRILL_VER=$(ls ./opt/mapr/drill/)

if [ -f "${DRILL_ROOT}/drill_packages/${DRILL_VER}.tgz" ]; then
    echo "This version already exists, we will not over write"
    echo "Location: ${DRILL_ROOT}/drill_packages/${DRILL_VER}.tgz"
    echo "To reinstall, remove or rename existing package"
    exit 1
fi
mv ./opt/mapr/drill/${DRILL_VER} ./
cd ${DRILL_VER}
echo "Moving default conf to conf_orig"
mv ./conf ./conf_orig
echo "Adding libjpam and extrajars to distribution"
cp -R ${DRILL_ROOT}/libjpam ./
cp ${DRILL_ROOT}/extrajars/* ./jars/3rdparty/
cd ..
echo "Packaging new tgz for execution in Mesos"
tar zcf ${DRILL_VER}.tgz ${DRILL_VER}
echo "Moving to drill location"
mv ${DRILL_VER}.tgz ${DRILL_ROOT}/drill_packages/
echo "Drill Ver: $DRILL_VER installed to ${DRILL_ROOT}/drill_packages/"


