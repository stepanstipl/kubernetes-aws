FROM alpine:3.2
MAINTAINER Stepan Stipl
# https://github.com/stepanstipl

ENV VERSION_ETCD=2.2.2

RUN apk --update add curl \
      && rm -rf /var/cache/apk/* /tmp/*

RUN curl -L  https://github.com/coreos/etcd/releases/download/v${VERSION_ETCD}/etcd-v${VERSION_ETCD}-linux-amd64.tar.gz -o /tmp/etcd-v${VERSION_ETCD}-linux-amd64.tar.gz \
      && tar xzvf /tmp/etcd-v${VERSION_ETCD}-linux-amd64.tar.gz -C /tmp \
      && cp /tmp/etcd-v${VERSION_ETCD}-linux-amd64/etcd / \
      && rm -rf /tmp/*

ENTRYPOINT ["/etcd"]
