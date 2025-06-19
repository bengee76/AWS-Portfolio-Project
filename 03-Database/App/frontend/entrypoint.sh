#! /bin/sh

envsubst '$LB_DNS' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

nginx -g 'daemon off;' 