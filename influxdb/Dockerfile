FROM alpine:edge
MAINTAINER Stepan Stipl

ENV INFLUX_VERSION v0.10.2
ENV DISCOVERY_VERSION 0.0.3
ENV DISCOVERY_URL https://github.com/stepanstipl/kubernetes-utils/releases/download/$DISCOVERY_VERSION/influxdb-discovery.tar.gz

ENV GOLANG_VERSION 1.4.3
ENV GOLANG_URL https://golang.org/dl/go$GOLANG_VERSION.src.tar.gz
ENV GOLANG_SHA1 486db10dc571a55c8d795365070f66d343458c48

RUN set -ex \
    && apk add --no-cache --virtual .build-deps \
        ca-certificates \
        gcc \
        musl-dev \
        openssl \
        git \
    && apk add --no-cache bash \
    && wget -q "$GOLANG_URL" -O golang.tar.gz \
    && echo "$GOLANG_SHA1  golang.tar.gz" | sha1sum -c - \
    && tar -C /usr/local -xzf golang.tar.gz \
    && rm golang.tar.gz \
    && cd /usr/local/go/src \
    && ./make.bash \
    && export GOPATH=/go \
    && export GOROOT=/usr/local/go \
    && export PATH=$GOPATH/bin:$GOROOT/bin:$PATH \
    && go get github.com/influxdata/influxdb \
    && cd $GOPATH/src/github.com \
    && ln -s influxdata influxdb \
    && cd influxdata/influxdb \
    && go get -u -f -t ./... \
    && go clean ./... \
    && git checkout -q --detach "$INFLUX_VERSION" \
    && LDFLAGS="-X main.version $INFLUX_VERSION" \
    && LDFLAGS="$LDFLAGS -X main.branch master" \
    && LDFLAGS="$LDFLAGS -X main.commit $(git rev-parse --short HEAD)" \
    && LDFLAGS="$LDFLAGS -X main.buildTime $(date -Iseconds)" \
    && go install -ldflags="$LDFLAGS" ./... \
    && cp $GOPATH/bin/influx* / \
    && wget -q "$DISCOVERY_URL" -O influxdb-discovery.tar.gz \
    && tar -C / -xzf influxdb-discovery.tar.gz \
    && rm influxdb-discovery.tar.gz \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/* $GOROOT $GOPATH

COPY influxdb.sh /
COPY influxdb.toml /etc/influxdb.toml

# api
EXPOSE 8086
# admin ui
EXPOSE 8083
# intra influxdb
EXPOSE 8088

CMD ["/influxdb.sh"]
