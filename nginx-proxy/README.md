# nginx-proxy

Nginx proxy for Docker, with oAuhth. Intended to be used with oauth2_proxy
(https://github.com/bitly/oauth2_proxy) in auth_request mode.

Expects at least following variables to be set:
- **NGINX_PROXY_PASS** - nginx's proxy_pass destination
- **NGINX_SERVER_NAME** - nginx's server_name
- **ENABLE_OAUTH** - whether to enable oAuth, defaults to `true`
- **OAUTH_PROXY_PASS** - aouthentication endpoint
