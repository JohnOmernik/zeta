#!/bin/bash

APP="kafkamanager"

CLUSTERNAME=$(ls /mapr)

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh

WORK_DIR="/tmp" # Used for creating tmp information
rm -rf ${WORK_DIR}/${APP}
cd ${WORK_DIR}
mkdir -p ${WORK_DIR}/${APP}
cd ${WORK_DIR}/${APP}

##############
#Provide example GIT Settings

APP_GIT_URL="https://github.com"
APP_GIT_USER="yahoo"
APP_GIT_REPO="kafka-manager"
git clone ${APP_GIT_URL}/${APP_GIT_USER}/${APP_GIT_REPO}

cat > ${WORK_DIR}/${APP}/${APP_GIT_REPO}/build.sh << EOL1
#!/bin/bash
apt-get install -y wget
cd /app
./sbt clean dist
EOL1
chmod +x ${APP_GIT_REPO}/build.sh

APP_VER=$(grep -E "^version" ./${APP_GIT_REPO}/build.sbt|cut -d"\"" -f2)

APP_BUILD_IMG="${ZETA_DOCKER_REG_URL}/ubuntu1404openjdk8"

sudo docker run -t --rm -v=${WORK_DIR}/${APP}/${APP_GIT_REPO}:/app ${APP_BUILD_IMG} /app/build.sh

sudo chown -R zetaadm:zetaadm ./${APP_GIT_REPO}

mv ./${APP_GIT_REPO}/target/universal/kafka-manager-${APP_VER}.zip ./
unzip kafka-manager-${APP_VER}.zip
mv kafka-manager-${APP_VER}/ ${APP}-${APP_VER}

APP_TGZ="${APP}-${APP_VER}.tgz"

tar zcf ${APP_TGZ} ./${APP}-${APP_VER}


if [ -f "${APP_ROOT}/${APP}_packages/${APP_TGZ}" ]; then
    echo "This package already exists. We can exit now, without overwriting, or you can overwrite with the package you just built"
    read -e -p "Should we overwrite ${APP_TGZ} located in ${APP_ROOT}/${APP}_packages with the currently built package? (Y/N): " -i "N" OW
    if [ "$OW" != "Y" ]; then
        echo "Your answer was not Y therefore we are exiting"
        exit 1
    fi
fi
mv ${APP_TGZ} ${APP_ROOT}/${APP}_packages/

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
#cd ${WORK_DIR}
#rm -rf ${WORK_DIR}/${APP}
