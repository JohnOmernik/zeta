# Docker base image for Oracle JDK 8 w/glibc-2.21.
FROM alpine:3.3
MAINTAINER Stuart Wong <cgs.wong@gmail.com>

# Setup environment
ENV PKG_URL "https://circle-artifacts.com/gh/andyshinn/alpine-pkg-glibc/6/artifacts/0/home/ubuntu/alpine-pkg-glibc/packages/x86_64"
ENV JAVA_VERSION_MAJOR 8
ENV JAVA_VERSION_MINOR 60
ENV JAVA_VERSION_BUILD 27
ENV JAVA_BASE /usr/local/java
ENV JAVA_HOME ${JAVA_BASE}/jdk
ENV JAVA_PKG jdk

ENV PATH ${PATH}:${JAVA_HOME}/bin
ENV LANG C.UTF-8

# Use workarounds from https://github.com/gliderlabs/docker-alpine/issues/11:
# 1. Install glibc
# 2. hotfix /etc/nsswitch.conf, which is apperently required by glibc and is not used in Alpine Linux
RUN apk --update add \
      curl \
      ca-certificates \
      bash &&\
    curl --silent --insecure --location --output /tmp/glibc-2.21-r2.apk "${PKG_URL}/glibc-2.21-r2.apk" &&\
    curl --silent --insecure --location --output /tmp/glibc-bin-2.21-r2.apk "${PKG_URL}/glibc-bin-2.21-r2.apk" &&\
    apk add --allow-untrusted \
      /tmp/glibc-2.21-r2.apk \
      /tmp/glibc-bin-2.21-r2.apk &&\
    /usr/glibc/usr/bin/ldconfig /lib /usr/glibc/usr/lib &&\
    # Install Java
    mkdir -p ${JAVA_BASE} &&\
    curl --silent --insecure --location --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_PKG}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz | tar zxf - -C $JAVA_BASE &&\
    ln -s $JAVA_BASE/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} ${JAVA_HOME} &&\
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf &&\
    # Cleanup
    rm -rf /tmp/* \
        /var/cache/apk/* \
        ${JAVA_HOME}/*src.zip \
        ${JAVA_HOME}/lib/missioncontrol \
        ${JAVA_HOME}/lib/visualvm \
        ${JAVA_HOME}/lib/*javafx* \
        ${JAVA_HOME}/jre/lib/plugin.jar \
        ${JAVA_HOME}/jre/lib/ext/jfxrt.jar \
        ${JAVA_HOME}/jre/bin/javaws \
        ${JAVA_HOME}/jre/lib/javaws.jar \
        ${JAVA_HOME}/jre/lib/desktop \
        ${JAVA_HOME}/jre/plugin \
        ${JAVA_HOME}/jre/lib/deploy* \
        ${JAVA_HOME}/jre/lib/*javafx* \
        ${JAVA_HOME}/jre/lib/*jfx* \
        ${JAVA_HOME}/jre/lib/amd64/libdecora_sse.so \
        ${JAVA_HOME}/jre/lib/amd64/libprism_*.so \
        ${JAVA_HOME}/jre/lib/amd64/libfxplugins.so \
        ${JAVA_HOME}/jre/lib/amd64/libglass.so \
        ${JAVA_HOME}/jre/lib/amd64/libgstreamer-lite.so \
        ${JAVA_HOME}/jre/lib/amd64/libjavafx*.so \
        ${JAVA_HOME}/jre/lib/amd64/libjfx*.so

# Start container
CMD ["java","-Djava.security.egd=file:/dev/urandom"]
