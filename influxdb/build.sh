#!/bin/bash -x

PROJECT='influxdb'
INFLUXDB_VERSION='0.10.0-beta2'
INFLUXDB_PACKAGE="github.com/influxdb/influxdb"
K8S_VERSION="1.1.4"
OUTPUT_DIR='/artifacts'


# Get influxdb
cd /tmp
curl -s -L -o /tmp/influxdb.tar.gz https://influxdb.s3.amazonaws.com/influxdb-v0.10.0-beta2_linux_amd64.tar.gz
tar xvzf /tmp/influxdb.tar.gz ./usr/bin/influxd ./usr/bin/influx

cp -r ./usr/bin/influxd ./usr/bin/influx "${OUTPUT_DIR}/"

# Needed for collectd
wget -O "${OUTPUT_DIR}/types.db" "https://raw.githubusercontent.com/collectd/collectd/master/src/types.db"


# Get kubernetes
wget "https://github.com/kubernetes/kubernetes/archive/v${K8S_VERSION}.tar.gz"
tar -xvzf "v${K8S_VERSION}.tar.gz"
mkdir -p "${GOPATH}/src/k8s.io"
mv "kubernetes-1.1.4" "${GOPATH}/src/k8s.io/"

cd "${GOPATH}/src/k8s.io/kubernetes"
cp /source/influxdb-discovery.go ./
~/go-tools/bin/godep go build -v influxdb-discovery.go -o "${OUTPUT_DIR}/influxdb-discovery"
