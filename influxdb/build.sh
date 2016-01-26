#!/bin/bash -x

PROJECT='influxdb'
VERSION='0.10.0-beta2'
OUTPUT_DIR='/artifacts'
INFLUXDB_PACKAGE="github.com/influxdb/influxdb"

# Clone influxdb
go get $INFLUXDB_PACKAGE
cd "${GOPATH}/src/${INFLUXDB_PACKAGE}"
go get -v -u -f -t ./...
git checkout -q "v${INFLUXDB_VERSION}"
go build -v ./...
# CGO_ENABLED=0 go build -a -ldflags '-s' --tags netgo --installsuffix netgo -v ./...
#go build -a --ldflags '-linkmode external -extldflags "-static"' -v $INFLUXDB_PACKAGE

cp /go/bin/influxd /go/bin/influx "${OUTPUT_DIR}/"

# Copy requiered libs
# mkdir -p "${OUTPUT_DIR}/lib"
# cp /lib/ld-musl-x86_64.so.1 "${OUTPUT_DIR}/lib/"
# cp /lib/libc.musl-x86_64.so.1 "${OUTPUT_DIR}/lib/" 

# Needed for collectd
wget -O "${OUTPUT_DIR}/types.db" "https://raw.githubusercontent.com/collectd/collectd/master/src/types.db"

# Build InfluxDB discovery
cd /source
go get -v ./...
go build -v ./influxdb-discovery.go
cp ./influxdb-discovery "${OUTPUT_DIR}/"
