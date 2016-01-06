FROM alpine:3.2
MAINTAINER Stepan Stipl
# https://github.com/stepanstipl

RUN apk --update add python py-pip curl bash openssl \
      && pip install --upgrade awscli \
      && apk del py-pip py-setuptools \
      && rm -rf /var/cache/apk/* /tmp/*

VOLUME /etc/kubernetes
VOLUME /srv/kubernetes

COPY manifests /manifests/
COPY podmaster-manifests /podmaster-manifests/

COPY kubelet-conf /

ENTRYPOINT ["/kubelet-conf"]
