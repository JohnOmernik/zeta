FROM ubuntu:14.04

RUN echo "deb http://repos.mesosphere.io/ubuntu/ trusty main" > /etc/apt/sources.list.d/mesosphere.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv E56151BF && \
    apt-get update && \
    apt-get install -y maven git \
    npm \
    default-jdk \
    mesos \
    scala \
    curl && \
    apt-get clean all && \
    ln -s /usr/bin/nodejs /usr/bin/node


RUN git clone https://github.com/mesos/chronos.git
RUN cd chronos && mvn clean package

ADD run_chronos.sh /chronos/bin/

RUN chmod +x /chronos/bin/run_chronos.sh

CMD ["java -version"]

