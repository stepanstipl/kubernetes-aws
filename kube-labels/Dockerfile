FROM alpine:3.3
MAINTAINER Stepan Stipl
# https://github.com/stepanstipl

RUN apk --update add curl bash jq \
      && rm -rf /var/cache/apk/* /tmp/*

COPY kube-labels /kube-labels

ENTRYPOINT ["/kube-labels"]
