#!/bin/bash -x

PROJECT='influxdb'
INFLUXDB_VERSION='0.10.1-1'
INFLUXDB_PACKAGE="github.com/influxdb/influxdb"
K8S_VERSION="1.1.7"
OUTPUT_DIR='/artifacts'

# Get influxdb
cd /tmp
curl -s -L -o "/tmp/influxdb.tar.gz" "https://influxdb.s3.amazonaws.com/influxdb-${INFLUXDB_VERSION}_linux_amd64.tar.gz"
[[ -f "/tmp/influxdb.tar.gz" ]] && tar xvzf ./influxdb.tar.gz "./influxdb-${INFLUXDB_VERSION}/usr/bin/influxd" "./influxdb-${INFLUXDB_VERSION}/usr/bin/influx"

cp "./influxdb-${INFLUXDB_VERSION}/usr/bin/influxd" "./influxdb-${INFLUXDB_VERSION}/usr/bin/influx" "${OUTPUT_DIR}/"

# Needed for collectd
wget -O "${OUTPUT_DIR}/types.db" "https://raw.githubusercontent.com/collectd/collectd/master/src/types.db"


# Get kubernetes
wget "https://github.com/kubernetes/kubernetes/archive/v${K8S_VERSION}.tar.gz"
tar -xvzf "v${K8S_VERSION}.tar.gz"
mkdir -p "${GOPATH}/src/k8s.io"
mv "kubernetes-${K8S_VERSION}" "${GOPATH}/src/k8s.io/kubernetes"

# Build influxdb-discovery
cd "${GOPATH}/src/k8s.io/kubernetes"
cp /source/influxdb-discovery.go ./
~/go-tools/bin/godep go build -v -o "${OUTPUT_DIR}/influxdb-discovery" influxdb-discovery.go
