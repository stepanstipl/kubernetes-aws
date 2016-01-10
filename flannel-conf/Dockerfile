FROM alpine:3.2
MAINTAINER Stepan Stipl
# https://github.com/stepanstipl

ENV ETCD_VERSION 2.2.2

RUN apk --update add python py-pip curl bash iptables \
      && pip install --upgrade awscli \
      && apk del py-pip py-setuptools \
      && rm -rf /var/cache/apk/* /tmp/*

RUN curl -L  https://github.com/coreos/etcd/releases/download/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz -o /tmp/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz \
      && tar xzvf /tmp/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz -C /tmp \
      && cp /tmp/etcd-v${ETCD_VERSION}-linux-amd64/etcdctl / \
      && rm -rf /tmp/*

COPY flannel-conf /flannel-conf

ENTRYPOINT ["/flannel-conf"]
