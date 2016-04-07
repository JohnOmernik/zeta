FROM centos:latest
MAINTAINER Naveen Manivannan <naveen{at}counterthreatunit{dot}com>

WORKDIR '/tmp'

ENV HADOOP_VER="2.7.0"
ENV HADOOP_USER="mapradm"
ENV JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk

RUN yum -y update && yum install -y java-1.8.0-openjdk-devel.x86_64 wget git-core tar && rpm -Uvh http://repos.mesosphere.io/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm && yum -y update && yum -y install mesos && yum -y clean all

ADD incubator-myriad.tar.gz /tmp/
COPY mapr.tar.gz /tmp/
RUN chmod -R 777 /tmp/incubator-myriad && cd /tmp/incubator-myriad/docker/ && ./build-myriad.sh && ln -s /tmp/hadoop-${HADOOP_VER} /usr/local/hadoop

#sudo docker run -v /var/run/docker.sock:/run/docker.sock -v $(which docker):/bin/docker -v $(which docker-compose):/bin/docker-compose --rm -it testing /bin/bash
