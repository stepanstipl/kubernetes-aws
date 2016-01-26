#!/bin/bash -x

PROJECT='influxdb'
INFLUXDB_VERSION='0.10.0-beta2'
INFLUXDB_PACKAGE="github.com/influxdb/influxdb"
OUTPUT_DIR='/artifacts'


# Get influxdb
cd /tmp
curl -s -L -o /tmp/influxdb.tar.gz https://influxdb.s3.amazonaws.com/influxdb-v0.10.0-beta2_linux_amd64.tar.gz
tar xvzf /tmp/influxdb.tar.gz ./usr/bin/influxd ./usr/bin/influx

cp ./usr/bin/influxd ./usr/bin/influx "${OUTPUT_DIR}/"

# Needed for collectd
wget -O "${OUTPUT_DIR}/types.db" "https://raw.githubusercontent.com/collectd/collectd/master/src/types.db"

# Get kubernetes
go get -u k8s.io/kubernetes
cd $GOPATH/src/k8s.io/kubernetes
$GOPATH/bin/godep restore

# Build InfluxDB discovery
cd /source
godep go get -v ./...
godep go build -v ./influxdb-discovery.go
cp ./influxdb-discovery "${OUTPUT_DIR}/"
