#!/bin/bash

APP="zeppelin"
CLUSTERNAME=$(ls /mapr)

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh

echo "To make your $APP package more complete, please specify a drill TGZ to include the JDBC jar for"
echo ""

DRILL_ROOT="/mapr/${CLUSTERNAME}/mesos/${MESOS_ROLE}/drill"

ls -ls ${DRILL_ROOT}/drill_packages
echo ""
read -e -p "Please enter the drill package to use for JDBC Drivers: " -i "drill-1.6.0.tgz" DRILL_TGZ
DRILL_VER=$(echo -n ${DRILL_TGZ}|sed "s/\.tgz//")


WORK_DIR="/tmp" # Used for creating tmp information
rm -rf ${WORK_DIR}/${APP}
cd ${WORK_DIR}
mkdir -p ${WORK_DIR}/${APP}
cd ${WORK_DIR}/${APP}

mkdir -p ${APP_ROOT}/${APP}_packages

BUILD="Y"

if [ -d "${APP_ROOT}/${APP}_packages/zep_build" ]; then
    read -e -p "Looks like the dockerfile was already here. Do you want to rebuild? " -i "N" BUILD
fi

if [ "$BUILD" == "Y" ]; then
    mkdir -p ${APP_ROOT}/${APP}_packages/zep_build
    mkdir -p ${APP_ROOT}/${APP}_packages/zep_run

    echo "Create Dockerfile for building Zeppelin"
cat > ${APP_ROOT}/${APP}_packages/zep_build/Dockerfile << EOF
FROM ${ZETA_DOCKER_REG_URL}/ubuntu1404

RUN apt-get update && apt-get install -y git openjdk-7-jdk npm libfontconfig wget
RUN wget http://www.eu.apache.org/dist/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz && tar -zxf apache-maven-3.3.3-bin.tar.gz -C /usr/local/ && ln -s /usr/local/apache-maven-3.3.3/bin/mvn /usr/local/bin/mvn && rm apache-maven-3.3.3-bin.tar.gz && mkdir /app
WORKDIR /app
EOF

cat > ${APP_ROOT}/${APP}_packages/zep_run/Dockerfile << EOF1
FROM ${ZETA_DOCKER_REG_URL}/ubuntu1404
RUN apt-get update
RUN apt-get install -y openjdk-7-jre python python-dev build-essential python-boto libcurl4-nss-dev libsasl2-dev libsasl2-modules maven libapr1-dev libsvn-dev
# May not be needed, will test, if it is needed we need to get UID of mapr for this. 
#RUN adduser --disabled-password --gecos '' --uid=700 mapr
CMD ["python -V"]

EOF1


    echo "Building, tagging, and pushing Zeppeling run and build images"
    cd ${APP_ROOT}/${APP}_packages/zep_build/
    APP_BUILD_IMG="${ZETA_DOCKER_REG_URL}/zep_build"
    APP_RUN_IMG="${ZETA_DOCKER_REG_URL}/zep_run"
    sudo docker build -t ${APP_BUILD_IMG} .

    cd ${APP_ROOT}/${APP}_packages/zep_run
    sudo docker build -t ${APP_RUN_IMG} .

    sudo docker push ${APP_BUILD_IMG}
    sudo docker push ${APP_RUN_IMG}
fi

cd ${WORK_DIR}/${APP}

##############
#Provide example GIT Settings
APP_GIT_URL="https://github.com"
APP_GIT_USER="apache"
APP_GIT_REPO="incubator-zeppelin"
git clone ${APP_GIT_URL}/${APP_GIT_USER}/${APP_GIT_REPO}


echo "Create a mini build script"
cat > ./${APP_GIT_REPO}/build.sh << EOF2
#!/bin/bash
export MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=1024m"
mvn clean package -DskipTests
EOF2

chmod +x ./${APP_GIT_REPO}/build.sh

echo "Use the build image to build Zeppelin"

sudo docker run -t --rm -v=${WORK_DIR}/${APP}/${APP_GIT_REPO}:/app ${APP_BUILD_IMG} ./build.sh


echo "Getting Current version from pom.xml"
cd ${APP_GIT_REPO}
APP_VER=$(grep -m1 "<version>" pom.xml | cut -d">" -f2 | cut -d"<" -f1)
cd ..

cp ${DRILL_ROOT}/drill_packages/${DRILL_TGZ} ./
tar zxf ${DRILL_TGZ}
sudo cp ./${DRILL_VER}/jars/jdbc-driver/drill-jdbc-all* ./${APP_GIT_REPO}/interpreter/jdbc/
rm -rf ./${DRILL_VER}


echo "Packaging Zeppelin"
sudo mv ${APP_GIT_REPO} "${APP}-${APP_VER}"
APP_TGZ="${APP}-${APP_VER}.tgz"
sudo chown -R zetaadm:zetaadm "${APP}-${APP_VER}"

echo "Adding Jar to ${APP_ROOT}/${APP}_packages/"
echo "This is hard coded and will change and break"
cp ${APP}-${APP_VER}/zeppelin-interpreter/zeppelin-interpreter-*.jar ${APP_ROOT}/${APP}_packages/

tar zcf ${APP_TGZ} ${APP}-${APP_VER}/

##############
# Finanlize location of pacakge

# Tag and upload docker image if needed locally if needed (zeta is for local, but consider using the env variables for the roles)


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
cd ${WORK_DIR}
rm -rf ${WORK_DIR}/${APP}
