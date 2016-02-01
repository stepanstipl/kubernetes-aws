#!/bin/bash
APP='grafana'

[[ "$DEBUG" == 'true' ]] && set -x

HEADER_CONTENT_TYPE="Content-Type: application/json"
HEADER_ACCEPT="Accept: application/json"

SECRETS_PATH=${SECRETS_PATH:-/secrets}

# Read secrets as variables
for file in ${SECRETS_PATH}/*; do 
  if [[ -f "${file}" ]]; then
    echo ok
    var="$(basename ${file} | tr '-' '_')"
    val="$(cat ${file})"
    [[ -n "${val}" ]] && export "${var^^}"="${val}"
  fi
done

GRAFANA_USER=${GRAFANA_USER:-admin}
GRAFANA_PASSWORD=${GRAFANA_PASSWORD:?"\$GRAFANA_PASSWORD not set"}
GRAFANA_PORT=${GRAFANA_PORT:-3000}

INFLUXDB_HOST=${INFLUXDB_HOST:-"monitoring-influxdb"}
INFLUXDB_DATABASE=${INFLUXDB_DATABASE:-k8s}
INFLUXDB_PASSWORD=${INFLUXDB_PASSWORD:-"root"}
INFLUXDB_PORT=${INFLUXDB_PORT:-8086}
INFLUXDB_USER=${INFLUXDB_USER:-root}

DASHBOARD_LOCATION=${DASHBOARD_LOCATION:-"/dashboards"}

export GF_SERVER_HTTP_PORT=${GRAFANA_PORT}
export GF_SECURITY_ADMIN_USER=${GRAFANA_USER}
export GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}

BACKEND_ACCESS_MODE=${BACKEND_ACCESS_MODE:-proxy}
INFLUXDB_SERVICE_URL="http://${INFLUXDB_HOST}:${INFLUXDB_PORT}"

echo "${APP}: Using the following URL for InfluxDB: ${INFLUXDB_SERVICE_URL}"
echo "${APP}: Using the following backend access mode for InfluxDB: ${BACKEND_ACCESS_MODE}"

set -m
echo "Starting Grafana in the background"
exec /usr/sbin/grafana-server --homepath=/usr/share/grafana --config=/etc/grafana/grafana.ini &

echo "Waiting for Grafana to come up..."
until $(curl --fail --output /dev/null --silent http://${GRAFANA_USER}:${GRAFANA_PASSWORD}@localhost:${GRAFANA_PORT}/api/org); do
  printf "."
  sleep 2
done
echo "Grafana is up and running."
echo "Creating default influxdb datasource..."
curl -i -XPOST -H "${HEADER_ACCEPT}" -H "${HEADER_CONTENT_TYPE}" "http://${GRAFANA_USER}:${GRAFANA_PASSWORD}@localhost:${GRAFANA_PORT}/api/datasources" -d '
{
  "name": "influxdb-datasource",
  "type": "influxdb",
  "access": "'"${BACKEND_ACCESS_MODE}"'",
  "isDefault": true,
  "url": "'"${INFLUXDB_SERVICE_URL}"'",
  "password": "'"${INFLUXDB_PASSWORD}"'",
  "user": "'"${INFLUXDB_USER}"'",
  "database": "'"${INFLUXDB_DATABASE}"'"
}'

echo ""
echo "Importing default dashboards..."
for filename in ${DASHBOARD_LOCATION}/*.json; do
  echo "Importing ${filename} ..."
  curl -i -XPOST --data "@${filename}" -H "${HEADER_ACCEPT}" -H "${HEADER_CONTENT_TYPE}" "http://${GRAFANA_USER}:${GRAFANA_PASSWORD}@localhost:${GRAFANA_PORT}/api/dashboards/db"
  echo ""
  echo "Done importing ${filename}"
done
echo ""
echo "Bringing Grafana back to the foreground"
fg
