#!/bin/bash

CLUSTERNAME=$(ls /mapr)
APP="dockerimages"
APP_ID="dockerimagebase"

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh


REG="${ZETA_DOCKER_REG_URL}"

cd ${APP_HOME}

IMAGES="minopenjdk7 minjdk8 minpython2 rsyncbase minopenjre7 minopenjdk7mvn333 minjdk8mvn333 minnpm minnpmgulppython ubuntu1404 ubuntu1404openjdk8"

for IMAGE in $IMAGES; do
    echo "Running on $IMAGE"
    cd $IMAGE
    sudo docker build -t ${REG}/${IMAGE} .
    sudo docker push ${REG}/${IMAGE}
    cd ..
done

echo ""
echo ""
echo "Docker Base Images were built and pushed to registry at ${REG}"
echo "You can always do it again by running ${APP_HOME}/build_images.sh"
echo ""

