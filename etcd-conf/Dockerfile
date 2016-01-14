FROM alpine:3.3
MAINTAINER Stepan Stipl
# https://github.com/stepanstipl

RUN apk --update add python py-pip curl bash jq \
      && pip install --upgrade awscli \
      && apk del py-pip py-setuptools \
      && rm -rf /var/cache/apk/* /tmp/*

COPY etcd-conf /etcd-conf

ENTRYPOINT ["/etcd-conf"]
