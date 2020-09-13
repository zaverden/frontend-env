#!/bin/sh

set -e

# we can use simple version of envsubst execution as
# envsubst < /usr/share/nginx/html/index.html.template > /usr/share/nginx/html/index.html
# but it replaces everything that looks like environment variable substitution
# so it affects `default values` approach.

# we need to replace only provided environment variables. and base image already contains script
# that does exactly what we want. we just have to tune it with a couple of environment variables
# see base image content here:
# https://github.com/nginxinc/docker-nginx/tree/9774b522d4661effea57a1fbf64c883e699ac3ec/mainline/buster

export NGINX_ENVSUBST_TEMPLATE_DIR=/usr/share/nginx/html
export NGINX_ENVSUBST_OUTPUT_DIR=/usr/share/nginx/html
/docker-entrypoint.d/20-envsubst-on-templates.sh