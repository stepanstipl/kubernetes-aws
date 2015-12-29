FROM alpine:3.3
MAINTAINER Stepan Stipl
# https://github.com/stepanstipl

ENV ETCD_VERSION 2.2.2
ENV ETCD_SOURCE https://github.com/coreos/etcd/releases/download/v${ETCD_VERSION}/etcd-v$ETCD_VERSION-linux-amd64.tar.gz

RUN apk --update curl bash \
      && curl $ETCD_SOURCE -o /tmp/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz \
      && tar xzvf /tmp/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz -C /tmp \
      && cp /tmp/etcd-v${ETCD_VERSION}-linux-amd64/etcdctl / \
      && cp /tmp/etcd-v${ETCD_VERSION}-linux-amd64/etcd / \
      && rm -rf /var/cache/apk/* /tmp/*

COPY etcd-start /

EXPOSE 4001 7001 2379 2380

ENTRYPOINT ["/etcd-start"]
