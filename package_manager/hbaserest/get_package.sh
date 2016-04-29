#!/bin/bash

APP="hbaserest"
CLUSTERNAME=$(ls /mapr)

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh


WORK_DIR="/tmp" # Used for creating tmp information
rm -rf ${WORK_DIR}/${APP}
cd ${WORK_DIR}
mkdir -p ${WORK_DIR}/${APP}
cd ${WORK_DIR}/${APP}

##############
# Provide example URLS Downloads
APP_URL_ROOT="http://package.mapr.com/releases/ecosystem-5.x/redhat/"
APP_URL_FILE="mapr-hbase-1.1.1.201602221251-1.noarch.rpm"


wget ${APP_URL_ROOT}${APP_URL_FILE}
echo "if rpm2cpio and cpio are not installed, this will fail. If so, just install them and run again"
rpm2cpio ${APP_URL_FILE} | cpio -idmv

APP_VER=$(ls ./opt/mapr/hbase/)
APP_TGZ="${APP_VER}.tgz"

cd ./opt/mapr/hbase
cd ${APP_VER}
tar zcf ${APP_ROOT}/${APP}_packages/${APP}_conf.tgz ./conf
mv ./conf ./conf_old
cd ..
tar zcf ${APP_TGZ} ${APP_VER}
mv ./${APP_TGZ} ${WORK_DIR}/${APP}/
cd ${WORK_DIR}/${APP}
rm -rf ./opt

mkdir dockerbuild
mv ./${APP_TGZ} ./dockerbuild/

cat > ${WORK_DIR}/${APP}/dockerbuild/Dockerfile << EOL1

FROM ${ZETA_DOCKER_REG_URL}/minjdk8

RUN apk --update add libstdc++ && rm /var/cache/apk/*

ADD ${APP_TGZ} /

cmd ["java -version"]
EOL1

cd dockerbuild

APP_IMG="${ZETA_DOCKER_REG_URL}/hbasebase"

sudo docker build -t $APP_IMG .
sudo docker push $APP_IMG


##############
# Provide next step instuctions
echo ""
echo ""
echo "${APP} release is prepped for use and uploaded to docker registry or copied to ${APP}_packages"
echo "Next step is to install a running instace of ${APP}"
echo ""
echo "> ${APP_ROOT}/install_instance.sh"
echo ""
echo ""



##############
# Clean up Work Dir
cd ${WORK_DIR}
rm -rf ${WORK_DIR}/${APP}
