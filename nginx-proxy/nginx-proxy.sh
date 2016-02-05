#!/bin/bash
APP='nginx-proxy'

[[ "$DEBUG" == 'true' ]] && set -x

ENABLE_OAUTH=${ENABLE_OAUTH:-'true'}
PROXY_TEMPLATE='proxy.conf'

if [[ "$ENABLE_OAUTH" == 'true' ]]; then
  PROXY_TEMPLATE='proxy-oauth.conf'
  OAUTH_PROXY_PASS=${OAUTH_PROXY_PASS:?'$OAUTH_PROXY_PASS url is not set'}
fi

NGINX_PROXY_PASS=${NGINX_PROXY_PASS:?'$NGINX_PROXY_PASS url is not set'}
NGINX_SERVER_NAME=${NGINX_SERVER_NAME:?'$NGINX_SERVER_NAME is not set'}

sed "s@{{ NGINX_PROXY_PASS }}@${NGINX_PROXY_PASS}@g;s@{{ NGINX_SERVER_NAME }}@${NGINX_SERVER_NAME}@g;s@{{ OAUTH_PROXY_PASS }}@${OAUTH_PROXY_PASS}@g" "/tmp/${PROXY_TEMPLATE}" > /etc/nginx/proxy.conf

nginx "$@"
