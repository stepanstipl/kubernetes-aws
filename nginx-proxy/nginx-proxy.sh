#!/bin/bash
APP='nginx-proxy'

[[ "$DEBUG" == 'true' ]] && set -x


ENABLE_OAUTH=${ENABLE_OAUTH:-'true'}
PROXY_TEMPLATE='proxy.conf'

# This would limit methods to GET & HEAD & OPTONS by default
ENABLE_READ_ONLY=${ENABLE_READ_ONLY:-'false'}

NGINX_PROXY_PASS=${NGINX_PROXY_PASS:?'$NGINX_PROXY_PASS url is not set'}
NGINX_SERVER_NAME=${NGINX_SERVER_NAME:?'$NGINX_SERVER_NAME is not set'}

OAUTH_LOCATION=""
OAUTH_AUTH_REQUEST=""
READ_ONLY=""

if [[ "$ENABLE_OAUTH" == 'true' ]]; then
  OAUTH_PROXY_PASS=${OAUTH_PROXY_PASS:?'$OAUTH_PROXY_PASS url is not set'}

  read -r -d '' OAUTH_LOCATION <<"EOF"
    location /oauth2/ {
        proxy_pass {{ OAUTH_PROXY_PASS }};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Scheme $scheme;
    }
EOF

  read -r -d '' OAUTH_AUTH_REQUEST <<"EOF"
        auth_request /oauth2/auth;
        error_page 401 /oauth2/sign_in;

        auth_request_set $user $upstream_http_remote_user;
        proxy_set_header Remote-User $user;
        auth_request_set $groups $upstream_http_remote_groups;
        proxy_set_header Remote-Groups $groups;
        auth_request_set $expiry $upstream_http_remote_expiry;
        proxy_set_header Remote-Expiry $expiry;
EOF

fi

if [[ "$ENABLE_READ_ONLY" == 'true' ]]; then
  read -r -d '' READ_ONLY  <<"EOF"
        if ( $request_method !~ ^(GET|HEAD|OPTIONS)$ ) {
            return 405;
        }
EOF

elif [[ "$ENABLE_READ_ONLY" == 'kibana' ]]; then
  read -r -d '' READ_ONLY  <<"EOF"
        set $posting 11;
        if ( $request_method !~ ^(GET|POST|OPTIONS|HEAD)$ ) {
            return 405;
        }
        
        if ( $request_method = POST ) {
            set $posting 1;
        }

        if ( $request_uri ~ ^/(.+)/(_search|_mget|_msearch|\.kibana/__kibanaQueryValidator/_validate/query)(.*)$ ){
            set $posting "${posting}1";
        }

        if ( $request_method = OPTIONS ) {
            set $posting 11;
        }

        if ( $request_method = GET ) {
            set $posting 11;
        }

        if ( $posting != 11 ){
            return 400;
        }
EOF

fi

# Sanitise new lines for sed... ugh
NL=$'\n'
READ_ONLY="${READ_ONLY//$NL/\\n}"
OAUTH_LOCATION="${OAUTH_LOCATION//$NL/\\n}"
OAUTH_AUTH_REQUEST="${OAUTH_AUTH_REQUEST//$NL/\\n}"

# Replace variables in config file 
sed "s@{{ NGINX_PROXY_PASS }}@${NGINX_PROXY_PASS}@g; \
     s@{{ NGINX_SERVER_NAME }}@${NGINX_SERVER_NAME}@g; \
     s@{{ READ_ONLY }}@${READ_ONLY}@g; \
     s@{{ OAUTH_LOCATION }}@${OAUTH_LOCATION}@g; \
     s@{{ OAUTH_AUTH_REQUEST }}@${OAUTH_AUTH_REQUEST}@g; \
     s@{{ OAUTH_PROXY_PASS }}@${OAUTH_PROXY_PASS}@g;" "/tmp/${PROXY_TEMPLATE}" > /etc/nginx/proxy.conf

nginx "$@"
