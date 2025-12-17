#!/bin/sh
set -e

# Replace environment variables in nginx config
envsubst '${BACKEND_HOST} ${BACKEND_PORT}' < /etc/nginx/templates/nginx.template.conf > /etc/nginx/conf.d/default.conf

# Start nginx
exec nginx -g 'daemon off;'

