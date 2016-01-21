FROM nginx:1.9.9
MAINTAINER Stepan Stipl
# https://github.com/stepanstipl

COPY nginx.conf /etc/nginx/nginx.conf
COPY proxy.conf /etc/nginx/proxy.conf
COPY nginx-proxy /

EXPOSE 443

CMD ["/nginx-proxy", "-g", "daemon off;"]
