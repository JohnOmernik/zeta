FROM alpine:3.3
#RUN apk add --update bash && rm -rf /var/cache/apk/*
RUN apk --update add python bash py-pip python-dev && pip install requests
CMD ["python --version"]
