#!/bin/sh -x
APP='influxdb'

CURL_OPTS=${CURL_OPTS:-'-s -f -w "%{http_code}" -o /dev/null --connect-timeout 30'}
CURL="/usr/bin/curl ${CURL_OPTS}"

PEER_PROTO='http'

JOIN=""
CHECK_PEERS=${CHECK_PEERS:-'true'}
MAX_WAIT=60

POD_IP=${POD_IP:?'$K8S_IP is not set'}

# Get IPs form Kubernetes
PEERS=$(/influxdb-discovery)

HEALTHY_PEERS=""

wait_for=$RANDOM
let "wait_for %= $MAX_WAIT"
sleep $wait_for

for peer in $PEERS; do
  resp_code='200' 
  # If we're supposed to check peers, check them
  [[ $CHECK_PEERS == 'true' ]] && resp_code=$($CURL "${PEER_PROTO}://${peer}/ping")

  if [[ $resp_code == '200' ]]; then
    [[ -n "${HEALTHY_PEERS}" ]] && HEALTHY_PEERS="${HEALTHY_PEERS},"
    HEALTHY_PEERS="${HEALTHY_PEERS}${peer}"
  fi
done

echo "${APP}: Found healthy peers: ${HEALTHY_PEERS}"
[[ -n "${HEALTHY_PEERS}" ]] && JOIN="-join ${HEALTHY_PEERS}"

export INFLUXDB_META_BIND_ADDRESS="${POD_IP}:8088"
export INFLUXDB_META_HTTP_BIND_ADDRESS="${POD_IP}:8091"
export INFLUXDB_ADMIN_BIND_ADDRESS="${POD_IP}:8083"
export INFLUXDB_HTTP_BIND_ADDRESS="${POD_IP}:8086"

/influxd --config /etc/influxdb.toml $JOIN
