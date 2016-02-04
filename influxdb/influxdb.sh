#!/bin/sh
APP='influxdb'

# Turn on debugging potentially
[[ "$DEBUG" == 'true' ]] && set -x

PEER_PORT=${PEER_PORT:-'8091'}

JOIN=${JOIN:-'false'}

POD_IP=${POD_IP:?'$K8S_IP is not set'}


if [[ "$JOIN" == "true" ]]; then
  # Get IPs form Kubernetes
  PEERS=$(/influxdb-discovery)

  JOIN=""

  # Constructs join list
  for peer in ${PEERS}; do
    [[ -n "${JOIN}" ]] && JOIN+=','
    JOIN+="${peer}:${PEER_PORT}"
  done

  JOIN="-join ${JOIN}"

  echo "${APP}: Found peers: ${PEERS}"
else
  JOIN=""
  echo "${APP}: Initalizing new cluster, skipping peer search"
fi

export INFLUXDB_META_BIND_ADDRESS="${POD_IP}:8088"
export INFLUXDB_META_HTTP_BIND_ADDRESS="${POD_IP}:8091"
export INFLUXDB_ADMIN_BIND_ADDRESS="${POD_IP}:8083"
export INFLUXDB_HTTP_BIND_ADDRESS="${POD_IP}:8086"

/influxd --config /etc/influxdb.toml $JOIN
