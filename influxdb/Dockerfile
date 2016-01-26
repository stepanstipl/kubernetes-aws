FROM progrium/busybox
# busybox:1.24-glibc

MAINTAINER Stepan Stipl

COPY _artifacts/influx /
COPY _artifacts/influxd /
COPY _artifacts/influxdb-discovery /
COPY _artifacts/types.db /usr/share/collectd/
COPY influxdb.sh /
COPY influxdb.toml /etc/influxdb.toml

RUN opkg-install curl

# api
EXPOSE 8086
# admin ui
EXPOSE 8083
# intra influxdb
EXPOSE 8088

CMD ["/influxdb.sh"]
