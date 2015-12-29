FROM alpine:3.2
MAINTAINER Stepan Stipl
# https://github.com/stepanstipl

RUN apk --update add bash \
      && rm -rf /var/cache/apk/* /tmp/*

VOLUME /etc/kubernetes/manifests

COPY kube-apiserver.yaml /tmp/

COPY k8s-manifests-master /

ENTRYPOINT ["/k8s-manifests-master"]
