#!/bin/sh +x
APP='influxdb'

JOIN=$(/influxdb-discovery)
[[ -n "${JOIN}" ]] && JOIN="-join ${JOIN}"

/influxd --config /etc/influxdb.toml $JOIN
