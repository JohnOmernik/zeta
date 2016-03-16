# Build for 206 MB JRE 1.8.0_60 (192 MB in size) with Alping and glibc
FROM zeta/minjdk8


ENV MAVEN_VERSION="3.3.3"
ENV M2_HOME=/usr/lib/mvn

RUN apk add --update wget coreutils && \
  cd /tmp && \
  wget "http://ftp.unicamp.br/pub/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz" && \
  tar -zxvf "apache-maven-$MAVEN_VERSION-bin.tar.gz" && \
  mv "apache-maven-$MAVEN_VERSION" "$M2_HOME" && \
  ln -s "$M2_HOME/bin/mvn" /usr/bin/mvn && \
  apk del wget && \
  rm /tmp/* /var/cache/apk/*

CMD ["java", "-version"]
