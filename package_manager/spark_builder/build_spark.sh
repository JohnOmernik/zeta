#!/bin/bash

#SPARKVER="1.5.2" -- Use ENV to override, not this line?

BUILD_BASE=/mapr/zetapoc/apps/dev/spark_builder/builds
MIRROR_BASE=http://apache.arvixe.com/spark
BUILDER_IMAGE=zeta:sparkbuilder
SPARKNAME="zeta"
SPARKOPTS="-Phadoop-provided -DskipTests"

logme () {
    echo "[INFO] $1"
}

if ! [ $SPARKVER ]; then
    logme "\$SPARKVER is not set in ENV. Pulling the latest version."
    wget -q -O /tmp/tmp.html $MIRROR_BASE
    SPARKVER=`cat /tmp/tmp.html | grep -o -E '\"spark-.*"' | tail -1 | sed 's/\"//g' | sed 's/\///'`
    rm /tmp/tmp.html
    logme "Latest version of Spark: $SPARKVER"
else
    logme "\$SPARKVER set in ENV as $SPARKVER"
fi

if ! [ -f $BUILD_BASE/$SPARKVER.tgz ]; then
    logme "Cannot find $SPARKVER.tgz in $BUILD_BASE. Downloading..."
    wget -q -O $BUILD_BASE/$SPARKVER.tgz $MIRROR_BASE/$SPARKVER/$SPARKVER.tgz
fi

logme "The Docker builder image doesn't exist. Building it now..."
cd $BUILD_BASE/../dockerimage && sudo docker build --no-cache --rm -t $BUILDER_IMAGE .
cd $BUILD_BASE/../.

sudo docker run --rm -t -e "SPARKOPS=${SPARKOPTS}" -e "SPARKNAME=${SPARKNAME}" -e "SPARKVER=${SPARKVER}" -v $BUILD_BASE:/working/builds:rw $BUILDER_IMAGE ./build.sh
#sudo docker run --rm -t -e "SPARKOPS=${SPARKOPTS}" -e "SPARKNAME=${SPARKNAME}" -e "SPARKVER=${SPARKVER}" -v $BUILD_BASE:/working/builds:rw $BUILDER_IMAGE ls -al /working
