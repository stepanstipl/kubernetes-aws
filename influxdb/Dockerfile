FROM alpine:3.3

MAINTAINER Stepan Stipl

RUN apk --update add bash \
      && rm -rf /var/cache/apk/* /tmp/*

COPY _artifacts/influx /
COPY _artifacts/influxd /

COPY _artifacts/influxdb-discovery /

COPY _artifacts/types.db /usr/share/collectd/

COPY _artifacts/influxdb.sh /

COPY influxdb.toml /etc/influxdb.toml

# api
EXPOSE 8086
# admin ui
EXPOSE 8083
# intra influxdb
EXPOSE 8088

CMD ["/influxdb.sh"]
