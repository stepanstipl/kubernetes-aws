FROM alpine:3.2
MAINTAINER Stepan Stipl
# https://github.com/stepanstipl

ENV BUILD_ETCD_VERSION 2.2.2
ENV BUILD_ETCD_SOURCE https://github.com/coreos/etcd/releases/download/v${BUILD_ETCD_VERSION}/etcd-v${BUILD_ETCD_VERSION}-linux-amd64.tar.gz

RUN apk add --update curl bash \
      && curl -L $BUILD_ETCD_SOURCE -o /tmp/etcd-v${BUILD_ETCD_VERSION}-linux-amd64.tar.gz \
      && tar xzvf /tmp/etcd-v${BUILD_ETCD_VERSION}-linux-amd64.tar.gz -C /tmp \
      && cp /tmp/etcd-v${BUILD_ETCD_VERSION}-linux-amd64/etcdctl / \
      && cp /tmp/etcd-v${BUILD_ETCD_VERSION}-linux-amd64/etcd / \
      && rm -rf /var/cache/apk/* /tmp/*

COPY etcd-start /

EXPOSE 4001 7001 2379 2380

ENTRYPOINT ["/etcd-start"]
