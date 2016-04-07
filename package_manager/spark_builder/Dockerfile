FROM docker-registryv1.marathonprod.mesos.srsman.secureworks.net:5000/zeta:minjdk8mvn333
#FROM zeta:minjava8mvn333

RUN mkdir /working
ADD build.sh /working/
RUN chmod +x /working/build.sh
WORKDIR /working/

CMD ["java", "-version"]
