FROM alpine:3.2
MAINTAINER Stepan Stipl
# https://github.com/stepanstipl

ENV DRK_DEVICE /dev/xvdb
ENV DRK_MOUNTPOINT /srv

COPY setup-master.sh /

ENTRYPOINT ["/setup-master.sh"]
