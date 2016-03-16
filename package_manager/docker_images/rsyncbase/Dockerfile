FROM alpine:3.2
RUN apk --update add python sshpass rsync py-pip python-dev bash openssh coreutils && pip install requests && rm -rf /vat/cache/apk/*

CMD ["python -V"]

