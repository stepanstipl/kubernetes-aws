FROM nginx:1.9.9
MAINTAINER Stepan Stipl
# https://github.com/stepanstipl

COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx-proxy.sh /

COPY proxy-oauth.conf /tmp/
COPY proxy.conf /tmp/

EXPOSE 443

CMD ["/nginx-proxy.sh", "-g", "daemon off;"]
