FROM alpine:3.3
RUN apk --update add openjdk7 bash && rm /var/cache/apk/*

ENV PATH /usr/lib/jvm/java-1.7-openjdk/bin:$PATH

CMD ["java", "-version"]
