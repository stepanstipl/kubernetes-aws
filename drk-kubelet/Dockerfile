FROM alpine:3.2
MAINTAINER Stepan Stipl
# https://github.com/stepanstipl

ENV K8S_VERSION 1.1.2
ENV K8S_DOMAIN cluster.local

RUN apk add --update openssl && rm -rf /var/cache/apk/*
RUN wget https://storage.googleapis.com/kubernetes-release/release/v${K8S_VERSION}/bin/linux/amd64/kubelet && chmod a+x /kubelet

VOLUME /var/lib/docker
VOLUME /var/lib/kubelet

EXPOSE 10250

ENTRYPOINT ["/kubelet", "--api-servers=http://127.0.0.1", "--config=/etc/kubernetes/manifests", "--cluster-dns=10.0.0.10", "--cluster-domain=${K8S_DOMAIN}", "--address=0.0.0.0", "--cloud-provider=aws"]
