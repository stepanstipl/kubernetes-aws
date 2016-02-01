FROM alpine:3.3
MAINTAINER Stepan Stipl <stepan@stipl.net>

ENV GRAFANA_VERSION=2.6.0

RUN export GOPATH=/go && \
    PATH=$PATH:$GOPATH/bin && \
    apk add --update build-base go git mercurial curl nodejs bash && \
    mkdir -p /go/src/github.com/grafana && cd /go/src/github.com/grafana && \
    git clone https://github.com/grafana/grafana.git -b "v${GRAFANA_VERSION}" && \
    cd grafana && \
    go run build.go setup && \
    godep restore && \
    go build . && \
    npm install && \
    npm install -g grunt-cli && \
    cd /go/src/github.com/grafana/grafana/node_modules/karma-phantomjs-launcher/node_modules/phantomjs && node install && \
    cd /go/src/github.com/grafana/grafana && grunt && \
    npm uninstall -g grunt-cli && \
    npm cache clear && \
    mkdir -p /usr/share/grafana/bin && \
    cp -a /go/src/github.com/grafana/grafana/grafana /usr/sbin/grafana-server && \
    cp -ra /go/src/github.com/grafana/grafana/public_gen /usr/share/grafana && \
    mv /usr/share/grafana/public_gen /usr/share/grafana/public && \
    cp -ra /go/src/github.com/grafana/grafana/conf /etc/grafana && \
    go clean -i -r && \
    apk del --purge build-base nodejs go git mercurial && \
    rm -rf /go /tmp/* /var/cache/apk/* /root/.n* /usr/local/bin/phantomjs

# TODO
# VOLUME 

EXPOSE 3000

COPY ./grafana.sh /grafana.sh
COPY dashboards /dashboards
COPY grafana.ini /etc/grafana/grafana.ini

ENTRYPOINT ["/grafana.sh"]
