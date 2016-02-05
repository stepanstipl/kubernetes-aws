FROM alpine:3.3
MAINTAINER Stepan Stipl
# https://github.com/stepanstipl

RUN apk --update add python py-pip curl bash openssl \
      && pip install --upgrade awscli \
      && apk del py-pip py-setuptools \
      && rm -rf /var/cache/apk/* /tmp/*

VOLUME /etc/kubernetes
VOLUME /srv/kubernetes

COPY kube-proxy.kubeconfig /

COPY kubeproxy-conf.sh /

ENTRYPOINT ["/kubeproxy-conf.sh"]
