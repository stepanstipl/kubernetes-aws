#!/bin/sh -x
APP='influxdb'

JOIN=$(/influxdb-discovery)
[[ -n "${JOIN}" ]] && JOIN="-join ${JOIN}"

K8S_IP=${K8S_IP:?'$K8S_IP is not set'}

export META_BIND_ADDRESS="${POD_IP}:8088"
export META_HTTP_BIND_ADDRESS="${POD_IP}:8091"
export ADMIN_BIND_ADDRESS="${POD_IP}:9083"
export HTTP_BIND_ADDRESS="${POD_IP}:9086"

/influxd --config /etc/influxdb.toml $JOIN
