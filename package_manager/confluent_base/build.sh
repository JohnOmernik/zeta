#!/bin/bash

MESOS_ROLE="prod"
CLUSTERNAME=$(ls /mapr)
. /mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

cd /mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/confluent_base/dockerbuild

TAR_FILE="confluent-2.0.1-2.11.7.tar.gz"
DL_BASE="http://packages.confluent.io/archive/2.0/"


IMAGE="confluent_base"
wget ${DL_BASE}${TAR_FILE}



cat > /mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/confluent_base/dockerbuild/Dockerfile << EOF
FROM ${ZETA_DOCKER_REG_URL}/minjdk8

ADD ${TAR_FILE} /

CMD ["java -version"]
EOF

sudo docker build -t ${ZETA_DOCKER_REG_URL}/${IMAGE} .
sudo docker push ${ZETA_DOCKER_REG_URL}/${IMAGE}
