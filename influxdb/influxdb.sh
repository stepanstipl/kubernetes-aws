#!/bin/sh -x
APP='influxdb'

JOIN=$(/influxdb-discovery)
[[ -n "${JOIN}" ]] && JOIN="-join ${JOIN}"

POD_IP=${POD_IP:?'$K8S_IP is not set'}

export INFLUXDB_META_BIND_ADDRESS="${POD_IP}:8088"
export INFLUXDB_META_HTTP_BIND_ADDRESS="${POD_IP}:8091"
export INFLUXDB_ADMIN_BIND_ADDRESS="${POD_IP}:8083"
export INFLUXDB_HTTP_BIND_ADDRESS="${POD_IP}:8086"

/influxd --config /etc/influxdb.toml $JOIN
