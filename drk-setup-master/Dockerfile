FROM alpine:3.2
MAINTAINER Stepan Stipl
# https://github.com/stepanstipl

ENV DRK_DEVICE /dev/xvdb
ENV DRK_MOUNTPOINT /srv

RUN apk add --update bash && rm -rf /var/cache/apk/*

COPY setup-master.sh /

ENTRYPOINT ["/setup-master.sh"]
