#!/bin/bash

#SPARKVER="1.5.2" -- Use ENV to override, not this line?
DIR="$(command cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE=$DIR/builds
MIRROR_BASE=http://apache.cs.utah.edu/spark
BUILDER_IMAGE=java:latest
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

if ! [ -f $BASE/$SPARKVER.tgz ]; then
    logme "Cannot find $SPARKVER.tgz in $BASE. Downloading..."
    wget -q -O $BASE/$SPARKVER.tgz $MIRROR_BASE/$SPARKVER/$SPARKVER.tgz
fi

docker run --rm -t -e "SPARKOPS=${SPARKOPTS}" -e "SPARKNAME=${SPARKNAME}" -e "SPARKVER=${SPARKVER}" -v $BASE:/working/builds:rw -v $DIR/build.sh:/working/build.sh $BUILDER_IMAGE /working/build.sh
