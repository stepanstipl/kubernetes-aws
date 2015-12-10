FROM alpine:3.2
MAINTAINER Stepan Stipl
# https://github.com/stepanstipl

RUN apk --update add bash \
      && rm -rf /var/cache/apk/* /tmp/*

COPY docker-conf /docker-conf

ENTRYPOINT ["/docker-conf"]
